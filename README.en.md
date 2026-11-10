# K2 Custom Filament Brands

Add **your own filament brands** to the touchscreen of a Creality K2 printer.
Whatever you use, it shows on the screen under its own brand and name and can be assigned to a CFS slot.

🇹🇷 [Türkçe sürüm](README.md)

> **Unofficial tool, not affiliated with Creality.** It changes a system file inside the printer.
> Read the [risks](#read-first-risks-and-limitations) below. You use it at your own risk.

---

## What does it do?

| | Normally | With this tool |
|---|---|---|
| Brands on the screen | Only **Creality** and **Generic** | Creality, Generic **and your brands** |
| Custom filaments you made in Creality Print | **Not shown** | Shown **with their own brand and name** |
| Example | Generic → ABS → Generic ABS | **Porima** → ABS → **Porima ABS Basic** |

You run it once. Run it again after adding custom filaments in Creality Print or after a firmware update.

## Why don't they show up?

The printer already downloads all personal filament profiles from your Creality account. It only puts the ones
**derived from a system profile** on the screen, though. Profiles made with **"Add custom filament"** in Creality
Print have an empty parent (`inherits`), so the printer silently skips them.

If you derive a profile from a Generic one with **"Save as"**, it does appear, but its brand always shows as **Generic**.
This tool adds real entries with your brand to the printer's own material list.

---

## Read first: risks and limitations

- **Root access is required.** You need to turn on root (SSH) login on the printer. Some sources say this may affect
  your warranty, and the printer shows a risk warning when you turn it on.
- **A system file is changed.** The tool edits the printer's material list. If something goes wrong, material
  selection on the screen could break. So before every change the tool **backs up** on both the printer and the PC,
  runs a **trial** first, and offers one-click **restore**.
- **A firmware update will most likely remove the entries.** Run the tool again after updating.
- **If Creality updates its official material list**, the effect is unknown. If your brands disappear, just run the tool again.
- **The screen entry only describes the slot.** Printing temperature, speed and other settings come from your Creality
  Print profile through the G-code. While loading and unloading filament, though, the printer may use the screen
  entry's temperature range; watch the first use of each new filament.
- **Creality Print may not match the slot to your profile automatically.** Pick the slot and the profile yourself when sending a print.
- **Auto refill:** slots with the same type and the same colour count as "the same material". If you use different
  brands, give their slots **different colours**, or the printer may switch to the other one when one runs out.
- **Types the printer does not know, such as HIPS,** show on the screen with their own type. This worked fine on a
  K2 Pro; if it causes trouble, see [Troubleshooting](#troubleshooting-faq).
- **Only tested on the K2 Pro.** Not tested on the K2 Plus, K2 or K2 SE. On those, run the trial mode first (`-DryRun`,
  below). Sharing the result in an [Issue](../../issues) helps others.
- **Do not run it while printing.** The tool stops on its own if the printer is printing.
- **The screen does not filter by nozzle size.** Each filament family is **one entry** on the screen covering its
  0.2/0.4/0.6/0.8 profiles together.
- **Do not create many profiles in Creality Print in a short time.** Not about this tool, but Creality's cloud can
  temporarily restrict an account after bulk operations (`1088 Please do not repeat the same operation`).

---

## Requirements

- **Printer:** Creality K2 Pro (tested). K2 Plus / K2 / K2 SE (not tested).
- **Computer:** Windows 10 or 11 (for the scripted install). For Mac / Linux: [Manual install](docs/manual-install.en.md).
- **Creality Print 7.x**, with your filaments added through **"Add custom filament"**, with the right **Vendor** and
  **Type** set. Creality Print names the profile like `Porima ABS Basic @Creality K2 Pro 0.4 nozzle` by itself.
- Printer and computer on the **same network**.
- Internet on the first run (the PowerShell module needed for SSH is downloaded automatically).

---

## Install (scripted, recommended)

### 1. Turn on root access on the printer

1. On the printer screen open **Settings**, scroll down and tap **Root account information**.
2. Read the warning and tick **"I have read and understood the risks of Root login"**.
3. Wait **30 seconds**, then press **OK**.
4. Write down the **root password** shown on the screen.

After a factory reset you need to do this again.
(Sources: [SimplyPrint K2 Pro guide](https://simplyprint.io/setup-guide/creality/k2-pro/on-printer),
[Helper Script Wiki – SSH](https://sw3defy.github.io/Creality-Helper-Script-Wiki-K2-Plus/firmwares/ssh-connection/))

### 2. Find the printer's IP address

On the screen: **Settings → Network**. Example: `192.168.1.25`.

### 3. Prepare your filaments in Creality Print

- Make a profile for each filament with **"Add custom filament"** in Creality Print. Fill in **Vendor** and **Type**.
- Every nozzle size you made a profile for (0.2/0.4/0.6/0.8) goes into one screen entry. Settings come from the 0.4
  profile; if there is none, from 0.6, 0.8, then 0.2.
- Profiles you made from a Generic one with **"Save as"** already show on the screen (as Generic); the tool leaves them alone.

### 4. Download the tool

1. Click the green **Code** button at the top of this page, then **Download ZIP**.
2. Right-click the ZIP and choose **Extract All**. Do not run it from inside the ZIP.

### 5. Run it

In the extracted folder, double-click **`Install-K2CustomFilamentBrands.cmd`**.

- If Windows says **"Windows protected your PC"**: **More info → Run anyway**.
- On the first run answer `E` or `Y` to **install Posh-SSH**.
- You are asked for the **IP address** and the **root password**. The password is not shown while typing, which is
  normal. It is never saved.
- If you have custom profiles for more than one printer in Creality Print, you are asked which one this printer is.
- The tool lists the entries it will add and **tries them on the printer first**; nothing changes at this stage.
- Answer `E` or `Y` to **"Write the entries above to the printer?"**.

Example output (shortened):

```text
[2] Creality Print profilleriniz okunuyor / Reading your Creality Print profiles
   Creality Print: 7.0 | account folder: 1234567890 | printer: Creality K2 Pro | families: 21
   90001 | Porima ABS Basic         | Porima   | ABS  | nozzles 0.2,0.4,0.6,0.8
   90019 | SAVA TPU 60A             | SAVA     | TPU  | nozzles 0.2,0.4,0.6,0.8
[3] Yazicida deneniyor (canli dosyalar degismez) / Trying on the printer (live files are not changed)
   RESULT entries=77 count=77 custom=21 skipped=0 brands=Creality,Generic,Porima,SAVA,...
Write the entries above to the printer? (E/H, Y/N): Y
[5] Kontrol / Check
Printer list: 77 materials, entries from this tool: 21
Done. The brands should show on the screen right away; if not, restart the printer.
```

### 6. Check the screen

Open filament selection for a CFS slot. Your brands and their filaments should be in the brand list.
If not, restart the printer.

**To only try it first** (writes nothing): type `cmd` in the folder's address bar, press Enter, and run:

```bat
Install-K2CustomFilamentBrands.cmd -DryRun
```

---

## When should I run it again?

- **After a firmware update** (if the brands are gone).
- When you **add a custom filament** in Creality Print or change the values of an existing one.

Running it again is safe: the tool first removes the entries it added earlier, then adds the current list. The IDs
(`90001`, `90002`…) stay the same. Saving a profile in Creality Print does not remove the entries (tested).

## Uninstall and restore

| File | What it does |
|---|---|
| `Uninstall-K2CustomFilamentBrands.cmd` | Removes **only the entries this tool added**. Creality and Generic entries are not touched. |
| `Restore-K2Backup.cmd` | Puts back the **newest backup** on the printer exactly as it was (if something goes wrong). |

Backups:
- **On the printer:** `/mnt/UDISK/creality/userdata/box_backup_k2cfb_<date>/`
- **On the PC:** `Documents\K2CustomFilamentBrands\backups\<date>\`

---

## Troubleshooting (FAQ)

**"running scripts is disabled on this system"**
Do not run the `.ps1` file directly; use the `.cmd` files. They allow scripts for that run only, without changing your Windows settings.

**"Windows protected your PC"**
**More info → Run anyway**. This is a normal warning for downloaded files.

**Posh-SSH could not be installed**
Check your internet connection; a company network may block it. To install it yourself, in PowerShell:
`Install-Module Posh-SSH -Scope CurrentUser`

**"SSH connection failed"**
Is root access turned on, is the IP right, did you type the password exactly as on the screen? Are the printer and computer on the same network?

**"SKIPPED … filament type 'XYZ' has no matching printer entry"**
The profile's type could not be matched to a Generic type on the printer. In Creality Print change the profile's
**Type** to a supported one: PLA, PLA-CF, ABS, ABS-CF, ASA, PETG, PETG-CF, PET, PA, PA-CF, PC, PC-CF, TPU, PP, PVA, BVOH, HIPS.

**"SKIP … printer has no single 'Generic …' entry to copy"**
That Generic entry is not in your printer's list (other K2 models may have a different list). Change the profile's
type or open an Issue.

**"SKIP … this name is already used by another entry"**
Your filament has the same name as an entry already on the screen. Rename the profile in Creality Print.

**HIPS (or another custom type) causes trouble on the screen or CFS**
Open `tools\build_custom_spec.ps1` in Notepad, change the second `'HIPS'` in `$screenTypeOverride = @{ 'HIPS' = 'HIPS' }`
to `'ABS'`, and run the tool again.

**The brands do not show on the screen**
Restart the printer. After a firmware update, run the tool again. If the result line shows `skipped=` above zero, see the items above.

**"The printer changed its list meanwhile"**
The printer downloaded a profile from the cloud at that moment. Wait a minute and run again.

**More than one Creality account**
The tool picks the account with the most custom profiles and lists the others in a warning. For another account use
`tools\K2CustomMaterials.ps1 -UserFolder <folder name>`.

---

## How does it work? (technical)

- `tools\build_custom_spec.ps1`: reads custom filaments with an empty parent under
  `%APPDATA%\Creality\Creality Print\<version>\user\<account>\filament\`, groups them by filament family and writes `custom_spec.json`.
- `tools\printer_material_install.py`: runs with the printer's own `python3`. Copies the Generic entry of the same type
  and replaces the id, brand, name, temperature range, density, nozzle list and matching settings. Writes the new files
  only to `/tmp`.
- `tools\K2CustomMaterials.ps1`: backs up, uploads, runs the trial, asks for confirmation, swaps the files in only if
  the live files did not change meanwhile, then reads the list back from the printer to check.
- **Files on the printer:** `/mnt/UDISK/creality/userdata/box/material_database.json` (material list),
  `material_option.json` (brand → type → name list on the screen), `k2_custom_filament_brands.json` (record of what this tool added).
- **On the PC:** `Documents\K2CustomFilamentBrands\`: `custom_ids.json` (stable IDs; do not delete), `custom_spec.json`,
  `settings.json` (last IP), `backups\`.

## Manual install (Mac / Linux / without the script)

Step by step: **[docs/manual-install.en.md](docs/manual-install.en.md)**

## Contributing and feedback

If you tried it on another K2 model, please share the result in an [Issue](../../issues): printer model, firmware
version, `-DryRun` output. Screenshots help a lot.

## License and disclaimer

[MIT License](LICENSE). This software is provided "as is". The developers cannot be held responsible for any damage
to your printer, filament or warranty. "Creality", "K2" and other brand names belong to their owners; this project is
not affiliated with them.
