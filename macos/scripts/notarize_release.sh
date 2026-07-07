#!/bin/sh
# Notarize a release-built macOS .app for direct distribution (Developer ID).
#
# Uses ReleaseDirect.entitlements (no Sign in with Apple / keychain groups —
# those are unsupported for Developer ID and cause launch error 163 on macOS 26+).
# Prerequisites (one-time on the release machine):
#   1. Developer ID Application certificate in Keychain (team 46X685R747).
#   2. App-specific password stored for notarytool, e.g.:
#        xcrun notarytool store-credentials "enjoy-notary" \
#          --apple-id "you@example.com" \
#          --team-id "46X685R747" \
#          --password "@keychain:AC_PASSWORD"
#
# Usage:
#   ./macos/scripts/notarize_release.sh build/macos/Build/Products/Release/Enjoy\ Player.app
#   ./macos/scripts/notarize_release.sh <app> --sign-only
#   ./macos/scripts/notarize_release.sh <app> --skip-sign   # upload only (retry after sign)
#
set -eu

APP_BUNDLE="${1:-}"
SIGN_ONLY=false
SKIP_SIGN=false
shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --sign-only) SIGN_ONLY=true ;;
    --skip-sign) SKIP_SIGN=true ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

if [ -z "${APP_BUNDLE}" ] || [ ! -d "${APP_BUNDLE}" ]; then
  echo "usage: $0 <path/to/Enjoy Player.app> [--sign-only|--skip-sign]" >&2
  exit 1
fi

if [ "${SIGN_ONLY}" = true ] && [ "${SKIP_SIGN}" = true ]; then
  echo "Cannot use --sign-only and --skip-sign together." >&2
  exit 1
fi

NOTARY_PROFILE="${NOTARY_PROFILE:-enjoy-notary}"
SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
MACOS_DIR="$(dirname "${SCRIPT_DIR}")"
ENTITLEMENTS="${MACOS_ENTITLEMENTS:-${MACOS_DIR}/Runner/ReleaseDirect.entitlements}"
FRAMEWORKS_DIR="${APP_BUNDLE}/Contents/Frameworks"
ZIP_PATH="$(mktemp -t enjoy-player-notarize).zip"

resolve_developer_id_identity() {
  if [ -n "${SIGN_IDENTITY:-}" ]; then
    printf '%s' "${SIGN_IDENTITY}"
    return
  fi
  security find-identity -v -p codesigning 2>/dev/null \
    | awk -F'"' '/Developer ID Application/ { print $2; exit }'
}

app_has_developer_id_signature() {
  codesign -dvv "${1}" 2>&1 | grep -q 'Authority=Developer ID Application'
}

is_macho() {
  file "$1" 2>/dev/null | grep -q 'Mach-O'
}

sign_path() {
  target="$1"
  use_entitlements="${2:-0}"
  if [ "${use_entitlements}" -eq 1 ]; then
    codesign --force --sign "${SIGN_IDENTITY}" \
      --options runtime \
      --timestamp \
      --entitlements "${ENTITLEMENTS}" \
      "${target}" || return 1
  else
    codesign --force --sign "${SIGN_IDENTITY}" \
      --options runtime \
      --timestamp \
      "${target}" || return 1
  fi
}

codesign_failure_hint() {
  echo "codesign failed. If you see errSecInternalComponent, unlock the login keychain:" >&2
  echo "  security unlock-keychain login.keychain-db" >&2
}

is_transient_notary_error() {
  grep -qiE 'deadlineExceeded|abortedUpload|timed out|network connection|HTTPClientError' "$1" 2>/dev/null
}

cleanup() {
  rm -f "${ZIP_PATH}"
}
trap cleanup EXIT

if [ "${SKIP_SIGN}" != true ]; then
  SIGN_IDENTITY="$(resolve_developer_id_identity)"
  if [ -z "${SIGN_IDENTITY}" ]; then
    echo "No Developer ID Application identity in Keychain." >&2
    echo "Install the cert (team 46X685R747) or set SIGN_IDENTITY." >&2
    exit 1
  fi

  echo "==> Re-signing for direct distribution (${SIGN_IDENTITY})"
  if [ -d "${FRAMEWORKS_DIR}" ]; then
    while IFS= read -r fw; do
      sign_path "${fw}" || { codesign_failure_hint; exit 1; }
    done <<EOF
$(find "${FRAMEWORKS_DIR}" -maxdepth 1 -name '*.framework' -type d 2>/dev/null)
EOF

    while IFS= read -r f; do
      case "${f}" in
        *.debug.dylib) continue ;;
      esac
      if is_macho "${f}"; then
        sign_path "${f}" || { codesign_failure_hint; exit 1; }
      fi
    done <<EOF
$(find "${FRAMEWORKS_DIR}" -type f 2>/dev/null)
EOF
  fi

  EXECUTABLE="${APP_BUNDLE}/Contents/MacOS/$(basename "${APP_BUNDLE}" .app)"
  if [ -f "${EXECUTABLE}" ]; then
    sign_path "${EXECUTABLE}" 1 || { codesign_failure_hint; exit 1; }
  fi

  sign_path "${APP_BUNDLE}" 1 || { codesign_failure_hint; exit 1; }

  echo "==> Verifying signature"
  codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE}"
else
  echo "==> Skipping re-sign (--skip-sign); verifying Developer ID signature"
  if ! app_has_developer_id_signature "${APP_BUNDLE}"; then
    echo "App is not signed with Developer ID Application. Run without --skip-sign first." >&2
    exit 1
  fi
  codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE}" || {
    echo "Developer ID signature verification failed." >&2
    exit 1
  }
fi

if [ "${SIGN_ONLY}" = true ]; then
  echo "Done: ${APP_BUNDLE} is signed for direct distribution."
  exit 0
fi

echo "==> Creating notarization zip"
ditto -c -k --norsrc --keepParent "${APP_BUNDLE}" "${ZIP_PATH}"
zip_mb="$(du -m "${ZIP_PATH}" | awk '{print $1}')"
echo "    Upload size: ~${zip_mb}MB (large bundles may need several minutes on slow networks)"

submit_notary_with_retry() {
  max_attempts="${NOTARY_SUBMIT_RETRIES:-5}"
  attempt=1
  SUBMIT_OUT="$(mktemp)"

  while [ "${attempt}" -le "${max_attempts}" ]; do
    echo "==> Submitting to Apple notary service (attempt ${attempt}/${max_attempts}, profile: ${NOTARY_PROFILE})"
    if xcrun notarytool submit "${ZIP_PATH}" \
      --keychain-profile "${NOTARY_PROFILE}" \
      --wait \
      --output-format json >"${SUBMIT_OUT}" 2>&1 \
      && grep -q '"status"[[:space:]]*:[[:space:]]*"Accepted"' "${SUBMIT_OUT}"; then
      return 0
    fi

    echo "notarytool attempt ${attempt} failed:" >&2
    cat "${SUBMIT_OUT}" >&2

    if ! is_transient_notary_error "${SUBMIT_OUT}"; then
      echo "Not a transient upload error; not retrying." >&2
      rm -f "${SUBMIT_OUT}"
      return 1
    fi

    echo "Upload to Apple notary service timed out (transient network). Disable VPN/proxy if it persists." >&2
    if [ "${attempt}" -lt "${max_attempts}" ]; then
      delay=$((attempt * 30))
      echo "Retrying upload in ${delay}s..." >&2
      sleep "${delay}"
    fi
    attempt=$((attempt + 1))
  done

  rm -f "${SUBMIT_OUT}"
  return 1
}

if ! submit_notary_with_retry; then
  echo "notarytool submission failed after ${NOTARY_SUBMIT_RETRIES:-5} attempt(s)." >&2
  echo "Retry upload only (app already signed):" >&2
  echo "  ./macos/scripts/notarize_release.sh \"${APP_BUNDLE}\" --skip-sign" >&2
  exit 1
fi
rm -f "${SUBMIT_OUT}"

echo "==> Stapling notarization ticket"
if ! xcrun stapler staple "${APP_BUNDLE}"; then
  echo "stapler failed: could not attach the notarization ticket to the app bundle." >&2
  exit 1
fi

echo "==> Gatekeeper assessment"
if ! spctl --assess --type execute --verbose=4 "${APP_BUNDLE}"; then
  echo "Gatekeeper assessment failed after notarization." >&2
  exit 1
fi

echo "Done: ${APP_BUNDLE} is notarized and stapled."
