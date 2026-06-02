#!/usr/bin/env pwsh
# Local release entry point (Windows-friendly). Same logic as GitHub release workflows.
#
# Examples:
#   pwsh ./release.ps1                          # Windows build + installer
#   pwsh ./release.ps1 -Publish                 # build + upload to dl.enjoy.bot
#   pwsh ./release.ps1 -FeedsOnly               # build + local feeds (no S3)
#   pwsh ./release.ps1 -SkipChecks              # faster iteration
#   pwsh ./release.ps1 -PublishOnly -Publish    # re-upload existing artifacts
#
param(
  [ValidateSet('windows', 'android', 'apple')]
  [string]$Platform = 'windows',

  [switch]$Publish,
  [switch]$FeedsOnly,
  [switch]$SkipChecks,
  [switch]$PublishOnly,
  [switch]$NoInstaller,
  [switch]$Help
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot

if ($Help) {
  Get-Content (Join-Path $RepoRoot '.github/scripts/release.sh') -TotalCount 20
  Write-Host ''
  Write-Host 'Run: bash .github/scripts/release.sh --help'
  exit 0
}

$envFile = Join-Path $RepoRoot '.github/scripts/publish_env.local.ps1'
if (Test-Path $envFile) {
  Write-Host "Loading $envFile"
  . $envFile
}

$bashArgs = @(
  (Join-Path $RepoRoot '.github/scripts/release.sh'),
  '--platform', $Platform
)

if ($SkipChecks) { $bashArgs += '--skip-checks' }
if ($PublishOnly) { $bashArgs += '--publish-only' }
if ($Publish) { $bashArgs += '--publish' }
if ($FeedsOnly) { $bashArgs += '--feeds-only' }
if ($NoInstaller) { $bashArgs += '--no-installer' }

Write-Host ">>> release.ps1 -Platform $Platform $($bashArgs -join ' ')"

& bash @bashArgs
exit $LASTEXITCODE
