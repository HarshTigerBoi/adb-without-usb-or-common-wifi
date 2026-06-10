# Quick Start

Use this when you want Android ADB without USB cable/data and without a common Wi-Fi router.

This works for normal ADB workflows:

- install APKs with `adb install`
- open a shell with `adb shell`
- read logs with `adb logcat`
- use tools that depend on ADB after the device appears as `device`

Once `adb devices` shows the phone as `device`, this is a normal ADB connection. Any app or tool that knows how to use ADB can use this device.

It is not tied to any AI tool, editor, or app. It is just Android Wireless debugging plus a laptop-created Wi-Fi Direct network.

## Easiest Path

Download or clone this repo on a Windows laptop, then double-click:

```text
START_HERE.cmd
```

To install an APK at the end, drag the APK file onto `START_HERE.cmd`.

You can also open PowerShell in this repository and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-adb-rescue-wizard.ps1
```

To install an APK at the end:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-adb-rescue-wizard.ps1 -ApkPath "C:\path\to\app.apk"
```

The wizard will:

1. Find or download Android platform-tools.
2. Start a laptop-created Wi-Fi Direct network.
3. Tell you what Wi-Fi network to join from the phone.
4. Optionally enable Windows Internet Connection Sharing.
5. Help pair Android Wireless debugging.
6. Connect to the real Wireless debugging connect port.
7. Optionally switch to easier reconnects on TCP port `5555`.
8. Optionally install an APK.

## Minimum Requirements

- Windows 10/11 laptop with Wi-Fi Direct support.
- Android 11+ phone with Developer options.
- Wireless debugging enabled on the phone.
- Phone and laptop must be able to reach each other on a local network.
- Pairing code/port and connect port must be treated as different values.

## Manual Commands After Setup

Check devices:

```powershell
.\work\android\platform-tools\adb.exe devices -l
```

Connect to a saved `:5555` target:

```powershell
.\work\android\platform-tools\adb.exe connect <PHONE_IP_OR_GATEWAY>:5555
```

Install an APK:

```powershell
.\work\android\platform-tools\adb.exe -s <ADB_SERIAL> install -r "C:\path\to\app.apk"
```

If only one device is connected:

```powershell
.\work\android\platform-tools\adb.exe install -r "C:\path\to\app.apk"
```
