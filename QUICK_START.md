# Quick Start

Use this when you want Android ADB without USB cable/data and without a common Wi-Fi router.

## One Linear Process

1. Download this repo as ZIP and extract it.
2. Open the extracted folder.
3. Double-click `START_HERE.cmd`.
4. If installing an APK, drag the APK onto `START_HERE.cmd` instead of double-clicking it.
5. If the wizard asks to download Android platform-tools, press Enter for yes.
6. If an old connection still works, the wizard will reuse it and skip pairing.
7. If the wizard starts a second PowerShell window, keep it open.
8. If the wizard shows a Wi-Fi network, connect the phone Wi-Fi to that network.
9. If Android says no internet, choose **Stay connected** or **Use this network anyway**.
10. If the wizard asks, press Enter after the phone is connected.
11. If asked to enable Windows Internet Connection Sharing, press Enter for yes.
12. On the phone, open Developer options -> Wireless debugging.
13. If Wireless debugging was already on but the wizard cannot connect, turn it off and on once.
14. Tap **Pair device with pairing code**.
15. Keep the pairing popup open.
16. If asked for the pairing IP and port, copy it from the pairing popup.
17. Enter the six-digit pairing code into the wizard.
18. After pairing, close the pairing popup.
19. Stay on the main Wireless debugging screen.
20. If asked for the connect IP and port, copy it from the main Wireless debugging screen.
21. Press Enter for yes when asked to switch to stable TCP ADB mode.
22. Success means `adb devices -l` shows the phone as `device`.

For later use, run `START_HERE.cmd` again. If Android has closed the old ADB listener, the wizard will tell you and take you through pairing again.

After success, use normal ADB commands:

```powershell
.\work\android\platform-tools\adb.exe install -r "C:\path\to\app.apk"
.\work\android\platform-tools\adb.exe shell
.\work\android\platform-tools\adb.exe logcat
```

For screenshots, value meanings, manual commands, and troubleshooting, read [GUIDE.md](GUIDE.md).
