# Quick Handoff for Another Codex Chat

Copy this into another Codex chat:

```text
My Android phone USB data path is broken, but wireless ADB was made to work before.

Please do not disconnect my laptop from the phone hotspot unless I explicitly say so.

First check:
.\work\android\platform-tools\adb.exe devices -l

If a device appears on :5555, use that serial for install:
.\work\android\platform-tools\adb.exe -s <ADB_SERIAL> install -r "C:\path\to\app.apk"

If no device appears, try:
.\work\android\platform-tools\adb.exe connect <PHONE_IP_OR_GATEWAY>:5555

If :5555 is not listening, follow the repo README:
1. Start scripts\start-wifi-direct-ap.ps1.
2. Enable ICS with scripts\enable-ics-to-adbbridge.ps1.
3. Connect the phone Wi-Fi to ADBBridge.
4. In phone Wireless debugging, forget stale paired devices.
5. Pair with adb pair <PAIRING_IP>:<PAIR_PORT> <CODE>.
6. Connect to the discovered _adb-tls-connect endpoint.
7. Run adb tcpip 5555.
8. Reconnect on <PHONE_IP_OR_GATEWAY>:5555.
9. Install the APK.
```

Minimum things that must be true:

- Android Wireless debugging is on.
- The phone and laptop can reach each other on at least one local network.
- `adb.exe` from Android platform-tools exists.
- The phone shows as `device`, not `offline`, before installing.

