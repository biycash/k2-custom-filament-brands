# Manual install (Mac / Linux / without the script)

🇹🇷 [Türkçe](manual-install.md) · [Back to the main page](../README.en.md)

On Windows the easiest way is the [scripted install](../README.en.md#install-scripted-recommended). This page is for
Mac/Linux users and anyone who wants to see each step. Before you start, read the
[risks](../README.en.md#read-first-risks-and-limitations) on the main page.

There are two ways:

| | Way A: list + Python on the printer (recommended) | Way B: edit the file fully by hand |
|---|---|---|
| Difficulty | Easy–medium | Medium–hard |
| Risk of mistakes | Low; Python checks it | High; one wrong comma breaks the list |
| Reinstall and removal | One command | By hand |

## Common preparation

1. **Turn on root access:** on the screen, **Settings → Root account information**. Tick the box, wait 30 seconds,
   press **OK** and write down the password.
2. **Find the IP address:** on the screen, **Settings → Network**.
3. **Tools to connect:**
   - **Mac / Linux:** the built-in **Terminal** is enough (`ssh` and `scp`).
   - **Windows, by hand:** [WinSCP](https://winscp.net) (copy and edit files) and WinSCP's **"Open in PuTTY"** or
     Windows' own `ssh` command.
4. **The printer must not be printing.**

Below, replace `PRINTER_IP` with your IP address. When asked, enter the root password; it is not shown while you type, which is normal.

---

## Way A: list file + Python on the printer (recommended)

You write the filaments you want into a small list file and the printer's own Python adds them safely. It is the
same program the scripted install uses.

### A1. Prepare the list file

Copy [`examples/custom_spec.example.json`](../examples/custom_spec.example.json) from this repository, save it as
`my_spec.json` and edit it. Each filament is one block:

```json
{
  "parent": "Generic ABS",
  "nozzles": ["0.2", "0.4", "0.6", "0.8"],
  "base": { "id": "90001", "brand": "Porima", "name": "Porima ABS Basic", "minTemp": 230, "maxTemp": 260, "density": 1.04 },
  "kv": { "filament_vendor": "Porima", "nozzle_temperature": "250", "hot_plate_temp": "100" }
}
```

| Field | What to write |
|---|---|
| `parent` | The Generic entry to copy, of the same type: `Generic PLA`, `Generic ABS`, `Generic PETG`, `Generic ASA`, `Generic PA`, `Generic PA6-CF`, `Generic PC`, `Generic TPU`, `Generic ABS-CF`, `Generic PLA-CF`, `Generic PETG-CF`, `Generic PET`… |
| `nozzles` | The nozzles you use this filament with |
| `base.id` | A **unique** 5-digit ID. Start at `90001` and count up. Do not change it once given. |
| `base.brand` | Brand shown on the screen |
| `base.name` | Name shown on the screen. It must not match a name already on the screen. |
| `base.minTemp` / `maxTemp` | Nozzle temperature range (°C). May be used while loading and unloading. |
| `base.density` | Density (g/cm³). Optional. |
| `base.meterialType` | **Only** for types with no Generic entry on the printer, e.g. HIPS: `"meterialType": "HIPS"` with `"parent": "Generic ABS"` |
| `kv` | Settings you want to change. Values are written **in quotes**: `"250"`. Only settings that already exist in the Generic entry are changed. |

JSON rules: put a comma between blocks, no comma after the last block, and write text in double quotes.
You can check the file on a site such as [jsonlint.com](https://jsonlint.com) before saving.

### A2. Copy the files to the printer

Open a Terminal in the repository folder:

```sh
scp tools/printer_material_install.py my_spec.json root@PRINTER_IP:/tmp/
```

### A3. Connect to the printer and back up

```sh
ssh root@PRINTER_IP
```

Once connected (the following commands run on the printer):

```sh
B=/mnt/UDISK/creality/userdata/box
mkdir -p /mnt/UDISK/creality/userdata/box_backup_manual
cp -a $B/material_database.json $B/material_option.json /mnt/UDISK/creality/userdata/box_backup_manual/
```

### A4. Try it (nothing changes)

```sh
python3 /tmp/printer_material_install.py --spec /tmp/my_spec.json
```

You should see an `ADD …` line for each filament and `RESULT … skipped=0` at the end. `SKIP` lines say what was not
added and why, for example a wrong `parent` or a name that already exists. This command writes the new files only to `/tmp`.

### A5. Apply

```sh
cp /tmp/new_material_database.json $B/material_database.json
cp /tmp/new_material_option.json $B/material_option.json
cp /tmp/new_k2_custom_filament_brands.json $B/k2_custom_filament_brands.json
sync
```

Check your brands on the screen; if they do not show, restart the printer.

### Changes, reinstall, removal

- **Your list changed or the firmware was updated:** repeat A2–A5. The tool removes what it added before and adds it again.
- **Removal:** instead of A4 run `python3 /tmp/printer_material_install.py --remove`, then the three `cp` commands from A5.
- **If something goes wrong, put the backup back:**
  ```sh
  cp -a /mnt/UDISK/creality/userdata/box_backup_manual/material_database.json \
        /mnt/UDISK/creality/userdata/box_backup_manual/material_option.json $B/
  rm -f $B/k2_custom_filament_brands.json
  sync
  ```

---

## Way B: edit the file fully by hand (with WinSCP)

No Python: you change the files in a text editor. This needs care: a single wrong comma can break the material list
on the screen. **Do not start without a backup.**

### B1. Connect with WinSCP

- **File protocol:** SFTP · **Host name:** `PRINTER_IP` · **User name:** `root` · **Password:** the root password from the screen
- Go to `/mnt/UDISK/creality/userdata/box/`.

### B2. Back up

Download `material_database.json` and `material_option.json` to your computer and **keep a copy**.

### B3. Add an entry to `material_database.json`

Open the file in an editor that highlights JSON (Notepad++ or VS Code; Windows Notepad is not recommended). The file
may be a single line; in VS Code **Format Document** makes it readable.

1. Find the entry with `"name":"Generic ABS"`. It starts with `{"engineVersion":` and ends with `"base":{…}}`.
2. Copy the **whole** entry, including its braces.
3. Paste it right after `"list":[` and put a comma after it: `"list":[{…your entry…},{…first existing entry…`
4. In your pasted copy change:
   - inside `"base"`: `"id"` → `"90001"` (unique), `"brand"` → `"Porima"`, `"name"` → `"Porima ABS Basic"`,
     `"minTemp"` / `"maxTemp"` → your range.
   - `"nozzleDiameter"` → the nozzles you use, for example `["0.2","0.4","0.6","0.8"]`.
   - optionally values inside `"kvParam"` (for example `"nozzle_temperature":"250"`).
5. Increase `"count":` near the end of the file by the number of entries you added.

### B4. Add the brand to `material_option.json`

This file is the **brand → type → name** list on the screen. Add your brand before the last `}`, with a comma after the previous brand:

```json
  "Porima":{
    "ABS":"Porima ABS Basic\nPorima ABS Eco",
    "PLA":"Porima PLA Premium"
  }
```

Several names of the same type are separated by `\n`. The type (`"ABS"`) must match the entry's `"meterialType"`.

### B5. Check, upload, verify

1. Check both files on a site such as [jsonlint.com](https://jsonlint.com); you should see **"Valid JSON"**.
2. Upload the files back to the same place with WinSCP (overwrite).
3. Check the screen; restart the printer if needed.
4. If anything goes wrong, upload the backups from B2.

Note: entries added with Way B are not written to this tool's record file (`k2_custom_filament_brands.json`). If you
later switch to the scripted install, entries whose ID **and** name match what the script generates are taken over
automatically; you may need to delete the others by hand.
