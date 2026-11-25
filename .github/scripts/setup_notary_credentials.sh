#!/usr/bin/env bash
# Register notarytool credentials for this job from App Store Connect API key secrets.
set -euo pipefail

lib="$(dirname "$0")/release_lib.sh"
# shellcheck source=release_lib.sh
source "${lib}"

PROFILE="${NOTARY_PROFILE:-enjoy-notary}"

for var in APP_STORE_CONNECT_API_KEY_ID APP_STORE_CONNECT_ISSUER_ID APP_STORE_CONNECT_API_PRIVATE_KEY; do
  if [ -z "${!var:-}" ]; then
    echo "App Store Connect API env not set; using existing notary profile (${PROFILE})." >&2
    exit 0
  fi
done

# Cache identifiers + .p8 under ~/.config/enjoy-player/ before validation so a
# failed notary login still leaves a complete local secrets layout.
release_cache_asc_credentials
KEY_PATH="$(release_asc_config_dir)/AuthKey_${APP_STORE_CONNECT_API_KEY_ID}.p8"

release_unlock_login_keychain

# Notarization no longer consumes this profile — notarize_release.sh submits
# with the cached API key directly, because macOS 26's notarytool cannot write
# a keychain profile headlessly (errSecInteractionNotAllowed even on an
# unlocked keychain). Keep the store attempt best-effort for local users whose
# other tooling reads the profile; a failure must not fail the release run.
if ! xcrun notarytool store-credentials "${PROFILE}" \
  --key "${KEY_PATH}" \
  --key-id "${APP_STORE_CONNECT_API_KEY_ID}" \
  --issuer "${APP_STORE_CONNECT_ISSUER_ID}"; then
  echo "store-credentials failed (see above); continuing — notarize_release.sh submits with the cached API key." >&2
fi

echo "Registered notary profile: ${PROFILE}"
