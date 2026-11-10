# K2 Custom Filament Brands
# Creality K2 ekranina kendi filament markalarinizi ekler / Adds your own filament brands to the Creality K2 screen.
#
#   -Action Install    (varsayilan) profillerden liste uretir, dener, onay ister, uygular
#   -Action Uninstall  yalnizca bu aracin ekledigi kayitlari kaldirir
#   -Action Restore    yazicidaki en son yedegi geri koyar
#   -DryRun            sadece dener, yaziciya hicbir sey yazmaz
param(
    [ValidateSet('Install', 'Uninstall', 'Restore')][string]$Action = 'Install',
    [string]$PrinterIp,
    [string]$Printer,
    [string]$UserFolder,
    [string]$DataDir = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'K2CustomFilamentBrands'),
    [switch]$DryRun,
    [switch]$Yes
)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$box = '/mnt/UDISK/creality/userdata/box'
$marker = 'k2_custom_filament_brands.json'
$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss', [Globalization.CultureInfo]::InvariantCulture)
$utf8 = New-Object Text.UTF8Encoding($false)

function Say($tr, $en, $color = 'Gray') { Write-Host "$tr" -ForegroundColor $color; if ($en) { Write-Host "  ($en)" -ForegroundColor DarkGray } }
function Step($n, $tr, $en) { Write-Host ''; Write-Host "[$n] $tr / $en" -ForegroundColor Cyan }
function Ask-YesNo($tr, $en) {
    if ($Yes) { return $true }
    $a = Read-Host "$tr / $en (E/H, Y/N)"
    return ($a -match '^(e|E|y|Y)')
}
function Stop-Here($tr, $en) { Say $tr $en 'Yellow'; exit 1 }

Write-Host ''
Write-Host '=== K2 Custom Filament Brands ===' -ForegroundColor Green
Say 'Yaziciniz baski yaparken calistirmayin. Her calistirmada once yedek alinir.' 'Do not run while printing. A backup is taken before every change.'

# --- Posh-SSH -----------------------------------------------------------------------------------
if (-not (Get-Module -ListAvailable Posh-SSH)) {
    Say 'SSH baglantisi icin gereken Posh-SSH modulu yuklu degil.' 'The Posh-SSH module needed for SSH is not installed.' 'Yellow'
    if (-not (Ask-YesNo 'Simdi yuklensin mi?' 'Install it now?')) { Stop-Here 'Iptal edildi.' 'Cancelled.' }
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) { Install-PackageProvider -Name NuGet -Scope CurrentUser -Force | Out-Null }
    Install-Module Posh-SSH -Scope CurrentUser -Force -AllowClobber
}
Import-Module Posh-SSH

# --- settings -----------------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $DataDir)) { New-Item -ItemType Directory -Path $DataDir | Out-Null }
$settingsPath = Join-Path $DataDir 'settings.json'
$settings = @{}
if (Test-Path -LiteralPath $settingsPath) { (Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $settings[$_.Name] = $_.Value } }
if (-not $PrinterIp) {
    $last = $settings['PrinterIp']
    $prompt = 'Yazicinin IP adresi (ekranda Ayarlar > Ag) / Printer IP address (Settings > Network on the screen)'
    if ($last) { $prompt += " [$last]" }
    $PrinterIp = (Read-Host $prompt).Trim()
    if (-not $PrinterIp) { $PrinterIp = $last }
}
if (-not $PrinterIp) { Stop-Here 'IP adresi girilmedi.' 'No IP address given.' }
$settings['PrinterIp'] = $PrinterIp
[IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json), $utf8)

# --- printer state ------------------------------------------------------------------------------
Step 1 'Yazici kontrol ediliyor' 'Checking the printer'
$state = $null
foreach ($port in 4408, 7125) {
    try { $state = (Invoke-RestMethod -Uri "http://${PrinterIp}:$port/printer/objects/query?print_stats" -TimeoutSec 6).result.status.print_stats.state; break } catch {}
}
if ($state) { Say "Yazici durumu: $state" "Printer state: $state" }
else { Say 'Yazicinin durumu okunamadi.' 'Could not read the printer state.' 'Yellow' }
if ($state -in 'printing', 'paused') { Stop-Here 'Yazici baski yapiyor; baski bitince tekrar calistirin.' 'The printer is printing; run again when it is done.' }
if (-not $state -and -not (Ask-YesNo 'Yazicinin baski YAPMADIGINDAN eminseniz devam edilsin mi?' 'Continue only if you are sure it is NOT printing?')) { Stop-Here 'Iptal edildi.' 'Cancelled.' }

$pw = Read-Host 'Root parolasi (ekranda Ayarlar > Root account information) / Root password (Settings > Root account information)' -AsSecureString
$cred = New-Object System.Management.Automation.PSCredential('root', $pw)
try { $s = New-SSHSession -ComputerName $PrinterIp -Credential $cred -AcceptKey -Force -ConnectionTimeout 15 -WarningAction SilentlyContinue }
catch { Stop-Here "SSH baglantisi kurulamadi: $($_.Exception.Message)" 'SSH connection failed. Check the IP, the password and that root access is enabled.' }

function Get-Out($cmd, $t = 180) { return (Invoke-SSHCommand -SSHSession $s -Command $cmd -TimeOut $t).Output }
function Md5Remote($p) { return ((Get-Out "md5sum '$p' 2>/dev/null") -split '\s+')[0] }
function Send-File($local) {
    Set-SCPItem -ComputerName $PrinterIp -Credential $cred -AcceptKey -Force -Path $local -Destination '/tmp' -WarningAction SilentlyContinue
    $l = (Get-FileHash -LiteralPath $local -Algorithm MD5).Hash.ToLower()
    if ($l -ne (Md5Remote "/tmp/$(Split-Path $local -Leaf)")) { throw "upload check failed: $local" }
}
function Backup-Now {
    $pb = "/mnt/UDISK/creality/userdata/box_backup_k2cfb_$stamp"
    Get-Out "mkdir -p $pb && cp -a $box/material_database.json $box/material_option.json $pb/ && { [ -f $box/$marker ] && cp -a $box/$marker $pb/ || true; } && echo ok" | Out-Null
    $lb = Join-Path $DataDir "backups\$stamp"
    New-Item -ItemType Directory -Path $lb -Force | Out-Null
    foreach ($f in 'material_database.json', 'material_option.json') {
        [IO.File]::WriteAllText((Join-Path $lb $f), ((Invoke-SSHCommand -SSHSession $s -Command "cat '$box/$f'" -TimeOut 120).Output -join "`n"), $utf8)
    }
    Say "Yedek: yazicida $pb, bilgisayarda $lb" "Backup: printer $pb, PC $lb"
}
function Test-OnScreenList($wantIds) {
    try {
        $ws = New-Object System.Net.WebSockets.ClientWebSocket
        $cts = New-Object System.Threading.CancellationTokenSource; $cts.CancelAfter(20000)
        $ws.ConnectAsync([Uri]"ws://${PrinterIp}:9999/", $cts.Token).Wait()
        $msg = [Text.Encoding]::UTF8.GetBytes('{"method":"get","params":{"reqMaterials":1}}')
        $ws.SendAsync((New-Object System.ArraySegment[byte] (,$msg)), [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()
        $buf = New-Object byte[] 262144; $ms = New-Object IO.MemoryStream; $found = $null
        while ($ws.State -eq 'Open' -and $null -eq $found) {
            $r = $ws.ReceiveAsync((New-Object System.ArraySegment[byte] (,$buf)), $cts.Token); $r.Wait()
            $ms.Write($buf, 0, $r.Result.Count)
            if ($r.Result.EndOfMessage) { $t = [Text.Encoding]::UTF8.GetString($ms.ToArray()); $ms.SetLength(0); if ($t.Contains('retMaterials')) { $found = $t } }
        }
        $m = @(($found | ConvertFrom-Json).retMaterials)
        $have = @($m | Where-Object { $wantIds -contains $_.base.id })
        Say "Yazicinin listesi: $($m.Count) malzeme, bu aracin kayitlari: $($have.Count)" "Printer list: $($m.Count) materials, entries from this tool: $($have.Count)" 'Green'
        $m | Group-Object { $_.base.brand } | ForEach-Object { Write-Host ('   {0}: {1}' -f $_.Name, $_.Count) }
    } catch { Say 'Yazicidan liste geri okunamadi (onemli degil).' 'Could not read the list back (not critical).' 'Yellow' }
}

try {
    $chkCmd = 'test -f BOX/material_database.json && test -f BOX/material_option.json && command -v python3 >/dev/null && echo OK; python3 -c "import json;l=json.load(open(''BOX/material_database.json''))[''result''][''list''];print(l[0].get(''printerIntName'',''?'') if l else ''?'')"'
    $chk = @(Get-Out $chkCmd.Replace('BOX', $box))
    if ($chk[0] -ne 'OK') { Stop-Here 'Yazicida beklenen dosyalar ya da python3 yok; bu yazici desteklenmiyor olabilir.' 'Expected files or python3 missing on the printer; it may not be supported.' }
    $model = "$($chk[1])"
    Say "Yazici model kodu: $model" "Printer model code: $model"
    if ($model -ne 'F012') {
        Say 'Bu arac yalnizca K2 Pro (F012) uzerinde test edildi. Bu modelde test edilmedi; once -DryRun ile deneyin.' 'Only tested on the K2 Pro (F012). Untested on this model; try -DryRun first.' 'Yellow'
        if (-not $DryRun -and -not (Ask-YesNo 'Yine de devam edilsin mi?' 'Continue anyway?')) { Stop-Here 'Iptal edildi.' 'Cancelled.' }
    }

    if ($Action -eq 'Restore') {
        Step 2 'Yazicidaki yedekler' 'Backups on the printer'
        $list = @(Get-Out 'ls -d /mnt/UDISK/creality/userdata/box_backup_k2cfb_* 2>/dev/null | sort')
        if ($list.Count -eq 0 -or -not $list[0]) { Stop-Here 'Yazicida bu araca ait yedek yok.' 'No backup from this tool on the printer.' }
        $list | ForEach-Object { Write-Host "   $_" }
        $pick = $list[-1]
        Say "Geri konacak: $pick" "Will restore: $pick" 'Yellow'
        if ($DryRun) { Say 'Sadece deneme; hicbir sey degismedi.' 'Dry run; nothing changed.'; return }
        if (-not (Ask-YesNo 'Bu yedek geri konsun mu?' 'Restore this backup?')) { Stop-Here 'Iptal edildi.' 'Cancelled.' }
        Backup-Now
        Get-Out "cp -a $pick/material_database.json $pick/material_option.json $box/ && { [ -f $pick/$marker ] && cp -a $pick/$marker $box/ || rm -f $box/$marker; } && sync && echo restored"
        Say 'Geri yuklendi. Gerekirse yaziciyi yeniden baslatin.' 'Restored. Restart the printer if needed.' 'Green'
        return
    }

    $pyArgs = '--remove'
    if ($Action -eq 'Install') {
        Step 2 'Creality Print profilleriniz okunuyor' 'Reading your Creality Print profiles'
        $bArgs = @{ DataDir = $DataDir }
        if ($UserFolder) { $bArgs['UserFolder'] = $UserFolder }
        if (-not $Printer) {
            $pr = @(& (Join-Path $here 'build_custom_spec.ps1') @bArgs -ListPrinters)
            if ($pr.Count -gt 1) {
                Say 'Birden fazla yazici icin ozel profil bulundu:' 'Custom profiles found for several printers:'
                for ($i = 0; $i -lt $pr.Count; $i++) { Write-Host ("   {0}) {1}  ({2} profil/profiles)" -f ($i + 1), $pr[$i].Printer, $pr[$i].Profiles) }
                $n = Read-Host 'Hangisi bu yazici? / Which one is this printer? (1..)'
                $Printer = $pr[[int]$n - 1].Printer
            } else { $Printer = $pr[0].Printer }
        }
        $bArgs['Printer'] = $Printer
        & (Join-Path $here 'build_custom_spec.ps1') @bArgs | ForEach-Object { Write-Host "   $_" }
        $pyArgs = '--spec /tmp/custom_spec.json'
    }

    Step 3 'Yazicida deneniyor (canli dosyalar degismez)' 'Trying on the printer (live files are not changed)'
    $before = @{ db = Md5Remote "$box/material_database.json"; opt = Md5Remote "$box/material_option.json" }
    Send-File (Join-Path $here 'printer_material_install.py')
    if ($Action -eq 'Install') { Send-File (Join-Path $DataDir 'custom_spec.json') }
    $out = @(Get-Out "python3 /tmp/printer_material_install.py $pyArgs 2>&1; echo exit=`$?")
    $out | ForEach-Object { Write-Host "   $_" }
    if (-not (($out -join "`n") -match 'RESULT entries=\d+' -and $out[-1] -eq 'exit=0')) { Stop-Here 'Deneme basarisiz; yaziciya hicbir sey yazilmadi.' 'The trial failed; nothing was written to the printer.' }
    if ($DryRun) { Say 'Sadece deneme istendi; yaziciya hicbir sey yazilmadi.' 'Dry run only; nothing was written to the printer.' 'Green'; return }

    $q = if ($Action -eq 'Install') { @('Yukaridaki kayitlar yaziciya yazilsin mi?', 'Write the entries above to the printer?') } else { @('Bu aracin ekledigi kayitlar kaldirilsin mi?', 'Remove the entries this tool added?') }
    if (-not (Ask-YesNo $q[0] $q[1])) { Stop-Here 'Iptal edildi; yaziciya hicbir sey yazilmadi.' 'Cancelled; nothing was written.' }

    Step 4 'Uygulaniyor' 'Applying'
    if ((Md5Remote "$box/material_database.json") -ne $before.db -or (Md5Remote "$box/material_option.json") -ne $before.opt) {
        Stop-Here 'Yazici bu sirada listeyi degistirdi; guvenlik icin durduruldu. Tekrar calistirin.' 'The printer changed its list meanwhile; stopped for safety. Run again.'
    }
    Backup-Now
    Get-Out "cp /tmp/new_material_database.json $box/material_database.json && cp /tmp/new_material_option.json $box/material_option.json && cp /tmp/new_$marker $box/$marker && sync && echo done" | Out-Null
    $ok = ((Md5Remote "$box/material_database.json") -eq (Md5Remote '/tmp/new_material_database.json')) -and ((Md5Remote "$box/material_option.json") -eq (Md5Remote '/tmp/new_material_option.json'))
    if (-not $ok) { Stop-Here 'Dosyalar dogrulanamadi! -Action Restore ile yedegi geri koyabilirsiniz.' 'Could not verify the files! Use -Action Restore to put the backup back.' }

    Step 5 'Kontrol' 'Check'
    $want = @()
    if ($Action -eq 'Install') { $want = @(([IO.File]::ReadAllText((Join-Path $DataDir 'custom_spec.json')) | ConvertFrom-Json).entries | ForEach-Object { $_.base.id }) }
    Test-OnScreenList $want
    Say 'Tamam. Markalar ekranda hemen gorunmeli; gorunmezse yaziciyi yeniden baslatin.' 'Done. The brands should show on the screen right away; if not, restart the printer.' 'Green'
}
finally { if ($s) { $null = Remove-SSHSession -SSHSession $s } }
