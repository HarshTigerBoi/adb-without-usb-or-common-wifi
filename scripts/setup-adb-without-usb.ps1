param(
  [string]$Adb = '.\work\android\platform-tools\adb.exe',
  [string]$ApkPath,
  [string]$Ssid = 'ADBBridge',
  [string]$Password = 'ChangeMe123!',
  [string]$PublicAdapter = 'Wi-Fi',
  [string]$PrivateAdapter = 'Local Area Connection* 2',
  [int]$StableTcpPort = 5555,
  [switch]$SkipAp,
  [switch]$SkipIcs,
  [switch]$SkipTcp5555
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot
$stateFile = Join-Path $repoRoot 'work\adb-without-usb-last-endpoint.txt'

function Write-Section {
  param([string]$Title)
  Write-Host ''
  Write-Host "=== $Title ===" -ForegroundColor Cyan
}

function Read-YesNo {
  param(
    [string]$Prompt,
    [bool]$DefaultYes = $true
  )

  $suffix = if ($DefaultYes) { '[Y/n]' } else { '[y/N]' }
  $answer = Read-Host "$Prompt $suffix"
  if ([string]::IsNullOrWhiteSpace($answer)) {
    return $DefaultYes
  }
  return $answer -match '^(y|yes)$'
}

function Resolve-AdbPath {
  param([string]$RequestedPath)

  if (Test-Path $RequestedPath) {
    return (Resolve-Path $RequestedPath).Path
  }

  $cmd = Get-Command adb -ErrorAction SilentlyContinue
  if ($cmd) {
    return $cmd.Source
  }

  if (-not (Read-YesNo 'adb.exe was not found. Download Android platform-tools now?')) {
    throw 'adb.exe is required. Install Android platform-tools, then rerun this script.'
  }

  $androidDir = Join-Path $repoRoot 'work\android'
  $zipPath = Join-Path $androidDir 'platform-tools-latest-windows.zip'
  New-Item -ItemType Directory -Path $androidDir -Force | Out-Null

  Write-Host 'Downloading Android platform-tools...'
  curl.exe -L --fail --output $zipPath 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip'
  Expand-Archive -Path $zipPath -DestinationPath $androidDir -Force

  $downloadedAdb = Join-Path $androidDir 'platform-tools\adb.exe'
  if (-not (Test-Path $downloadedAdb)) {
    throw 'Downloaded platform-tools, but adb.exe was not found where expected.'
  }

  return (Resolve-Path $downloadedAdb).Path
}

function Get-MdnsEndpoint {
  param(
    [string]$AdbPath,
    [string]$ServiceName
  )

  $output = & $AdbPath mdns services 2>$null
  foreach ($line in $output) {
    if ($line -match [regex]::Escape($ServiceName) -and $line -match '((?:\d{1,3}\.){3}\d{1,3}):(\d+)') {
      return "$($matches[1]):$($matches[2])"
    }
  }

  return $null
}

function Wait-MdnsEndpoint {
  param(
    [string]$AdbPath,
    [string]$ServiceName,
    [string]$Label
  )

  for ($i = 1; $i -le 12; $i++) {
    $endpoint = Get-MdnsEndpoint -AdbPath $AdbPath -ServiceName $ServiceName
    if ($endpoint) {
      Write-Host "Found $Label endpoint: $endpoint"
      return $endpoint
    }

    Write-Host "Waiting for $Label endpoint... ($i/12)"
    Start-Sleep -Seconds 5
  }

  return $null
}

function Get-DefaultGatewayEndpoint {
  param(
    [string]$AdapterName,
    [int]$Port
  )

  $config = Get-NetIPConfiguration -InterfaceAlias $AdapterName -ErrorAction SilentlyContinue
  $gateway = $config.IPv4DefaultGateway.NextHop | Select-Object -First 1
  if ($gateway) {
    return "${gateway}:$Port"
  }

  return $null
}

function Get-SavedEndpoint {
  if (Test-Path $stateFile) {
    $line = Get-Content -Path $stateFile -TotalCount 1
    if ($line) {
      $endpoint = $line.Trim()
      if ($endpoint -match '^.+:\d+$') {
        return $endpoint
      }
    }
  }

  return $null
}

function Save-Endpoint {
  param([string]$Endpoint)

  if ($Endpoint -match '^.+:\d+$') {
    New-Item -ItemType Directory -Path (Split-Path -Parent $stateFile) -Force | Out-Null
    Set-Content -Path $stateFile -Value $Endpoint
  }
}

function Get-ReadyAdbSerial {
  param([string]$AdbPath)

  $devices = & $AdbPath devices -l 2>$null
  foreach ($line in $devices) {
    if ($line -match '^(\S+)\s+device\b') {
      $serial = $matches[1]
      if ($serial -notmatch '^emulator-') {
        return $serial
      }
    }
  }

  return $null
}

function Test-TcpEndpointOpen {
  param([string]$Endpoint)

  if ($Endpoint -notmatch '^(.+):(\d+)$') {
    return $false
  }

  $hostName = $matches[1]
  $port = [int]$matches[2]
  $client = [System.Net.Sockets.TcpClient]::new()
  try {
    $task = $client.ConnectAsync($hostName, $port)
    return ($task.Wait(1500) -and $client.Connected)
  } catch {
    return $false
  } finally {
    $client.Close()
    $client.Dispose()
  }
}

function Try-AdbConnect {
  param(
    [string]$AdbPath,
    [string]$Endpoint,
    [string]$Label
  )

  if ([string]::IsNullOrWhiteSpace($Endpoint)) {
    return $false
  }

  Write-Host "Trying $Label endpoint: $Endpoint"
  if (-not (Test-TcpEndpointOpen -Endpoint $Endpoint)) {
    Write-Host "That endpoint is not open right now."
    return $false
  }

  & $AdbPath connect $Endpoint | Out-Host
  Start-Sleep -Seconds 1
  & $AdbPath devices -l | Out-Host

  $readySerial = Get-ReadyAdbSerial -AdbPath $AdbPath
  if ($readySerial) {
    Save-Endpoint -Endpoint $Endpoint
    Write-Host "ADB is ready on $readySerial"
    return $true
  }

  return $false
}

Write-Section 'ADB Without USB or Common Wi-Fi Wizard'
Write-Host 'Goal: ADB without USB cable/data and without a common Wi-Fi router.'
Write-Host 'This still uses Wi-Fi: the laptop creates a small local Wi-Fi Direct network.'

$adbPath = Resolve-AdbPath -RequestedPath $Adb
Write-Host "Using adb: $adbPath"
& $adbPath start-server | Out-Host

Write-Section 'Try Existing ADB Connection'
$connected = $false
$readySerial = Get-ReadyAdbSerial -AdbPath $adbPath
if ($readySerial) {
  Write-Host "ADB is already ready on $readySerial"
  $connected = $true
} else {
  Write-Host 'No ready wireless phone is currently connected.'
  Write-Host 'Wireless debugging being ON is permission; it does not always mean Android is listening right now.'

  $savedEndpoint = Get-SavedEndpoint
  if ($savedEndpoint) {
    $connected = Try-AdbConnect -AdbPath $adbPath -Endpoint $savedEndpoint -Label 'last saved stable TCP ADB'
  }

  if (-not $connected) {
    $default5555 = Get-DefaultGatewayEndpoint -AdapterName $PublicAdapter -Port $StableTcpPort
    if ($default5555) {
      $connected = Try-AdbConnect -AdbPath $adbPath -Endpoint $default5555 -Label 'phone hotspot gateway stable TCP ADB'
    }
  }

  if (-not $connected) {
    $mdnsConnect = Get-MdnsEndpoint -AdbPath $adbPath -ServiceName '_adb-tls-connect._tcp'
    if ($mdnsConnect) {
      $connected = Try-AdbConnect -AdbPath $adbPath -Endpoint $mdnsConnect -Label 'Wireless debugging connect'
    }
  }
}

if (-not $connected) {
  Write-Host ''
  Write-Host 'Existing ADB is closed. The wizard will repair it by pairing again.'
  Write-Host 'On the phone, toggling Wireless debugging off and on can make the pairing/connect ports appear.'
}

if (-not $connected -and -not $SkipAp) {
  Write-Section 'Start Laptop Wi-Fi Direct Network'
  $apScript = Join-Path $PSScriptRoot 'start-wifi-direct-ap.ps1'
  Start-Process -FilePath powershell.exe -ArgumentList @(
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', "`"$apScript`"",
    '-Ssid', "`"$Ssid`"",
    '-Password', "`"$Password`""
  )

  Write-Host "A new PowerShell window should open and keep the Wi-Fi network alive."
  Write-Host "Phone Wi-Fi network name: $Ssid"
  Write-Host "Phone Wi-Fi password: $Password"
  Write-Host 'Do not close that new PowerShell window while using ADB.'
}

if (-not $connected) {
  Write-Section 'Phone Step'
  Write-Host "On the phone, connect Wi-Fi to '$Ssid'."
  Write-Host 'If Android says the network has no internet, choose Stay connected or Use this network anyway.'
  Write-Host 'Then open Developer options -> Wireless debugging and turn Wireless debugging on.'
  Write-Host 'If Wireless debugging was already on but no port appears, turn it off and on once.'
  Read-Host 'Press Enter here after the phone is connected to the laptop-created Wi-Fi'
}

if (-not $connected -and -not $SkipIcs) {
  Write-Section 'Optional Internet Sharing'
  Write-Host "Default internet adapter: $PublicAdapter"
  Write-Host "Default laptop-created AP adapter: $PrivateAdapter"
  if (Read-YesNo 'Enable Windows Internet Connection Sharing now? This may show a UAC prompt.') {
    & (Join-Path $PSScriptRoot 'enable-ics-to-adbbridge.ps1') -PublicAdapter $PublicAdapter -PrivateAdapter $PrivateAdapter
  }
}

if (-not $connected) {
  Write-Section 'Pair Wireless Debugging'
  Write-Host 'On the phone, tap: Wireless debugging -> Pair device with pairing code.'
  Write-Host 'Keep the pairing popup open. The six-digit code and the pairing IP:port are temporary.'
  Read-Host 'Press Enter after the pairing popup is visible'

  $pairEndpoint = Wait-MdnsEndpoint -AdbPath $adbPath -ServiceName '_adb-tls-pairing._tcp' -Label 'pairing'
  if (-not $pairEndpoint) {
    Write-Host 'Could not auto-detect the pairing endpoint.'
    $pairEndpoint = Read-Host 'Type the PAIRING_IP:PAIR_PORT from the pairing popup'
  }

  $pairCode = Read-Host 'Type the six-digit pairing code from the pairing popup'
  & $adbPath pair $pairEndpoint $pairCode | Out-Host

  Write-Section 'Connect ADB'
  Write-Host 'Close the pairing popup and return to the main Wireless debugging screen.'
  Write-Host 'The real connect value is the main screen "IP address and port", not the pairing popup port.'
  Read-Host 'Press Enter after the main Wireless debugging screen is visible'

  $connectEndpoint = Wait-MdnsEndpoint -AdbPath $adbPath -ServiceName '_adb-tls-connect._tcp' -Label 'connect'
  if (-not $connectEndpoint) {
    Write-Host 'Could not auto-detect the connect endpoint.'
    $connectEndpoint = Read-Host 'Type the CONNECT_IP:CONNECT_PORT from the main Wireless debugging screen'
  }

  & $adbPath connect $connectEndpoint | Out-Host
  & $adbPath devices -l | Out-Host
  $readySerial = Get-ReadyAdbSerial -AdbPath $adbPath
  if ($readySerial) {
    $connected = $true
    Save-Endpoint -Endpoint $connectEndpoint
  }

  if (-not $SkipTcp5555) {
    Write-Section 'Make Reconnect Easier'
    if (Read-YesNo 'Switch this ADB connection to stable classic TCP ADB mode?') {
      & $adbPath -s $connectEndpoint tcpip $StableTcpPort | Out-Host
      Start-Sleep -Seconds 3

      $default5555 = Get-DefaultGatewayEndpoint -AdapterName $PublicAdapter -Port $StableTcpPort
      if ($default5555) {
        $tcpTarget = Read-Host "Type phone IP/gateway for stable TCP ADB, or press Enter to try $default5555"
        if ([string]::IsNullOrWhiteSpace($tcpTarget)) {
          $tcpTarget = $default5555
        }
      } else {
        $tcpTarget = Read-Host 'Type phone IP/gateway for stable TCP ADB'
      }

      if ($tcpTarget -and $tcpTarget -notmatch ':\d+$') {
        $tcpTarget = "${tcpTarget}:$StableTcpPort"
      }

      if ($tcpTarget) {
        & $adbPath connect $tcpTarget | Out-Host
        & $adbPath devices -l | Out-Host
        Save-Endpoint -Endpoint $tcpTarget
      }
    }
  }
}

Write-Section 'Install APK'
if (-not $ApkPath) {
  $ApkPath = Read-Host 'Optional: type an APK path to install now, or press Enter to skip'
}

if ($ApkPath) {
  & (Join-Path $PSScriptRoot 'install-apk.ps1') -ApkPath $ApkPath -Adb $adbPath
} else {
  Write-Host 'Skipped APK install.'
}

Write-Section 'Done'
Write-Host 'If adb devices shows "device", use that serial for adb install, adb shell, and logcat.'
Write-Host 'If it shows "offline", forget the paired device on the phone and run the wizard again.'
