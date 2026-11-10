@echo off
rem K2 Custom Filament Brands - install / update.
rem Double-click to run. Extra options are passed through, e.g.:  Install-K2CustomFilamentBrands.cmd -DryRun
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\K2CustomMaterials.ps1" -Action Install %*
echo.
pause
