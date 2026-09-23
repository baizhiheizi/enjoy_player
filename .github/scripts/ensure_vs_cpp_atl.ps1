# Ensure the C++ ATL component is present for the VS instance used by
# `flutter build windows`.
#
# flutter_secure_storage_windows compiles `#include <atlstr.h>`, which ships
# only with the "C++ ATL for latest v143 build tools" component. Without it
# the plugin build fails with error C1083 ("atlstr.h: No such file or
# directory"). ATL can silently disappear from a self-hosted runner when VS
# Build Tools updates or the host is re-provisioned (it did here between
# 2026-08-24 and 2026-08-31), so this check runs idempotently before every
# Windows build and self-heals when possible.
#
# Requires elevation to install; detection alone is fine unprivileged.
$ErrorActionPreference = "Stop"

$vsInstallerDir = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer"
$vswhere = Join-Path $vsInstallerDir "vswhere.exe"
if (-not (Test-Path $vswhere)) {
  Write-Error "vswhere not found — Visual Studio Build Tools missing? See docs/ci-self-hosted-runners.md (Windows runner checklist)."
  exit 1
}

$instance = & $vswhere -latest -products * -format json | ConvertFrom-Json | Select-Object -First 1
if (-not $instance) {
  Write-Error "No Visual Studio instance found — install Build Tools with the 'Desktop development with C++' workload (docs/ci-self-hosted-runners.md)."
  exit 1
}

$installPath = $instance.installationPath
Write-Host "VS instance: $installPath v$($instance.installationVersion)"

function Test-AtlHeader([string]$instancePath) {
  # atlstr.h lives in atlmfc/ under each MSVC toolset version; any hit means
  # the ATL component is installed.
  $toolsets = Join-Path $instancePath "VC\Tools\MSVC"
  if (-not (Test-Path $toolsets)) { return $null }
  return Get-ChildItem -Path $toolsets -Directory -ErrorAction SilentlyContinue |
    ForEach-Object { Join-Path $_.FullName "atlmfc\include\atlstr.h" } |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1
}

$atlHeader = Test-AtlHeader $installPath
if ($atlHeader) {
  Write-Host "C++ ATL already installed: $atlHeader"
  exit 0
}

Write-Host "atlstr.h missing — installing the Microsoft.VisualStudio.Component.VC.ATL component (quiet; may download a few hundred MB)..."

$elevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $elevated) {
  Write-Error "Not running elevated — cannot self-install the ATL component. Install 'C++ ATL for latest v143 build tools' manually (docs/ci-self-hosted-runners.md)."
  exit 1
}

# setup.exe is the documented automation entry point and blocks until done;
# vs_installer.exe is the legacy fallback (may return before completion, so
# the post-install check below is the real gate either way).
$installer = Join-Path $vsInstallerDir "setup.exe"
if (-not (Test-Path $installer)) {
  $installer = Join-Path $vsInstallerDir "vs_installer.exe"
}
if (-not (Test-Path $installer)) {
  Write-Error "VS installer not found under $vsInstallerDir — install 'C++ ATL for latest v143 build tools' manually (docs/ci-self-hosted-runners.md)."
  exit 1
}

$p = Start-Process -FilePath $installer -PassThru -Wait -ArgumentList @(
  "modify",
  "--installPath", "`"$installPath`"",
  "--add", "Microsoft.VisualStudio.Component.VC.ATL",
  "--quiet", "--norestart"
)
# 0 = success; 3010 = success but reboot required (not needed to use headers).
if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) {
  Write-Error "VS installer modify failed with exit code $($p.ExitCode)."
  exit 1
}

$atlHeader = Test-AtlHeader $installPath
# vs_installer.exe (legacy fallback) can return before the payload finishes
# landing; poll briefly so that path still gets a correct verdict.
$deadline = (Get-Date).AddMinutes(10)
while (-not $atlHeader -and (Get-Date) -lt $deadline) {
  Write-Host "atlstr.h not visible yet (installer exit $($p.ExitCode)); waiting 15s..."
  Start-Sleep -Seconds 15
  $atlHeader = Test-AtlHeader $installPath
}

if (-not $atlHeader) {
  Write-Error "ATL component install returned $($p.ExitCode) but atlstr.h is still missing under $installPath."
  exit 1
}

Write-Host "C++ ATL installed: $atlHeader"
