# Copy to publish_env.local.ps1 (gitignored) and fill in values.
# Used by release.ps1 and CI publish steps.
#
# Usage (PowerShell, from repo root):
#   . .\.github\scripts\publish_env.local.ps1
#   pwsh ./release.ps1 -Publish
# Or publish only:
#   pwsh ./release.ps1 -PublishOnly -Publish

$env:S3_ACCESS_KEY_ID = "<R2 access key id>"
$env:S3_SECRET_ACCESS_KEY = "<R2 secret access key>"
$env:S3_BUCKET = "<r2-bucket-name>"
$env:S3_ENDPOINT = "https://<account-id>.r2.cloudflarestorage.com"

# Optional
$env:S3_PREFIX = "player"
$env:CLOUDFLARE_API_TOKEN = "<token with Cache Purge>"
$env:CLOUDFLARE_ZONE_ID = "<zone id for enjoy.bot>"
# Optional — local publish with WinSparkle signing:
# $env:SPARKLE_DSA_PRIV_PEM = "C:\path\to\dsa_priv.pem"
