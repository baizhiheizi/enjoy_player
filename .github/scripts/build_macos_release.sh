#!/usr/bin/env bash
# Compile macOS release for direct download (unsigned; signed in a post-step).
#
# flutter build macos does not forward xcodebuild settings after "--", so we
# generate Xcode project files with config-only, then compile with
# CODE_SIGNING_ALLOWED=NO (same approach as build_macos_ci.sh).
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${root}"

dart_defines=(--dart-define=DISTRIBUTION_CHANNEL=direct)
if [[ -n "${MACOS_RELEASE_DART_DEFINES:-}" ]]; then
  # shellcheck disable=SC2206
  dart_defines+=(${MACOS_RELEASE_DART_DEFINES})
fi

echo ">>> Configure macOS release"
flutter build macos --release --config-only "${dart_defines[@]}"

echo ">>> xcodebuild Release (compile-only signing)"
xcodebuild \
  -workspace macos/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -derivedDataPath build/macos \
  CODE_SIGNING_ALLOWED=NO \
  build

app_path="build/macos/Build/Products/Release/Enjoy Player.app"
if [[ ! -d "${app_path}" ]]; then
  echo "Missing release app bundle: ${app_path}" >&2
  exit 1
fi

echo "Built: ${app_path}"
