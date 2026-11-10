@echo off
rem K2 Custom Filament Brands - put back the newest backup this tool made on the printer.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\K2CustomMaterials.ps1" -Action Restore %*
echo.
pause
