# Sync version in windows/installer/enjoy_player.iss from pubspec.yaml (semver only).
$ErrorActionPreference = "Stop"

$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -notmatch '(?m)^version:\s*([\d.]+)') {
  Write-Error "Could not parse version from pubspec.yaml"
  exit 1
}
$version = $Matches[1]

$issPath = "windows/installer/enjoy_player.iss"
$lines = Get-Content $issPath
$found = $false
$updated = foreach ($line in $lines) {
  if ($line -match '^#define MyAppVersion ') {
    $found = $true
    "#define MyAppVersion `"$version`""
  } else {
    $line
  }
}

if (-not $found) {
  Write-Error "#define MyAppVersion not found in $issPath"
  exit 1
}

Set-Content -Path $issPath -Value $updated
Write-Host "Set MyAppVersion=$version in $issPath (installer: EnjoyPlayerSetup-v$version.exe)"
