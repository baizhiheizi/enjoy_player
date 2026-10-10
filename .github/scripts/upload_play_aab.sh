#!/usr/bin/env bash
# Upload a signed Play AAB to Google Play (alpha track / draft by default)
# via fastlane supply (upload_to_play_store, see fastlane/Fastfile).
#
# Auth (prefer in this order):
#   GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH     — path to JSON file (local)
#   GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_BASE64   — base64 of JSON (CI; avoids multiline env corruption)
#   GOOGLE_PLAY_SERVICE_ACCOUNT_JSON          — raw JSON string (local only; fragile in GHA)
#
# Optional:
#   GOOGLE_PLAY_PACKAGE_NAME      (default: ai.enjoy.player)
#   GOOGLE_PLAY_TRACK             (default: alpha)
#   GOOGLE_PLAY_RELEASE_STATUS    (default: draft)
#
# Usage:
#   bash .github/scripts/upload_play_aab.sh path/to/EnjoyPlayer-vX.Y.Z.aab
set -euo pipefail

scripts="$(cd "$(dirname "$0")" && pwd)"

AAB="${1:-}"
if [[ -z "${AAB}" ]]; then
  echo "Usage: $0 <path-to.aab>" >&2
  exit 1
fi
if [[ ! -f "${AAB}" ]]; then
  echo "AAB not found: ${AAB}" >&2
  exit 1
fi

has_path="${GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH:-}"
has_b64="${GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_BASE64:-}"
has_json="${GOOGLE_PLAY_SERVICE_ACCOUNT_JSON:-}"
if [[ -z "${has_path}" && -z "${has_b64}" && -z "${has_json}" ]]; then
  echo "Skipping Play upload: GOOGLE_PLAY_SERVICE_ACCOUNT_JSON(_PATH|_BASE64) not set."
  exit 0
fi

# Normalize every auth form to a temp JSON file so the raw secret never
# round-trips through a multiline-mangled env var.
cleanup_sa=""
if [[ -n "${has_path}" ]]; then
  sa_file="${has_path}"
elif [[ -n "${has_b64}" ]]; then
  sa_file="$(mktemp "${RUNNER_TEMP:-/tmp}/play-sa-XXXXXX.json")"
  printf '%s' "${has_b64}" | base64 --decode >"${sa_file}"
  chmod 600 "${sa_file}"
  cleanup_sa="${sa_file}"
else
  sa_file="$(mktemp "${RUNNER_TEMP:-/tmp}/play-sa-XXXXXX.json")"
  printf '%s' "${has_json}" >"${sa_file}"
  chmod 600 "${sa_file}"
  cleanup_sa="${sa_file}"
fi
trap '[[ -n "${cleanup_sa}" ]] && rm -f "${cleanup_sa}"' EXIT

# Preserve the old Python uploader's early-fail: a malformed credential
# should die here with a clear reason, not as an opaque fastlane error.
if ! jq -e . "${sa_file}" >/dev/null 2>&1; then
  echo "Service account JSON is invalid: ${sa_file} is not parseable JSON" >&2
  exit 1
fi
if ! jq -e 'has("client_email") and has("private_key")' "${sa_file}" >/dev/null 2>&1; then
  echo "Service account JSON is invalid: missing client_email / private_key" >&2
  exit 1
fi

package="${GOOGLE_PLAY_PACKAGE_NAME:-ai.enjoy.player}"
track="${GOOGLE_PLAY_TRACK:-alpha}"
status="${GOOGLE_PLAY_RELEASE_STATUS:-draft}"

echo ">>> Verify AAB signing for Play"
bash "${scripts}/verify_android_aab_for_play.sh" "${AAB}"

echo ">>> Upload AAB to Google Play (package=${package} track=${track} status=${status})"
echo "    $(basename "${AAB}")"

(
  export GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH="${sa_file}"
  export PLAY_AAB_PATH="${AAB}"
  unset GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
  bash "${scripts}/fastlane.sh" android beta
)

echo "Play upload complete."
