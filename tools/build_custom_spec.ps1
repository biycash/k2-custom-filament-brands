# K2 Custom Filament Brands - builds custom_spec.json from your Creality Print profiles.
# Kendi Creality Print "ozel filament" profillerinizden custom_spec.json uretir.
#
# Which profiles: filament profiles you made with "Custom filament" (their "inherits" field is empty),
# named like "<Brand> <Material> @<Printer> <nozzle> nozzle", e.g. "Porima ABS Basic @Creality K2 Pro 0.4 nozzle".
# One printer entry per family (everything before " @"), with all of its nozzle sizes.
# Settings come from the 0.4 profile, else 0.6, 0.8, 0.2.
param(
    [Parameter(Mandatory = $true)][string]$DataDir,
    [string]$Printer,
    [string]$UserFolder,
    [switch]$ListPrinters
)
$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture
$utf8 = New-Object Text.UTF8Encoding($false)

# Printer entry to copy for each filament type. The entry must exist in the printer's list.
$parentByType = [ordered]@{
    'PLA' = 'Generic PLA'; 'PLA-CF' = 'Generic PLA-CF'; 'PLA-GF' = 'Generic PLA-HT-GF'; 'PLA-SILK' = 'Generic PLA-Silk'
    'ABS' = 'Generic ABS'; 'ABS-CF' = 'Generic ABS-CF'; 'ABS-GF' = 'Generic ABS-GF'; 'ABS-FR' = 'Generic ABS-FR'
    'ASA' = 'Generic ASA'; 'ASA-CF' = 'Generic ASA'
    'PETG' = 'Generic PETG'; 'PETG-CF' = 'Generic PETG-CF'; 'PETG-GF' = 'Generic PETG-GF'
    'PET' = 'Generic PET'; 'PET-CF' = 'Generic PET-CF'; 'PET-GF' = 'Generic PET-GF15'
    'PA' = 'Generic PA'; 'PA-CF' = 'Generic PA6-CF'; 'PA-GF' = 'Generic PA6-GF'; 'PAHT-CF' = 'Generic PAHT-CF'
    'PC' = 'Generic PC'; 'PC-CF' = 'Generic PC-CF'
    'TPU' = 'Generic TPU'; 'PP' = 'Generic PP'; 'PVA' = 'Generic PVA'; 'BVOH' = 'Generic BVOH'
    'HIPS' = 'Generic ABS'
}
# Types the printer has no Generic entry for: shown on the screen under their own type name.
# If the screen or the CFS misbehaves with such a type, change the value to the copied type (e.g. 'ABS').
$screenTypeOverride = @{ 'HIPS' = 'HIPS' }
$skipKeys = 'compatible_printers', 'compatible_printers_condition', 'compatible_prints', 'compatible_prints_condition',
    'inherits', 'name', 'from', 'version', 'filament_settings_id', 'filament_id', 'setting_id', 'instantiation'

function Read-JsonFile($p) { return ([IO.File]::ReadAllText($p)).TrimStart([char]0xFEFF) | ConvertFrom-Json }

# --- find Creality Print user data -------------------------------------------------------------
$cpRoot = Join-Path $env:APPDATA 'Creality\Creality Print'
if (-not (Test-Path -LiteralPath $cpRoot)) { throw "Creality Print data folder not found: $cpRoot" }
$verDir = Get-ChildItem -LiteralPath $cpRoot -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'user') } |
    Sort-Object { try { [version]$_.Name } catch { [version]'0.0' } } -Descending | Select-Object -First 1
if (-not $verDir) { throw "No Creality Print profile folder found under $cpRoot" }
$userRoot = Join-Path $verDir.FullName 'user'

$profiles = New-Object System.Collections.ArrayList
foreach ($u in Get-ChildItem -LiteralPath $userRoot -Directory) {
    if ($UserFolder -and $u.Name -ne $UserFolder) { continue }
    foreach ($sub in 'filament\base', 'filament') {
        $d = Join-Path $u.FullName $sub
        if (-not (Test-Path -LiteralPath $d)) { continue }
        foreach ($f in Get-ChildItem -LiteralPath $d -Filter *.json -File) {
            try { $o = Read-JsonFile $f.FullName } catch { continue }
            if ("$($o.inherits)" -ne '') { continue }
            if ("$($o.name)" -notmatch '^(.+?) @(.+?) ([0-9.]+) nozzle$') { continue }
            [void]$profiles.Add([pscustomobject]@{ User = $u.Name; Family = $Matches[1]; Printer = $Matches[2]; Nozzle = $Matches[3]; Data = $o })
        }
    }
}
if ($profiles.Count -eq 0) { throw "No custom filament profiles found in $userRoot" }

$users = @($profiles | Group-Object User | Sort-Object Count -Descending)
if (-not $UserFolder) {
    $UserFolder = $users[0].Name
    if ($users.Count -gt 1) { Write-Warning ("Several Creality Print accounts have custom filaments; using '{0}'. Others: {1}" -f $UserFolder, (($users | Select-Object -Skip 1 | ForEach-Object { "$($_.Name) ($($_.Count))" }) -join ', ')) }
}
$mine = @($profiles | Where-Object { $_.User -eq $UserFolder })

if ($ListPrinters) {
    $mine | Group-Object Printer | Sort-Object Count -Descending | ForEach-Object { [pscustomobject]@{ Printer = $_.Name; Profiles = $_.Count } }
    return
}
if (-not $Printer) {
    $g = @($mine | Group-Object Printer | Sort-Object Count -Descending)
    $Printer = $g[0].Name
}
$mine = @($mine | Where-Object { $_.Printer -eq $Printer })
if ($mine.Count -eq 0) { throw "No custom filament profiles for printer '$Printer'" }

# --- stable ids ----------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $DataDir)) { New-Item -ItemType Directory -Path $DataDir | Out-Null }
$idsPath = Join-Path $DataDir 'custom_ids.json'
$ids = [ordered]@{}
if (Test-Path -LiteralPath $idsPath) { (Read-JsonFile $idsPath).PSObject.Properties | ForEach-Object { $ids[$_.Name] = "$($_.Value)" } }

# --- build entries ---------------------------------------------------------------------------
$entries = New-Object System.Collections.ArrayList
$report = New-Object System.Collections.ArrayList
foreach ($fam in ($mine | Group-Object Family | Sort-Object Name)) {
    $byNz = @{}; foreach ($p in $fam.Group) { $byNz[$p.Nozzle] = $p.Data }
    $src = $null; foreach ($n in '0.4', '0.6', '0.8', '0.2') { if ($byNz.ContainsKey($n)) { $src = $n; break } }
    if (-not $src) { $src = @($byNz.Keys)[0] }
    $o = $byNz[$src]
    $type = "$(@($o.filament_type)[0])".ToUpperInvariant()
    if (-not $parentByType.Contains($type)) {
        [void]$report.Add("SKIPPED $($fam.Name): filament type '$type' has no matching printer entry")
        continue
    }
    $brand = "$(@($o.filament_vendor)[0])".Trim()
    if ($brand -eq '') { $brand = 'Custom' }
    if (-not $ids.Contains($fam.Name)) {
        $next = 90001; while (@($ids.Values) -contains ('{0:D5}' -f $next)) { $next++ }
        $ids[$fam.Name] = '{0:D5}' -f $next
    }
    $b = [ordered]@{ id = $ids[$fam.Name]; brand = $brand; name = $fam.Name }
    if ($screenTypeOverride.ContainsKey($type)) { $b['meterialType'] = $screenTypeOverride[$type] }
    $lo = "$(@($o.nozzle_temperature_range_low)[0])"; $hi = "$(@($o.nozzle_temperature_range_high)[0])"; $dn = "$(@($o.filament_density)[0])"
    $tmp = 0; $dtmp = 0.0
    if ([int]::TryParse($lo, [ref]$tmp)) { $b['minTemp'] = $tmp }
    if ([int]::TryParse($hi, [ref]$tmp)) { $b['maxTemp'] = $tmp }
    if ([double]::TryParse($dn, [Globalization.NumberStyles]::Float, $inv, [ref]$dtmp) -and $dtmp -gt 0) { $b['density'] = $dtmp }
    $kv = [ordered]@{}
    foreach ($p in $o.PSObject.Properties) {
        if ($skipKeys -contains $p.Name) { continue }
        $vals = @($p.Value)
        if ($vals.Count -eq 1 -and $null -ne $vals[0] -and $vals[0] -isnot [pscustomobject]) { $kv[$p.Name] = "$($vals[0])" }
    }
    $kv['filament_vendor'] = $brand
    $nozzles = @($byNz.Keys | Sort-Object { [double]::Parse($_, $inv) })
    [void]$entries.Add([ordered]@{ parent = $parentByType[$type]; nozzles = $nozzles; base = $b; kv = $kv; source = "$($fam.Name) @ $src" })
    [void]$report.Add(('{0} | {1,-34} | {2,-16} | {3,-8} | nozzles {4}' -f $b.id, $fam.Name, $brand, $type, ($nozzles -join ',')))
}

[IO.File]::WriteAllText((Join-Path $DataDir 'custom_spec.json'), ([ordered]@{ printer = $Printer; account = $UserFolder; entries = $entries } | ConvertTo-Json -Depth 10), $utf8)
[IO.File]::WriteAllText($idsPath, ($ids | ConvertTo-Json), $utf8)
"Creality Print: $($verDir.Name) | account folder: $UserFolder | printer: $Printer | families: $($entries.Count)"
$report
