#!/usr/bin/env bash
# Sign a desktop release artifact for Sparkle / WinSparkle appcast enclosures.
#
# macOS: uses EdDSA private key in the login keychain (run `dart run auto_updater:generate_keys` once).
# Windows: uses dsa_priv.pem (repo root or SPARKLE_DSA_PRIV_PEM / SPARKLE_DSA_PRIV_PEM_BASE64).
#
# Prints the full sign_update line to stdout and, when GITHUB_ENV is set, exports:
#   SPARKLE_ED_SIGNATURE_MACOS  or  SPARKLE_ED_SIGNATURE_WINDOWS
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: sign_sparkle_enclosure.sh <artifact-path>" >&2
  exit 1
fi

artifact="$1"
if [[ ! -f "${artifact}" ]]; then
  echo "::error::Missing artifact: ${artifact}" >&2
  exit 1
fi

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${root}"

flutter pub get >/dev/null

if [[ "$(uname -s)" == "Darwin" ]]; then
  if [[ ! -x "macos/Pods/Sparkle/bin/sign_update" ]]; then
    (cd macos && pod install)
  fi
fi

priv_key_path=""
if [[ "$(uname -s)" != "Darwin" ]]; then
  if [[ -n "${SPARKLE_DSA_PRIV_PEM:-}" && -f "${SPARKLE_DSA_PRIV_PEM}" ]]; then
    priv_key_path="${SPARKLE_DSA_PRIV_PEM}"
  elif [[ -n "${SPARKLE_DSA_PRIV_PEM_BASE64:-}" ]]; then
    priv_key_path="${RUNNER_TEMP:-/tmp}/sparkle_dsa_priv.pem"
    printf '%s' "${SPARKLE_DSA_PRIV_PEM_BASE64}" | base64 -d >"${priv_key_path}"
  elif [[ -f "dsa_priv.pem" ]]; then
    priv_key_path="dsa_priv.pem"
  fi
  if [[ -z "${priv_key_path}" ]]; then
    echo "::warning::No WinSparkle private key; skipping signature for ${artifact}" >&2
    exit 0
  fi
fi

sign_args=("${artifact}")
if [[ -n "${priv_key_path}" ]]; then
  sign_args+=("${priv_key_path}")
fi

output="$(dart run auto_updater:sign_update "${sign_args[@]}")"
echo "${output}"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  if echo "${output}" | grep -q 'edSignature'; then
    sig="$(echo "${output}" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')"
    echo "SPARKLE_ED_SIGNATURE_MACOS=${sig}" >>"${GITHUB_ENV}"
  elif echo "${output}" | grep -q 'dsaSignature'; then
    sig="$(echo "${output}" | sed -n 's/.*sparkle:dsaSignature="\([^"]*\)".*/\1/p')"
    echo "SPARKLE_ED_SIGNATURE_WINDOWS=${sig}" >>"${GITHUB_ENV}"
  fi
fi
