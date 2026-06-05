# Copy to publish_env.local.ps1 (gitignored) and fill in values.
# Used by release.ps1 and CI publish steps.
#
# Usage (PowerShell, from repo root):
#   . .\.github\scripts\publish_env.local.ps1
#   pwsh ./release.ps1 -Publish

$env:AWS_ACCESS_KEY_ID = "<R2 access key id>"
$env:AWS_SECRET_ACCESS_KEY = "<R2 secret access key>"
$env:AWS_DEFAULT_REGION = "auto"
$env:AWS_ENDPOINT_URL_S3 = "https://<account-id>.r2.cloudflarestorage.com"
$env:PUBLISH_BUCKET = "<r2-bucket-name>"
$env:PUBLISH_PREFIX = "player"

$env:CLOUDFLARE_API_TOKEN = "<token with Cache Purge>"
$env:CLOUDFLARE_ZONE_ID = "<zone id for enjoy.bot>"
# $env:ENJOY_PLAYER_DL_BASE = "https://dl.enjoy.bot/player"
# WinSparkle signing (required for desktop auto-update appcast):
# $env:SPARKLE_DSA_PRIV_PEM = "C:\path\to\dsa_priv.pem"
