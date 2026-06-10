# Android Wireless ADB Without USB or a Common Wi-Fi Router

Use Android `adb install`, `adb shell`, `adb logcat`, Android Studio, scrcpy, or any other ADB-based workflow when you **do not have a usable USB data cable** and **do not have a common Wi-Fi router** for both devices.

## Start Here

Download or clone this repo on a Windows laptop, then use one of these:

```text
Double-click START_HERE.cmd
```

or run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-adb-rescue-wizard.ps1
```

To install an APK at the end, drag the APK file onto `START_HERE.cmd`, or run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-adb-rescue-wizard.ps1 -ApkPath "C:\path\to\app.apk"
```

The wizard handles the laptop side and pauses for the few phone taps Android requires:

1. Download/find ADB.
2. Start a laptop-created Wi-Fi Direct network.
3. Tell you what Wi-Fi to join from the phone.
4. Help pair Android Wireless debugging.
5. Connect ADB.
6. Optionally switch to TCP `5555` for easier reconnects.
7. Optionally install an APK.

The setup uses only what many people already have:

- one Windows laptop
- one Android phone
- the phone's hotspot for laptop internet, if needed
- a laptop-created Wi-Fi Direct network for Android Wireless debugging

After the first Wireless ADB connection works, the phone can be switched to classic TCP ADB on port `5555` for easier reconnects.

Once `adb devices` shows the phone as `device`, the connection is normal ADB. Any tool that uses ADB can use it.

## Core Idea

Android Wireless debugging needs a network path. Usually that means both devices are on the same home/router Wi-Fi. If you do not have that, Windows can create a local Wi-Fi Direct Legacy AP. The phone joins that AP, the laptop pairs with Android Wireless debugging, and then ADB works without USB data.

This is best described as:

```text
ADB without USB cable/data and without a common Wi-Fi router.
```

It is not literally "ADB without Wi-Fi"; it creates a tiny local Wi-Fi network from the laptop.

## What to Call This

Useful search phrases:

- ADB without USB cable
- ADB without USB data
- ADB without common Wi-Fi
- Wireless ADB without external Wi-Fi
- Android wireless debugging without router
- ADB install without USB cable
- Windows Wi-Fi Direct ADB bridge
- Android debugging using phone hotspot and laptop Wi-Fi

Important wording: this is **not ADB without any Wi-Fi radio at all**. ADB still needs a network path. The trick is that you do not need a home router, public Wi-Fi, or working USB data. The Windows laptop creates a local Wi-Fi Direct AP, and the phone connects to that.

## When This Helps

- You do not want to use a USB cable.
- You have no USB data cable, only charging cables.
- Your phone's USB data path is broken, flaky, or inconvenient.
- You do not have a common Wi-Fi router for both laptop and phone.
- The laptop is using the phone hotspot for internet, so the phone is the hotspot host instead of a normal Wi-Fi client.
- Wireless debugging pairs but `adb connect` fails because the phone does not expose a reachable connect port.

Also useful when Windows shows USB errors such as:

- `Unknown USB Device (Port Reset Failed)`
- `USB\VID_0000&PID_0001`
- `Device Descriptor Request Failed`

## What This Does Not Do

- It does not debug over "nothing"; it uses a local Wi-Fi Direct network made by the laptop.
- It does not repair a broken USB-C port or charging board.
- It does not bypass Android security. Wireless debugging must be enabled and paired by the phone owner.
- It does not let a normal Android app silently install/debug other apps.

## What You Need

- Windows 10/11 laptop with Wi-Fi Direct virtual adapter support.
- Android 11+ phone with Developer options and Wireless debugging.
- Android platform-tools (`adb.exe`).
- The phone must be able to join a Wi-Fi network created by the laptop.
- The laptop and phone must have at least one reachable local network path.

This bypasses USB data by using Wireless ADB. It can help whether USB is broken, unavailable, or simply not desired.

## Value Decoder: What Each Placeholder Means

Wireless ADB has two different screens and two different ports. Most failures happen because the pairing port is mistaken for the connect port.

### Pairing Popup Values

![Annotated pairing popup](assets/wireless-debugging-pairing.svg)

When you tap **Pair device with pairing code**, Android shows:

- `SIX_DIGIT_CODE`: the six-digit number, for example `123456`.
- `PAIRING_IP:PAIR_PORT`: the temporary pairing address, for example `192.168.137.42:43123`.

Use these only with:

```powershell
adb pair <PAIRING_IP>:<PAIR_PORT> <SIX_DIGIT_CODE>
```

Do **not** use the pairing port with `adb connect`.

### Main Wireless Debugging Screen Values

![Annotated main Wireless debugging screen](assets/wireless-debugging-main.svg)

After pairing, close the pairing popup and return to the main **Wireless debugging** screen.

The line labeled **IP address and port** should show:

```text
<CONNECT_IP>:<CONNECT_PORT>
```

Use that with:

```powershell
adb connect <CONNECT_IP>:<CONNECT_PORT>
```

If the screen shows only an IP with no `:port`, the ADB connect listener is not active yet. Toggle Wireless debugging off/on, reconnect Wi-Fi, or follow the Wi-Fi Direct AP + ICS flow below.

### Network Topology

![Wireless ADB rescue topology](assets/topology.svg)

Common placeholders:

| Placeholder | Meaning | How to find it |
|---|---|---|
| `<PAIRING_IP>:<PAIR_PORT>` | Temporary endpoint from the pairing popup | Phone -> Wireless debugging -> Pair device with pairing code |
| `<SIX_DIGIT_CODE>` | Temporary six-digit pairing code | Same pairing popup |
| `<CONNECT_IP>:<CONNECT_PORT>` | Actual ADB connection endpoint | Main Wireless debugging screen, or `adb mdns services` as `_adb-tls-connect._tcp` |
| `<PHONE_HOTSPOT_GATEWAY>` | Phone's hotspot-side IP as seen by Windows | `Get-NetIPConfiguration -InterfaceAlias 'Wi-Fi'` -> `IPv4DefaultGateway` |
| `<LAPTOP_WIFI_IP>` | Laptop's IP on the phone hotspot | `Get-NetIPConfiguration -InterfaceAlias 'Wi-Fi'` -> `IPv4Address` |
| `<ADB_SERIAL>` | Device identifier shown by ADB | `adb devices -l` |

Example mDNS output:

```text
adb-xxxx  _adb-tls-pairing._tcp  192.168.137.42:43123
adb-xxxx  _adb-tls-connect._tcp  192.168.137.42:45678
```

Correct commands for that example:

```powershell
adb pair 192.168.137.42:43123 123456
adb connect 192.168.137.42:45678
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
