param(
  [Parameter(Mandatory = $true)]
  [string]$ApkPath,

  [string]$Serial,

  [string]$Adb = '.\work\android\platform-tools\adb.exe'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $ApkPath)) {
  throw "APK not found: $ApkPath"
}

if (-not (Test-Path $Adb)) {
  $cmd = Get-Command adb -ErrorAction SilentlyContinue
  if ($cmd) {
    $Adb = $cmd.Source
  } else {
    throw "adb.exe not found. Install Android platform-tools first."
  }
}

if (-not $Serial) {
  $devices = & $Adb devices | Select-String -Pattern "`tdevice$"
  if ($devices.Count -eq 1) {
    $Serial = (($devices[0].Line -split "`t")[0]).Trim()
  } else {
    & $Adb devices -l
    throw 'Pass -Serial because zero or multiple devices are connected.'
  }
}

& $Adb -s $Serial install -r $ApkPath

