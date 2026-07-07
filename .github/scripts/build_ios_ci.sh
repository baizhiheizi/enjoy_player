#!/usr/bin/env bash
# Compile-only iOS smoke build for CI without code signing.
#
# Builds for iphoneos (generic iOS device), not the simulator:
# - ffmpeg_kit_flutter_new lacks arm64 for Apple Silicon iOS 26+ simulators.
# - Simulator destinations require a current CoreSimulator framework from
#   xcodebuild -runFirstLaunch (see ensure_ios_ci_toolchain.sh).
#
# Requires the iOS platform matching the active Xcode SDK (install via
# ensure_ios_ci_toolchain.sh or Xcode > Settings > Components).
set -euo pipefail

configuration="${1:?Usage: $0 Debug|Release}"

case "${configuration}" in
  Debug)
    flutter build ios --debug --config-only --no-codesign
    ;;
  Release)
    flutter build ios --release --config-only --no-codesign
    ;;
  *)
    echo "Unsupported configuration: ${configuration}" >&2
    exit 1
    ;;
esac

xcodebuild_with_retry() {
  local attempt output status
  for attempt in 1 2 3; do
    if output="$(xcodebuild \
      -workspace ios/Runner.xcworkspace \
      -scheme Runner \
      -configuration "${configuration}" \
      -sdk iphoneos \
      -destination 'generic/platform=iOS' \
      -derivedDataPath build/ios/DerivedData \
      CODE_SIGNING_ALLOWED=NO \
      build 2>&1)"; then
      echo "${output}"
      return 0
    fi
    status=$?
    echo "${output}" >&2
    if [[ "${attempt}" -lt 3 ]] \
      && echo "${output}" | grep -qE 'Could not resolve package dependencies|Couldn.t fetch updates from remote repositories'; then
      echo "xcodebuild SPM resolve failed (attempt ${attempt}/3); retrying in 15s…" >&2
      sleep 15
      continue
    fi
    return "${status}"
  done
}

xcodebuild_with_retry
