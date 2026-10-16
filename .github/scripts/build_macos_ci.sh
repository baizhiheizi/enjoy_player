#!/usr/bin/env bash
# Compile-only macOS smoke build for CI without Apple Development signing.
#
# flutter build macos does not forward xcodebuild settings after "--"; those
# positional args are treated as Dart entrypoints. Use config-only + xcodebuild
# with CODE_SIGNING_ALLOWED=NO instead (see ADR/docs in packaging.md for why
# local dev keeps Apple Development signing on the Runner target).
set -euo pipefail

configuration="${1:?Usage: $0 Debug|Release}"

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${root}"

# shellcheck source=apple_spm_hygiene.sh
source "${root}/.github/scripts/apple_spm_hygiene.sh"
apple_sanitize_git_env_for_spm

case "${configuration}" in
  Debug | Release) ;;
  *)
    echo "Unsupported configuration: ${configuration}" >&2
    exit 1
    ;;
esac

config_flag="$(echo "${configuration}" | tr '[:upper:]' '[:lower:]')"

# Xcode 16 SwiftPM can crash (NSMutableArray insertObjects:atIndexes: count
# mismatch) when stale package resolution state lingers. Clear caches so each
# CI run starts from a clean slate.
apple_clear_spm_caches "${root}"

# package:sqlite3 3.x downloads libsqlite3.dylib for the target arch from
# github.com via the dart_build hook (Dart HttpClient, no retries). Restricted
# networks and the self-hosted runners drop that TLS handshake, which fails the
# Flutter Assemble phase with "Building native assets failed". Prefetch both
# macOS arches (x64 + arm64 for the universal app) into the dart_build shared
# cache with curl (which retries) so the hook reuses them. Best-effort: if the
# fetch cannot run, fall back to letting the hook download on its own.
echo ">>> Prefetch sqlite3 macOS native libs"
bash "${root}/tool/prefetch_sqlite3_libs.sh" macos \
  || echo "prefetch_sqlite3_libs: skipped; the dart_build hook will fetch on its own" >&2

build_with_retry() {
  # "$@" inside apple_with_spm_host_lock runs this function with errexit
  # exempted, so every step must forward its own failure explicitly.
  apple_retry_spm_command "${root}" \
    flutter build macos --"${config_flag}" --config-only || return $?

  # --config-only regenerates the ephemeral SwiftPM package symlinks, so the
  # floor patch must run after it and before xcodebuild resolves packages.
  apple_raise_swiftpm_macos_floors "${root}" "12.0" || return $?

  apple_retry_spm_command "${root}" \
    xcodebuild \
    -workspace macos/Runner.xcworkspace \
    -scheme Runner \
    -configuration "${configuration}" \
    -derivedDataPath build/macos \
    CODE_SIGNING_ALLOWED=NO \
    build || return $?
}

apple_with_spm_host_lock build_with_retry
