@echo off
rem K2 Custom Filament Brands - remove only the entries this tool added.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\K2CustomMaterials.ps1" -Action Uninstall %*
echo.
pause
