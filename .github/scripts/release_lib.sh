#!/usr/bin/env bash
# Shared helpers for local + CI release scripts.
set -euo pipefail

release_repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

release_version() {
  bash "$(dirname "${BASH_SOURCE[0]}")/read_pubspec_version.sh"
}

release_build_number() {
  bash "$(dirname "${BASH_SOURCE[0]}")/read_pubspec_version.sh" --build
}

release_log_publish_only() {
  if [[ "${RELEASE_SKIP_BUILD}" == true && "${RELEASE_PUBLISH}" == true ]]; then
    echo ">>> Publish only (skipping build and checks; using existing artifacts)"
  fi
}

release_apply_sparkle_sign_output() {
  local output="$1"
  local sig=""
  if echo "${output}" | grep -q 'edSignature'; then
    sig="$(echo "${output}" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')"
    export SPARKLE_ED_SIGNATURE_MACOS="${sig}"
  elif echo "${output}" | grep -q 'dsaSignature'; then
    sig="$(echo "${output}" | sed -n 's/.*sparkle:dsaSignature="\([^"]*\)".*/\1/p')"
    export SPARKLE_ED_SIGNATURE_WINDOWS="${sig}"
  fi
}

release_load_publish_env() {
  local root="$1"
  local env_file="${root}/.github/scripts/publish_env.local.sh"
  if [[ -f "${env_file}" ]]; then
    # shellcheck source=/dev/null
    source "${env_file}"
    echo "Loaded publish env from ${env_file}"
  fi
}

# Parse shared release flags. Platform-specific flags remain in RELEASE_EXTRA_ARGS.
release_parse_common_args() {
  RELEASE_SKIP_CHECKS=false
  RELEASE_SKIP_BUILD=false
  RELEASE_PUBLISH=false
  RELEASE_FEEDS_ONLY=false
  RELEASE_EXTRA_ARGS=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-checks)
        RELEASE_SKIP_CHECKS=true
        shift
        ;;
      --skip-build)
        RELEASE_SKIP_BUILD=true
        shift
        ;;
      --publish-only)
        RELEASE_SKIP_BUILD=true
        RELEASE_SKIP_CHECKS=true
        shift
        ;;
      --publish)
        RELEASE_PUBLISH=true
        shift
        ;;
      --feeds-only)
        RELEASE_FEEDS_ONLY=true
        RELEASE_PUBLISH=true
        shift
        ;;
      *)
        RELEASE_EXTRA_ARGS+=("$1")
        shift
        ;;
    esac
  done
}

# Parse --windows-installer / --macos-zip / --android-apk into RELEASE_ARTIFACT_* globals.
release_parse_artifact_args() {
  RELEASE_ARTIFACT_KEYS=()
  declare -gA RELEASE_ARTIFACT_PATHS=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --windows-installer)
        RELEASE_ARTIFACT_KEYS+=(windows)
        RELEASE_ARTIFACT_PATHS[windows]="$2"
        shift 2
        ;;
      --macos-zip)
        RELEASE_ARTIFACT_KEYS+=(macos)
        RELEASE_ARTIFACT_PATHS[macos]="$2"
        shift 2
        ;;
      --android-apk)
        RELEASE_ARTIFACT_KEYS+=("$2")
        RELEASE_ARTIFACT_PATHS["$2"]="$3"
        shift 3
        ;;
      *)
        echo "Unknown arg: $1" >&2
        return 1
        ;;
    esac
  done
}

# Reconstruct artifact argv (for forwarding to generate_update_feeds.sh).
release_artifact_argv() {
  local -n _out=$1
  _out=()
  local key
  for key in "${RELEASE_ARTIFACT_KEYS[@]}"; do
    case "${key}" in
      windows)
        _out+=(--windows-installer "${RELEASE_ARTIFACT_PATHS[windows]}")
        ;;
      macos)
        _out+=(--macos-zip "${RELEASE_ARTIFACT_PATHS[macos]}")
        ;;
      *)
        _out+=(--android-apk "${key}" "${RELEASE_ARTIFACT_PATHS[$key]}")
        ;;
    esac
  done
}

# Stale pubspec.yaml under build/release/ (e.g. from local feed staging) breaks
# flutter analyze: path deps and assets resolve relative to that nested copy.
release_prune_stale_build_pubspecs() {
  local root="$1"
  if [[ -d "${root}/build/release" ]]; then
    find "${root}/build/release" -name pubspec.yaml -type f -delete 2>/dev/null || true
  fi
}

release_run_checks() {
  local root="$1"
  cd "${root}"
  release_prune_stale_build_pubspecs "${root}"
  flutter pub get
  flutter analyze
  flutter test
}

release_run_android_checks() {
  local root="$1"
  cd "${root}"
  release_prune_stale_build_pubspecs "${root}"
  flutter pub get
  bash tool/patch_agp9_pub_plugins.sh
  flutter analyze
  flutter test
}

release_pwsh() {
  if command -v pwsh >/dev/null 2>&1; then
    pwsh "$@"
  else
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$@"
  fi
}

release_print_artifacts() {
  local root="$1"
  local platform="$2"
  echo ""
  echo "=== Release artifacts (${platform}) ==="
  case "${platform}" in
    windows)
      compgen -G "${root}/build/windows/installer/EnjoyPlayerSetup-v"*.exe >/dev/null 2>&1 &&
        ls -1 "${root}/build/windows/installer/"EnjoyPlayerSetup-v*.exe || true
      ;;
    android)
      compgen -G "${root}/build/app/outputs/bundle/release/EnjoyPlayer-v"*.aab >/dev/null 2>&1 &&
        ls -1 "${root}/build/app/outputs/bundle/release/"EnjoyPlayer-v*.aab || true
      compgen -G "${root}/build/app/outputs/flutter-apk/EnjoyPlayer-v"*.apk >/dev/null 2>&1 &&
        ls -1 "${root}/build/app/outputs/flutter-apk/"EnjoyPlayer-v*.apk || true
      ;;
    apple)
      compgen -G "${root}/build/ios/ipa/EnjoyPlayer-v"*.ipa >/dev/null 2>&1 &&
        ls -1 "${root}/build/ios/ipa/"EnjoyPlayer-v*.ipa || true
      compgen -G "${root}/EnjoyPlayer-macOS-v"*.zip >/dev/null 2>&1 &&
        ls -1 "${root}/"EnjoyPlayer-macOS-v*.zip || true
      ;;
  esac
  local feed_dir="${root}/build/update-feeds"
  if [[ -f "${feed_dir}/latest.json" ]]; then
    echo "Local feeds: ${feed_dir}/latest.json"
    echo "             ${feed_dir}/appcast.xml"
  fi
}
