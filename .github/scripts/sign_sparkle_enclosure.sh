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
  elif [[ -n "${SPARKLE_DSA_PRIV_PEM:-}" ]]; then
    priv_key_path="${RUNNER_TEMP:-/tmp}/sparkle_dsa_priv.pem"
    printf '%s' "${SPARKLE_DSA_PRIV_PEM}" >"${priv_key_path}"
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
  if [[ -f "windows/dsa_pub.pem" ]] && command -v openssl >/dev/null 2>&1; then
    derived="$(openssl dsa -in "${priv_key_path}" -pubout 2>/dev/null \
      | openssl pkey -pubin -pubout 2>/dev/null)"
    committed="$(openssl pkey -pubin -in windows/dsa_pub.pem -pubout 2>/dev/null)"
    if [[ -z "${derived}" || -z "${committed}" ]]; then
      echo "::warning::Could not compare the Sparkle DSA private key with windows/dsa_pub.pem (openssl read failed)" >&2
    elif [[ "${derived}" != "${committed}" ]]; then
      echo "::error::The Sparkle DSA private key does not pair with the committed windows/dsa_pub.pem; WinSparkle clients would reject every update it signs" >&2
      exit 1
    else
      echo "Sparkle DSA private key pairs with windows/dsa_pub.pem"
    fi
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
