@echo off
setlocal

cd /d "%~dp0"

echo Android Wireless ADB Setup
echo ==========================
echo.
echo Goal:
echo   ADB without USB cable/data and without a common Wi-Fi router.
echo.
echo This launcher starts the guided setup wizard.
echo You can also drag an APK file onto START_HERE.cmd to install it at the end.
echo.

if "%~1"=="" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run-adb-rescue-wizard.ps1"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run-adb-rescue-wizard.ps1" -ApkPath "%~1"
)

echo.
echo Wizard finished. Press any key to close this window.
pause >nul
