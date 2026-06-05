#!/usr/bin/env bash
# Register notarytool credentials for this job from App Store Connect API key secrets.
set -euo pipefail

PROFILE="${NOTARY_PROFILE:-enjoy-notary}"

for var in APP_STORE_CONNECT_API_KEY_ID APP_STORE_CONNECT_ISSUER_ID APP_STORE_CONNECT_API_PRIVATE_KEY; do
  if [ -z "${!var:-}" ]; then
    echo "App Store Connect API env not set; using existing notary profile (${PROFILE})." >&2
    exit 0
  fi
done

KEY_PATH="${RUNNER_TEMP:-/tmp}/AuthKey_${APP_STORE_CONNECT_API_KEY_ID}.p8"
printf '%s' "${APP_STORE_CONNECT_API_PRIVATE_KEY}" >"${KEY_PATH}"
chmod 600 "${KEY_PATH}"

xcrun notarytool store-credentials "${PROFILE}" \
  --key "${KEY_PATH}" \
  --key-id "${APP_STORE_CONNECT_API_KEY_ID}" \
  --issuer "${APP_STORE_CONNECT_ISSUER_ID}"

echo "Registered notary profile: ${PROFILE}"
rm -f "${KEY_PATH}"
