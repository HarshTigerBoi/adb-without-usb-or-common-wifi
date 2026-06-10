# Android Wireless ADB Rescue

Use this when an Android phone only charges over USB, USB ADB does not enumerate, and you still need `adb install`, `logcat`, or shell access.

This workaround is for a Windows laptop and an Android phone with **Wireless debugging**. It creates a second local Wi-Fi path from the laptop using Windows Wi-Fi Direct Legacy AP, pairs Wireless ADB over that path, then switches ADB to classic TCP port `5555` for easier reconnects.

## When This Helps

- USB only charges, but no file transfer / MTP / ADB appears.
- Windows shows errors such as:
  - `Unknown USB Device (Port Reset Failed)`
  - `USB\VID_0000&PID_0001`
  - `Device Descriptor Request Failed`
- Another phone works on the same laptop, so the laptop USB stack is probably fine.
- Wireless debugging pairs, but `adb connect` fails because the phone does not show or expose a connect port.
- Your laptop depends on the phone hotspot for internet, which makes the usual "same Wi-Fi network" requirement awkward.

## What You Need

- Windows 10/11 laptop with Wi-Fi Direct virtual adapter support.
- Android 11+ phone with Developer options and Wireless debugging.
- Android platform-tools (`adb.exe`).
- The phone must be able to join a Wi-Fi network created by the laptop.
- The laptop and phone must have at least one reachable local network path.

This does **not** fix broken USB hardware. It bypasses USB data by using Wireless ADB.

## Fast Path for Future Codex Chats

Paste this into another Codex chat:

```text
I have a Windows laptop and an Android phone whose USB data path is broken. Wireless ADB was previously made to work by creating a Windows Wi-Fi Direct Legacy AP, pairing Android Wireless debugging, then switching ADB to TCP port 5555.

Please first check:
.\work\android\platform-tools\adb.exe devices -l

If the phone is not connected, reconnect with:
.\work\android\platform-tools\adb.exe connect <PHONE_HOTSPOT_GATEWAY_OR_PHONE_IP>:5555

Do not disconnect the laptop from the phone hotspot unless I explicitly say it is okay. If :5555 is not listening, use the full rescue flow from README.md: start the Wi-Fi Direct AP, enable ICS, pair Wireless debugging, connect to the discovered _adb-tls-connect endpoint, then run adb tcpip 5555.

To install my APK, run:
.\work\android\platform-tools\adb.exe -s <ADB_SERIAL> install -r "C:\path\to\app.apk"
```

## Install Platform Tools

```powershell
New-Item -ItemType Directory -Path .\work\android -Force | Out-Null
curl.exe -L --fail --output .\work\android\platform-tools-latest-windows.zip https://dl.google.com/android/repository/platform-tools-latest-windows.zip
Expand-Archive -Path .\work\android\platform-tools-latest-windows.zip -DestinationPath .\work\android -Force
.\work\android\platform-tools\adb.exe version
```

## Start the Laptop Wi-Fi Direct AP

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-wifi-direct-ap.ps1
```

Defaults:

```text
SSID: ADBBridge
Password: ChangeMe123!
Laptop AP IP: usually 192.168.137.1
```

Keep this PowerShell process running.

## Share Internet Into the AP

This is optional in theory, but it helped make Android expose the Wireless debugging connect service reliably.

Run as administrator:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\enable-ics-to-adbbridge.ps1
```

Default adapter names:

```text
Public internet adapter: Wi-Fi
Private AP adapter: Local Area Connection* 2
```

If your Windows adapter names differ, edit the variables at the top of the script.

## Phone Setup

On the phone:

1. Enable Developer options.
2. Enable **USB debugging**.
3. Enable **Wireless debugging**.
4. If available, enable **Install via USB** and **USB debugging/security settings**.
5. Connect phone Wi-Fi to `ADBBridge`.
6. If Android says there is no internet, choose **Stay connected** or **Use this network anyway**.

If the laptop must stay on the phone hotspot for internet, keep that connection alive. Do not disconnect it while working unless you have another internet path.

## Clear Stale ADB State

If pairing got messy:

On the phone:

1. Wireless debugging -> Paired devices.
2. Forget the old laptop pairing.

On the laptop:

```powershell
.\work\android\platform-tools\adb.exe kill-server
Get-Process adb -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-Item "$env:USERPROFILE\.android\adb_known_hosts.pb" -Force -ErrorAction SilentlyContinue
.\work\android\platform-tools\adb.exe start-server
```

## Pair and Connect

On the phone:

1. Wireless debugging -> Pair device with pairing code.
2. Keep the pairing popup open.

On the laptop:

```powershell
.\work\android\platform-tools\adb.exe mdns services
```

You want to see both services:

```text
<id>    _adb-tls-pairing._tcp    <PAIRING_IP>:<PAIR_PORT>
<id>    _adb-tls-connect._tcp    <CONNECT_IP>:<CONNECT_PORT>
```

Pair:

```powershell
.\work\android\platform-tools\adb.exe pair <PAIRING_IP>:<PAIR_PORT> <SIX_DIGIT_CODE>
```

Connect:

```powershell
.\work\android\platform-tools\adb.exe connect <CONNECT_IP>:<CONNECT_PORT>
.\work\android\platform-tools\adb.exe devices -l
```

Expected:

```text
<CONNECT_IP>:<CONNECT_PORT>    device ...
```

## Make Reconnect Easy with Port 5555

Once connected, switch to classic TCP mode:

```powershell
.\work\android\platform-tools\adb.exe -s <CONNECT_IP>:<CONNECT_PORT> tcpip 5555
```

Reconnect:

```powershell
.\work\android\platform-tools\adb.exe connect <PHONE_IP_OR_GATEWAY>:5555
.\work\android\platform-tools\adb.exe devices -l
```

If duplicate transports appear:

```powershell
.\work\android\platform-tools\adb.exe disconnect
.\work\android\platform-tools\adb.exe connect <PHONE_IP_OR_GATEWAY>:5555
```

## Install APK

```powershell
.\work\android\platform-tools\adb.exe -s <ADB_SERIAL> install -r "C:\path\to\app.apk"
```

If only one device is connected:

```powershell
.\work\android\platform-tools\adb.exe install -r "C:\path\to\app.apk"
```

## Limitations

- Wireless debugging must be allowed by the phone OS.
- An ordinary Android app cannot enable ADB or install other apps silently.
- This does not repair USB-C data pins or a damaged charging daughterboard.
- Port `5555` ADB may stop after reboot, toggling Wireless debugging, or changing networks.
- Pairing ports are temporary and are not connect ports.
- Do not run `adb connect` against the pairing port; it can create stale `offline` devices.
- If the phone shows only an IP and no port on the Wireless debugging page, the connect listener is not active yet.
- Some OEM skins require a real Wi-Fi client connection before Wireless debugging opens the connect socket.

## Why This Works

Wireless debugging has two stages:

1. Pair with a temporary pairing endpoint.
2. Connect to a separate TLS ADB endpoint.

Some phones expose the pairing endpoint but fail to expose the connect endpoint when the phone is acting as the hotspot. Creating a laptop Wi-Fi Direct Legacy AP gives the phone a client Wi-Fi path. Sharing internet into that AP can make the phone treat it as a normal usable Wi-Fi network. Once Wireless ADB connects once, switching to classic TCP `5555` makes future reconnects much easier.
