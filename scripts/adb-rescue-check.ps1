param(
  [string]$Adb = '.\work\android\platform-tools\adb.exe'
)

$ErrorActionPreference = 'Continue'

if (-not (Test-Path $Adb)) {
  $cmd = Get-Command adb -ErrorAction SilentlyContinue
  if ($cmd) {
    $Adb = $cmd.Source
  } else {
    throw "adb.exe not found. Install Android platform-tools first."
  }
}

Write-Host "Using adb: $Adb"
& $Adb version

Write-Host ''
Write-Host 'Devices:'
& $Adb devices -l

Write-Host ''
Write-Host 'ADB mDNS services:'
& $Adb mdns services

Write-Host ''
Write-Host 'IPv4 adapters:'
Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Sort-Object InterfaceAlias,IPAddress |
  Format-Table -AutoSize InterfaceAlias,IPAddress,PrefixLength

Write-Host ''
Write-Host 'Likely local neighbors:'
Get-NetNeighbor -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Where-Object { $_.IPAddress -like '192.168.*' -or $_.IPAddress -like '10.*' -or $_.IPAddress -like '172.*' -or $_.IPAddress -like '100.*' } |
  Sort-Object IPAddress |
  Format-Table -AutoSize InterfaceAlias,IPAddress,LinkLayerAddress,State

