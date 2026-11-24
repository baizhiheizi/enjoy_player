#!/usr/bin/env bash
# Import Apple distribution certs from GitHub secrets into a temporary keychain.
#
# Skip when the self-hosted runner already has valid certs (recommended for your Mac):
#   APPLE_USE_RUNNER_KEYCHAIN=true
#
# Required secrets when importing:
#   KEYCHAIN_PASSWORD
#   IOS_DISTRIBUTION_CERT_BASE64 + IOS_DISTRIBUTION_CERT_PASSWORD
#   MACOS_DEVELOPER_ID_CERT_BASE64 + MACOS_DEVELOPER_ID_CERT_PASSWORD
set -euo pipefail

# A locked keychain still lists its certificates, so `security find-identity`
# succeeds while codesign cannot reach the private key. The symptom is an
# opaque "errSecInternalComponent" from codesign with no mention of the
# keychain, so the lock is detected here and reported as what it is.
assert_login_keychain_unlocked() {
  local keychain="${HOME}/Library/Keychains/login.keychain-db"
  [ -e "${keychain}" ] || return 0
  local output
  if output="$(security show-keychain-info "${keychain}" 2>&1)"; then
    return 0
  fi
  case "${output}" in
    *"User interaction is not allowed"*)
      echo "::error::The login keychain is locked, so codesign cannot reach the signing key (errSecInternalComponent). Unlock it on the runner Mac (security unlock-keychain) and re-run." >&2
      return 1
      ;;
  esac
  return 0
}

if [ "${APPLE_USE_RUNNER_KEYCHAIN:-true}" = "true" ]; then
  echo "Using existing login keychain on self-hosted runner."
  lib="$(dirname "$0")/release_lib.sh"
  # shellcheck source=release_lib.sh
  source "${lib}"
  release_unlock_login_keychain
  assert_login_keychain_unlocked
  security find-identity -v -p codesigning | head -10 || true
  exit 0
fi

for var in KEYCHAIN_PASSWORD IOS_DISTRIBUTION_CERT_BASE64 IOS_DISTRIBUTION_CERT_PASSWORD \
  MACOS_DEVELOPER_ID_CERT_BASE64 MACOS_DEVELOPER_ID_CERT_PASSWORD; do
  if [ -z "${!var:-}" ]; then
    echo "Missing ${var}. Set APPLE_USE_RUNNER_KEYCHAIN=true or provide cert secrets." >&2
    exit 1
  fi
done

KEYCHAIN_PATH="${RUNNER_TEMP:-/tmp}/enjoy-release.keychain-db"
KEYCHAIN_PASSWORD="${KEYCHAIN_PASSWORD}"

security create-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"
security set-keychain-settings -lut 21600 "${KEYCHAIN_PATH}"
security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"

import_p12() {
  local name="$1"
  local b64="$2"
  local password="$3"
  local p12_path="${RUNNER_TEMP:-/tmp}/${name}.p12"

  echo "${b64}" | base64 --decode >"${p12_path}"
  security import "${p12_path}" -k "${KEYCHAIN_PATH}" -P "${password}" \
    -T /usr/bin/codesign -T /usr/bin/security -T /usr/bin/xcrun
  rm -f "${p12_path}"
}

import_p12 "ios_distribution" "${IOS_DISTRIBUTION_CERT_BASE64}" "${IOS_DISTRIBUTION_CERT_PASSWORD}"
import_p12 "macos_developer_id" "${MACOS_DEVELOPER_ID_CERT_BASE64}" "${MACOS_DEVELOPER_ID_CERT_PASSWORD}"

security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"
security list-keychains -d user -s "${KEYCHAIN_PATH}" login.keychain-db
security default-keychain -s "${KEYCHAIN_PATH}"

echo "Imported signing certificates:"
security find-identity -v -p codesigning "${KEYCHAIN_PATH}"
