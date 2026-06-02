#!/usr/bin/env bash
# Shared helpers for local + CI release scripts.
set -euo pipefail

release_repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

release_version() {
  bash "$(dirname "${BASH_SOURCE[0]}")/read_pubspec_version.sh"
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

release_run_checks() {
  local root="$1"
  cd "${root}"
  flutter pub get
  flutter analyze
  flutter test
}

release_run_android_checks() {
  local root="$1"
  cd "${root}"
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
