$ErrorActionPreference = 'Stop'

$ssid = $env:ADB_BRIDGE_SSID
if (-not $ssid) {
  $ssid = 'ADBBridge'
}

$password = $env:ADB_BRIDGE_PASSWORD
if (-not $password) {
  $password = 'ChangeMe123!'
}

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Devices.WiFiDirect.WiFiDirectAdvertisementPublisher, Windows.Devices.WiFiDirect, ContentType = WindowsRuntime]
$null = [Windows.Security.Credentials.PasswordCredential, Windows.Security.Credentials, ContentType = WindowsRuntime]

$publisher = [Windows.Devices.WiFiDirect.WiFiDirectAdvertisementPublisher]::new()
$publisher.Advertisement.IsAutonomousGroupOwnerEnabled = $true
$publisher.Advertisement.LegacySettings.IsEnabled = $true
$publisher.Advertisement.LegacySettings.Ssid = $ssid

$credential = [Windows.Security.Credentials.PasswordCredential]::new()
$credential.Password = $password
$publisher.Advertisement.LegacySettings.Passphrase = $credential

Write-Host 'Starting Wi-Fi Direct Legacy AP...'
Write-Host "SSID: $ssid"
Write-Host "Password: $password"
$publisher.Start()
Start-Sleep -Seconds 3
Write-Host "Publisher status: $($publisher.Status)"
Write-Host ''
Write-Host 'Connect the phone to this Wi-Fi network, then open Developer options -> Wireless debugging.'
Write-Host 'Keep this PowerShell process running while using ADB.'

while ($true) {
  Write-Host "---- $(Get-Date -Format HH:mm:ss) ----"
  Get-NetAdapter -InterfaceDescription '*Wi-Fi Direct*' -ErrorAction SilentlyContinue |
    Select-Object Name,InterfaceDescription,Status,MacAddress,LinkSpeed |
    Format-Table -AutoSize

  Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.InterfaceAlias -like '*Local Area Connection*' -or $_.InterfaceAlias -like '*Wi-Fi Direct*' -or $_.IPAddress -like '192.168.*' } |
    Select-Object InterfaceAlias,IPAddress,PrefixLength |
    Format-Table -AutoSize

  Start-Sleep -Seconds 10
}

