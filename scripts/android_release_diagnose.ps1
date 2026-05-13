#Requires -Version 5.1
<#
.SYNOPSIS
  Diagnose Enjoy Player Android release blank screen (repro + logcat).

.DESCRIPTION
  1) Optionally runs `flutter run --release` on a connected Android device/emulator.
  2) Clears logcat, launches the app (if installed), and captures filtered logs for N seconds.

  Requires Flutter on PATH. Uses adb from PATH or Android SDK default:
  %LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe

.PARAMETER RunRelease
  Run `flutter run --release` on the first Android target (blocks until you quit the app).

.PARAMETER LogcatSeconds
  Duration to capture logcat after cold-start (default 25).

.PARAMETER Serial
  adb -s <serial> when multiple devices are connected.

.EXAMPLE
  .\scripts\android_release_diagnose.ps1

.EXAMPLE
  .\scripts\android_release_diagnose.ps1 -RunRelease

.EXAMPLE
  .\scripts\android_release_diagnose.ps1 -Serial emulator-5554
#>
param(
  [switch]$RunRelease,
  [int]$LogcatSeconds = 25,
  [string]$Serial = ""
)

$ErrorActionPreference = "Stop"
$pkg = "ai.enjoy.player"
$projRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $projRoot "pubspec.yaml"))) {
  $projRoot = (Get-Location).Path
}

function Resolve-Adb {
  $fromPath = $null
  try {
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) { $fromPath = $cmd.Source }
  } catch { }
  # Do not use Test-Path on arbitrary strings: Test-Path "C" is true (drive root).
  $isAdbExe = {
    param([string]$p)
    if (-not $p) { return $false }
    if ((Split-Path -Leaf $p) -ne "adb.exe") { return $false }
    return (Test-Path -LiteralPath $p)
  }
  foreach ($p in @(
      $fromPath
      "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
      "$env:ANDROID_HOME\platform-tools\adb.exe"
      "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe"
    )) {
    if (& $isAdbExe $p) { return $p }
  }
  throw "adb not found. Install Android platform-tools or add adb to PATH."
}

function Invoke-Adb {
  param([Parameter(Mandatory)][string[]]$Arguments)
  $adb = Resolve-Adb
  if ($Serial) {
    & $adb @("-s", $Serial) @Arguments
  } else {
    & $adb @Arguments
  }
}

Write-Host "Project: $projRoot"
Write-Host "Package: $pkg"
Write-Host "adb:     $(Resolve-Adb)"
Write-Host ""

Push-Location $projRoot
try {
  flutter devices
} finally {
  Pop-Location
}

$androidIds = @()
try {
  $out = flutter devices --machine | ConvertFrom-Json
  foreach ($d in $out) {
    if ($d.targetPlatform -match "^android-") {
      $androidIds += $d.id
    }
  }
} catch {
  Write-Warning "Could not parse `flutter devices --machine`: $_"
}

if ($RunRelease) {
  if ($androidIds.Count -eq 0) {
    throw "No Android device/emulator found. Start an emulator or connect USB debugging, then retry."
  }
  $d = if ($Serial) { $Serial } else { $androidIds[0] }
  Write-Host "`n>>> flutter run --release -d $d (Ctrl+C to stop)`n"
  Push-Location $projRoot
  try {
    flutter run --release -d $d
  } finally {
    Pop-Location
  }
  exit 0
}

if ($androidIds.Count -eq 0) {
  Write-Warning "No Android device online — skipping logcat cold-start. Connect a device and re-run this script."
  exit 0
}

Write-Host "`n--- Logcat interpretation (Enjoy Player) ---"
Write-Host "  Tip: Install a release APK first (e.g. flutter install, or adb install build/app/outputs/flutter-apk/app-<abi>-release.apk)."
Write-Host "  prefs: build start / prefs: build done  -> from AppPreferencesCtrl (Drift settings)."
Write-Host "  auth: loadInitialAuthState start/done   -> from AuthCtrl cold path."
Write-Host "  FATAL EXCEPTION / AndroidRuntime        -> native/Java crash (check stack for libmpv, ffmpeg, sqlite3, Speech SDK)."
Write-Host "  FlutterError / _flutter                 -> Dart widget/init failure."
Write-Host "  Stuck after prefs start without build done -> likely Drift/SQLite or a provider deadlock before UI."
Write-Host ""

Invoke-Adb @("shell", "cmd", "package", "resolve-activity", "--brief", $pkg) 2>$null | Out-Host

Write-Host "`n>>> Clearing logcat; force-stop + start $pkg; capturing ~$LogcatSeconds s ...`n"
Invoke-Adb @("logcat", "-c") | Out-Null
Invoke-Adb @("shell", "am", "force-stop", $pkg) 2>$null | Out-Null
Start-Sleep -Milliseconds 400
Invoke-Adb @("shell", "monkey", "-p", $pkg, "-c", "android.intent.category.LAUNCHER", "1") 2>$null | Out-Null

$tmp = Join-Path $env:TEMP ("enjoy_logcat_{0}.txt" -f (Get-Random))
$adbExe = Resolve-Adb
$adbArgs = if ($Serial) {
  @("-s", $Serial, "logcat", "-v", "time")
} else {
  @("logcat", "-v", "time")
}
$p = Start-Process -FilePath $adbExe -ArgumentList $adbArgs `
  -RedirectStandardOutput $tmp -PassThru -WindowStyle Hidden
Start-Sleep -Seconds $LogcatSeconds
Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 300

$patterns = "flutter|Flutter|DartVM|prefs:|auth:|AndroidRuntime|FATAL|tombstone|Enjoy|ai.enjoy.player|libc|DEBUG"
Get-Content -Path $tmp -ErrorAction SilentlyContinue | ForEach-Object {
  if ($_ -match $patterns) { $_ }
}

Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue

Write-Host "`nDone. For a full unfiltered trace, run:"
$hint = if ($Serial) { "-s $Serial " } else { "" }
Write-Host "  $(Resolve-Adb) ${hint}logcat -v time > enjoy_logcat.txt"
Write-Host "Then reproduce the blank screen and search the file for FATAL, prefs:, auth:, Flutter."
