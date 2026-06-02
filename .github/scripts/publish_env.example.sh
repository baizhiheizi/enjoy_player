# Copy to publish_env.local.sh (gitignored) and fill in values.
# Usage (Git Bash / WSL, from repo root):
#   source .github/scripts/publish_env.local.sh
#   bash .github/scripts/release.sh --platform windows --publish

export S3_ACCESS_KEY_ID="<R2 access key id>"
export S3_SECRET_ACCESS_KEY="<R2 secret access key>"
export S3_BUCKET="<r2-bucket-name>"
export S3_ENDPOINT="https://<account-id>.r2.cloudflarestorage.com"

export S3_PREFIX="player"
export CLOUDFLARE_API_TOKEN="<token with Cache Purge>"
export CLOUDFLARE_ZONE_ID="<zone id for enjoy.bot>"

# WinSparkle signing (optional locally; path to dsa_priv.pem)
# export SPARKLE_DSA_PRIV_PEM="/path/to/dsa_priv.pem"
