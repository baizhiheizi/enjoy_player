# Delegates to the single-source Dart patcher in tool/patch_agp9_pub_plugins.dart.
# This wrapper exists so the release scripts and docs keep one stable entry point.
$ErrorActionPreference = "Stop"

$root = Split-Path $PSScriptRoot -Parent
$script = Join-Path $root "tool\patch_agp9_pub_plugins.dart"

function Resolve-Dart {
    $onPath = Get-Command dart -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }
    $flutter = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutter) {
        $flutterBin = Split-Path $flutter.Source -Parent
        $candidate = Join-Path $flutterBin "cache\dart-sdk\bin\dart.exe"
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

$dart = Resolve-Dart
if (-not $dart) {
    Write-Error "patch_agp9_pub_plugins: no Dart SDK found (need dart on PATH or a Flutter SDK)" -ErrorAction Continue
    exit 1
}

& $dart $script @args
exit $LASTEXITCODE
