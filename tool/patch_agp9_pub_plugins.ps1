# Patches pub-cache Android Gradle files for AGP 9 built-in Kotlin compatibility.
# Run after `flutter pub get` when debug/release Android builds warn or fail on older plugins.
$ErrorActionPreference = "Stop"

$pubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { Join-Path $env:LOCALAPPDATA "Pub\Cache\hosted\pub.dev" }
if (-not (Test-Path $pubCache)) {
    Write-Error "Pub cache not found at $pubCache"
}

function Patch-BuiltInKotlinGroovy {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    $text = Get-Content $Path -Raw
    if ($text -notmatch "kotlin-android|org\.jetbrains\.kotlin\.android") { return }

    $updated = $text
    $updated = $updated -replace "(?m)^\s*apply plugin:\s*['\`"]kotlin-android['\`"]\s*\r?\n", ""
    $updated = $updated -replace "(?m)^\s*classpath\s+['\`"]org\.jetbrains\.kotlin:kotlin-gradle-plugin[^\r\n]*\r?\n", ""
    $updated = $updated -replace "(?m)^\s*classpath\(['\`"]org\.jetbrains\.kotlin:kotlin-gradle-plugin[^\r\n]*\r?\n", ""
    $updated = $updated -replace "(?ms)\r?\n\s*kotlinOptions\s*\{[^}]*\}\s*", "`n"
    $updated = $updated -replace "(?m)^\s*implementation\s+['\`"]org\.jetbrains\.kotlin:kotlin-stdlib[^\r\n]*\r?\n", ""
    $updated = $updated -replace "(?ms)\r?\n\s*ext\.kotlin_version\s*=\s*[^\r\n]*\r?\n", "`n"

    if ($updated -ne $text) {
        Set-Content -Path $Path -Value $updated -NoNewline
        Write-Host "Patched built-in Kotlin: $Path"
    }
}

function Patch-BuiltInKotlinKts {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    $text = Get-Content $Path -Raw
    if ($text -notmatch "kotlin-android|org\.jetbrains\.kotlin\.android") { return }

    $updated = $text
    $updated = $updated -replace "(?m)^\s*id\(['\`"]kotlin-android['\`"]\)\s*\r?\n", ""
    $updated = $updated -replace "(?m)^\s*classpath\(['\`"]org\.jetbrains\.kotlin:kotlin-gradle-plugin[^\r\n]*\r?\n", ""

    if ($updated -ne $text) {
        Set-Content -Path $Path -Value $updated -NoNewline
        Write-Host "Patched built-in Kotlin: $Path"
    }
}

$inappWebViewGradle = Join-Path $pubCache "flutter_inappwebview_android-1.1.3\android\build.gradle"
if (Test-Path $inappWebViewGradle) {
    $text = Get-Content $inappWebViewGradle -Raw
    $updated = $text -replace "proguard-android\.txt", "proguard-android-optimize.txt"
    if ($updated -ne $text) {
        Set-Content -Path $inappWebViewGradle -Value $updated -NoNewline
        Write-Host "Patched $inappWebViewGradle (proguard-android-optimize.txt)"
    }
}

@(
    (Join-Path $pubCache "package_info_plus-10.1.0\android\build.gradle"),
    (Join-Path $pubCache "wakelock_plus-1.6.1\android\build.gradle")
) | ForEach-Object { Patch-BuiltInKotlinGroovy $_ }

Patch-BuiltInKotlinKts (Join-Path $pubCache "url_launcher_android-6.3.30\android\build.gradle.kts")

# share_plus 13.2+ skips applying KGP when AGP >= 9, assuming built-in Kotlin.
# This app keeps android.builtInKotlin=false, so Kotlin sources never compile and
# GeneratedPluginRegistrant fails with "cannot find symbol SharePlusPlugin".
$sharePlusPatched = $false
Get-ChildItem -Path $pubCache -Directory -Filter "share_plus-*" | ForEach-Object {
    $gradleKts = Join-Path $_.FullName "android\build.gradle.kts"
    if (-not (Test-Path $gradleKts)) { return }
    $text = Get-Content $gradleKts -Raw
    if ($text -notmatch "agpMajor\s*<\s*9") { return }
    $updated = [regex]::Replace(
        $text,
        "(?ms)if\s*\(\s*agpMajor\s*<\s*9\s*\)\s*\{\s*apply\(plugin\s*=\s*[`"']org\.jetbrains\.kotlin\.android[`"']\)\s*\}",
        'apply(plugin = "org.jetbrains.kotlin.android")'
    )
    if ($updated -ne $text) {
        Set-Content -Path $gradleKts -Value $updated -NoNewline
        Write-Host "Patched share_plus AGP9/KGP: $gradleKts"
        $sharePlusPatched = $true
    }
}

# Invalidate stale share_plus outputs from builds that ran before the KGP patch
# (Gradle can mark compileReleaseKotlin UP-TO-DATE with empty class output).
if ($sharePlusPatched) {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    $sharePlusBuild = Join-Path $repoRoot "build\share_plus"
    if (Test-Path $sharePlusBuild) {
        Remove-Item -Recurse -Force $sharePlusBuild
        Write-Host "Cleared stale $sharePlusBuild"
    }
}

# file_picker 12's Kotlin source layout changed during the AGP 9 migration.
# Gradle's incremental cache can retain a source snapshot that compiles
# FilePickerDelegate.kt without FileUtils.kt after an upgrade.
if (-not $repoRoot) {
    $repoRoot = Split-Path $PSScriptRoot -Parent
}
$filePickerBuild = Join-Path $repoRoot "build\file_picker"
if (Test-Path $filePickerBuild) {
    Remove-Item -Recurse -Force $filePickerBuild
    Write-Host "Cleared stale $filePickerBuild"
}

Write-Host "AGP 9 pub plugin patches applied."
