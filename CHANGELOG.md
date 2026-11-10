# Changelog

## 1.0.0 – 2026-11-10

- First release. Tested on a Creality K2 Pro (model code F012) with Creality Print 7.2.
- Windows one-click install, uninstall and restore (`.cmd` launchers, no system setting changes).
- Reads "Add custom filament" profiles from Creality Print, one screen entry per filament family covering all nozzle sizes.
- Printer-side installer (`tools/printer_material_install.py`) with trial run, marker file, safe re-runs and `--remove`.
- Backups on the printer and the PC before every change.
- Takes over entries left by an earlier manual install when their ID and name match.
- Manual install guide for Mac / Linux (Turkish and English).
