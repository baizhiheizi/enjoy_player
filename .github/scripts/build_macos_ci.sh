#!/usr/bin/env bash
# Compile-only macOS smoke build for CI without Apple Development signing.
#
# flutter build macos does not forward xcodebuild settings after "--"; those
# positional args are treated as Dart entrypoints. Use config-only + xcodebuild
# with CODE_SIGNING_ALLOWED=NO instead (see ADR/docs in packaging.md for why
# local dev keeps Apple Development signing on the Runner target).
set -euo pipefail

configuration="${1:?Usage: $0 Debug|Release}"

case "${configuration}" in
  Debug|Release) ;;
  *)
    echo "Unsupported configuration: ${configuration}" >&2
    exit 1
    ;;
esac

# Xcode 16 SwiftPM can crash (NSMutableArray insertObjects:atIndexes: count
# mismatch) when stale package resolution state lingers. Clear caches so each
# CI run starts from a clean slate.
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf macos/Flutter/ephemeral/Packages/.build

build_with_retry() {
  local attempt output status
  local config_flag
  config_flag="$(echo "${configuration}" | tr '[:upper:]' '[:lower:]')"

  for attempt in 1 2 3; do
    if output="$(flutter build macos --"${config_flag}" --config-only 2>&1)"; then
      echo "${output}"
    else
      status=$?
      echo "${output}" >&2
      if [[ "${attempt}" -lt 3 ]] \
        && echo "${output}" | grep -qE 'INTERNAL ERROR: Uncaught exception|Could not resolve package dependencies'; then
        echo "flutter config-only SPM crash (attempt ${attempt}/3); clearing cache and retrying in 15s…" >&2
        rm -rf ~/Library/Caches/org.swift.swiftpm
        rm -rf macos/Flutter/ephemeral/Packages/.build
        sleep 15
        continue
      fi
      return "${status}"
    fi

    if output="$(xcodebuild \
      -workspace macos/Runner.xcworkspace \
      -scheme Runner \
      -configuration "${configuration}" \
      -derivedDataPath build/macos \
      CODE_SIGNING_ALLOWED=NO \
      build 2>&1)"; then
      echo "${output}"
      return 0
    fi
    status=$?
    echo "${output}" >&2
    if [[ "${attempt}" -lt 3 ]] \
      && echo "${output}" | grep -qE 'Could not resolve package dependencies|Couldn.t fetch updates from remote repositories|INTERNAL ERROR: Uncaught exception'; then
      echo "xcodebuild SPM failed (attempt ${attempt}/3); clearing cache and retrying in 15s…" >&2
      rm -rf ~/Library/Caches/org.swift.swiftpm
      rm -rf build/macos
      sleep 15
      continue
    fi
    return "${status}"
  done
}

build_with_retry
