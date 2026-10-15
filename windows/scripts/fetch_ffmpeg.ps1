# Downloads Gyan.dev FFmpeg release-essentials and places ffmpeg.exe under windows/ffmpeg/.
# Idempotent: skips when the destination binary already runs. See windows/ffmpeg/README.md.
param(
  [switch]$Force,
  [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Dest = if ($OutputPath) { $OutputPath } else { Join-Path $RepoRoot "windows\ffmpeg\ffmpeg.exe" }
$DestDir = Split-Path $Dest -Parent

$ZipUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
$ShaUrl = "$ZipUrl.sha256"

function Test-FfmpegExecutable {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return $false }
  try {
    $null = & $Path -version 2>&1
    return $LASTEXITCODE -eq 0
  } catch {
    return $false
  }
}

function Invoke-DownloadWithRetry {
  param([string]$Uri, [string]$OutFile, [int]$Attempts = 5)
  for ($i = 1; $i -le $Attempts; $i++) {
    try {
      Invoke-WebRequest -Uri $Uri -UseBasicParsing -OutFile $OutFile
      return
    } catch {
      if ($i -eq $Attempts) { throw }
      Write-Host "Download of $Uri failed (attempt $i/$Attempts): $($_.Exception.Message); retrying..."
      Start-Sleep -Seconds (3 * $i)
    }
  }
}

if (-not $Force -and (Test-FfmpegExecutable $Dest)) {
  Write-Host "Windows FFmpeg already present: $Dest"
  exit 0
}

Write-Host "Fetching FFmpeg release-essentials from Gyan.dev..."
Write-Host "Confirm FFmpeg licensing before redistributing ffmpeg.exe to end users (see windows/ffmpeg/README.md)."

$TempRoot = Join-Path $env:TEMP ("enjoy-ffmpeg-" + [Guid]::NewGuid().ToString("N"))
$ZipPath = Join-Path $TempRoot "ffmpeg-release-essentials.zip"
$ExtractDir = Join-Path $TempRoot "extract"

try {
  New-Item -ItemType Directory -Force -Path $TempRoot, $DestDir | Out-Null

  Invoke-DownloadWithRetry -Uri $ShaUrl -OutFile (Join-Path $TempRoot "expected.sha256")
  $ExpectedHash = ((Get-Content (Join-Path $TempRoot "expected.sha256") -Raw).Trim() -split '\s+')[0].ToLowerInvariant()

  Invoke-DownloadWithRetry -Uri $ZipUrl -OutFile $ZipPath

  $ActualHash = (Get-FileHash -Path $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($ActualHash -ne $ExpectedHash) {
    throw "SHA-256 mismatch for $ZipUrl`n  expected: $ExpectedHash`n  actual:   $ActualHash"
  }
  Write-Host "SHA-256 verified."

  Expand-Archive -Path $ZipPath -DestinationPath $ExtractDir -Force

  $FfmpegBin = Get-ChildItem -Path $ExtractDir -Recurse -Filter "ffmpeg.exe" |
    Where-Object { $_.Directory.Name -eq "bin" } |
    Select-Object -First 1

  if (-not $FfmpegBin) {
    throw "Could not find bin/ffmpeg.exe inside the downloaded archive."
  }

  Copy-Item -Path $FfmpegBin.FullName -Destination $Dest -Force

  if (-not (Test-FfmpegExecutable $Dest)) {
    throw "Downloaded ffmpeg.exe failed -version check at $Dest"
  }

  $VersionLine = (& $Dest -version 2>&1 | Select-Object -First 1)
  Write-Host "Installed: $Dest"
  Write-Host $VersionLine
} finally {
  if (Test-Path $TempRoot) {
    Remove-Item -Path $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}
