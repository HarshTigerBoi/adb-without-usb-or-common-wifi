# Quick Start

Use this when you want Android ADB without USB cable/data and without a common Wi-Fi router.

## One Linear Process

1. Download this repo as ZIP and extract it.
2. Open the extracted folder.
3. Double-click `START_HERE.cmd`.
4. If installing an APK, drag the APK onto `START_HERE.cmd` instead of double-clicking it.
5. If the wizard asks to download Android platform-tools, press Enter for yes.
6. Keep the second PowerShell window open if it appears.
7. Connect the phone Wi-Fi to the network shown by the wizard.
8. If Android says no internet, choose **Stay connected** or **Use this network anyway**.
9. In the wizard, press Enter after the phone is connected.
10. If asked to enable Windows Internet Connection Sharing, press Enter for yes.
11. On the phone, open Developer options -> Wireless debugging.
12. Tap **Pair device with pairing code**.
13. Keep the pairing popup open.
14. If asked for the pairing IP and port, copy it from the pairing popup.
15. Enter the six-digit pairing code into the wizard.
16. After pairing, close the pairing popup.
17. Stay on the main Wireless debugging screen.
18. If asked for the connect IP and port, copy it from the main Wireless debugging screen.
19. Press Enter for yes when asked to switch to TCP port `5555`.
20. Success means `adb devices -l` shows the phone as `device`.

After success, use normal ADB commands:

```powershell
.\work\android\platform-tools\adb.exe install -r "C:\path\to\app.apk"
.\work\android\platform-tools\adb.exe shell
.\work\android\platform-tools\adb.exe logcat
```

For screenshots, value meanings, manual commands, and troubleshooting, read [GUIDE.md](GUIDE.md).
