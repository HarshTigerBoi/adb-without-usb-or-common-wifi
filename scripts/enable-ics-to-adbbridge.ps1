param(
  [string]$PublicAdapter = 'Wi-Fi',
  [string]$PrivateAdapter = 'Local Area Connection* 2'
)

$ErrorActionPreference = 'Stop'

function Test-IsAdmin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
  Write-Host 'Relaunching with administrator rights. Approve the Windows UAC prompt if it appears.'
  Start-Process -FilePath powershell.exe -ArgumentList @(
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', "`"$PSCommandPath`"",
    '-PublicAdapter', "`"$PublicAdapter`"",
    '-PrivateAdapter', "`"$PrivateAdapter`""
  ) -Verb RunAs -Wait
  exit $LASTEXITCODE
}

$share = New-Object -ComObject HNetCfg.HNetShare
$connections = @($share.EnumEveryConnection())

function Get-ShareConnectionByName {
  param([string]$Name)
  foreach ($connection in $connections) {
    $props = $share.NetConnectionProps($connection)
    if ($props.Name -eq $Name) {
      return $connection
    }
  }
  return $null
}

$publicConnection = Get-ShareConnectionByName -Name $PublicAdapter
$privateConnection = Get-ShareConnectionByName -Name $PrivateAdapter

if (-not $publicConnection) {
  throw "Could not find public adapter '$PublicAdapter'."
}
if (-not $privateConnection) {
  throw "Could not find private adapter '$PrivateAdapter'."
}

foreach ($connection in $connections) {
  $config = $share.INetSharingConfigurationForINetConnection($connection)
  if ($config.SharingEnabled) {
    $props = $share.NetConnectionProps($connection)
    Write-Host "Disabling existing Internet Connection Sharing on $($props.Name)"
    $config.DisableSharing()
  }
}

Write-Host "Sharing internet from '$PublicAdapter' to '$PrivateAdapter'."
$publicConfig = $share.INetSharingConfigurationForINetConnection($publicConnection)
$privateConfig = $share.INetSharingConfigurationForINetConnection($privateConnection)

# 0 = public internet adapter, 1 = private/home adapter.
$publicConfig.EnableSharing(0)
$privateConfig.EnableSharing(1)

Start-Sleep -Seconds 3

Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Where-Object { $_.InterfaceAlias -in $PublicAdapter,$PrivateAdapter -or $_.IPAddress -like '192.168.137.*' } |
  Sort-Object InterfaceAlias,IPAddress |
  Format-Table -AutoSize InterfaceAlias,IPAddress,PrefixLength
