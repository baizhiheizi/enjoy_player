#!/usr/bin/env bash
# Apple (iOS + macOS) release — same steps as release_apple.yml.
# macOS only.
#
# Usage:
#   bash .github/scripts/release_apple.sh
#   bash .github/scripts/release_apple.sh --notarize --publish
set -euo pipefail

lib="$(dirname "$0")/release_lib.sh"
# shellcheck source=release_lib.sh
source "${lib}"

root="$(release_repo_root)"
cd "${root}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "release_apple.sh requires macOS." >&2
  exit 1
fi

SKIP_CHECKS=false
SKIP_BUILD=false
NOTARIZE=false
UPLOAD_TESTFLIGHT=false
PUBLISH=false
FEEDS_ONLY=false
MACOS_APP_PATH="${MACOS_APP_PATH:-build/macos/Build/Products/Release/Enjoy Player.app}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-checks) SKIP_CHECKS=true; shift ;;
    --skip-build | --publish-only) SKIP_BUILD=true; shift ;;
    --notarize) NOTARIZE=true; shift ;;
    --testflight) UPLOAD_TESTFLIGHT=true; shift ;;
    --publish) PUBLISH=true; shift ;;
    --feeds-only) FEEDS_ONLY=true; PUBLISH=true; shift ;;
    -h | --help)
      sed -n '2,8p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ "${SKIP_CHECKS}" != true ]]; then
  echo ">>> Pre-release checks"
  release_run_checks "${root}"
fi

if [[ "${SKIP_BUILD}" != true ]]; then
  bash "${root}/.github/scripts/setup_apple_signing.sh" || true

  if [[ "${NOTARIZE}" == true ]]; then
    bash "${root}/.github/scripts/setup_notary_credentials.sh" || true
  fi

  echo ">>> Homebrew + CocoaPods"
  brew bundle install --file="${root}/macos/Brewfile"
  (cd "${root}/ios" && pod install)
  (cd "${root}/macos" && pod install)

  echo ">>> Build iOS IPA"
  flutter build ipa --release --export-options-plist=ios/ExportOptions.export.plist

  if [[ "${UPLOAD_TESTFLIGHT}" == true ]]; then
    if [[ -n "${APP_STORE_CONNECT_API_KEY_ID:-}" && -n "${APP_STORE_CONNECT_ISSUER_ID:-}" && -n "${APP_STORE_CONNECT_API_PRIVATE_KEY:-}" ]]; then
      KEY_PATH="${RUNNER_TEMP:-/tmp}/AuthKey_${APP_STORE_CONNECT_API_KEY_ID}.p8"
      printf '%s' "${APP_STORE_CONNECT_API_PRIVATE_KEY}" >"${KEY_PATH}"
      chmod 600 "${KEY_PATH}"
      IPA="$(ls -1 "${root}/build/ios/ipa/"*.ipa | head -1)"
      xcrun altool --upload-app --type ios --file "${IPA}" \
        --apiKey "${APP_STORE_CONNECT_API_KEY_ID}" \
        --apiIssuer "${APP_STORE_CONNECT_ISSUER_ID}"
      rm -f "${KEY_PATH}"
    else
      echo "Skipping TestFlight: App Store Connect API env not set."
    fi
  fi

  echo ">>> Build macOS release (direct channel)"
  flutter build macos --release --dart-define=DISTRIBUTION_CHANNEL=direct

  if [[ "${NOTARIZE}" == true ]]; then
    echo ">>> Notarize macOS app"
    chmod +x "${root}/macos/scripts/notarize_release.sh"
    "${root}/macos/scripts/notarize_release.sh" "${MACOS_APP_PATH}"
  fi

  version="$(release_version)"
  ditto -c -k --keepParent "${MACOS_APP_PATH}" "${root}/EnjoyPlayer-macOS-v${version}.zip"
  bash "${root}/.github/scripts/rename_release_artifacts.sh" apple
fi

if [[ "${PUBLISH}" == true ]]; then
  release_load_publish_env "${root}"
  version="$(release_version)"
  zip="${root}/EnjoyPlayer-macOS-v${version}.zip"
  if [[ ! -f "${zip}" ]]; then
    echo "Missing macOS zip: ${zip}" >&2
    exit 1
  fi
  publish_args=(--macos-zip "${zip}")
  if [[ "${FEEDS_ONLY}" == true ]]; then
    publish_args=(--feeds-only "${publish_args[@]}")
  else
    export RELEASE_REQUIRE_S3=1
  fi
  echo ">>> Publish macOS zip"
  bash "${root}/.github/scripts/publish_player_release_to_s3.sh" "${publish_args[@]}"
fi

release_print_artifacts "${root}" apple
echo "Done."
