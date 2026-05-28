#!/usr/bin/env bash
# Rename Flutter release outputs to versioned filenames (semver from pubspec.yaml).
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${root}"

version="$("${root}/.github/scripts/read_pubspec_version.sh")"
prefix="EnjoyPlayer-v${version}"

rename_if_exists() {
  local src="$1"
  local dest="$2"
  if [[ -f "${src}" ]]; then
    mv -f "${src}" "${dest}"
    echo "Renamed: $(basename "${dest}")"
  fi
}

platform="${1:-all}"

rename_android() {
  local aab_dir="build/app/outputs/bundle/release"
  if compgen -G "${aab_dir}/*.aab" >/dev/null; then
    local aab
    aab="$(ls -1 "${aab_dir}"/*.aab | head -1)"
    rename_if_exists "${aab}" "${aab_dir}/${prefix}.aab"
  fi

  local apk_dir="build/app/outputs/flutter-apk"
  rename_if_exists "${apk_dir}/app-arm64-v8a-release.apk" "${apk_dir}/${prefix}-arm64-v8a.apk"
  rename_if_exists "${apk_dir}/app-armeabi-v7a-release.apk" "${apk_dir}/${prefix}-armeabi-v7a.apk"
  rename_if_exists "${apk_dir}/app-x86_64-release.apk" "${apk_dir}/${prefix}-x86_64.apk"
}

rename_apple() {
  local ipa_dir="build/ios/ipa"
  if compgen -G "${ipa_dir}/*.ipa" >/dev/null; then
    local ipa
    ipa="$(ls -1 "${ipa_dir}"/*.ipa | head -1)"
    rename_if_exists "${ipa}" "${ipa_dir}/${prefix}.ipa"
  fi
}

case "${platform}" in
  android) rename_android ;;
  apple) rename_apple ;;
  all)
    rename_android
    rename_apple
    ;;
  *)
    echo "Usage: $0 [android|apple|all]" >&2
    exit 1
    ;;
esac

echo "Release artifact prefix: ${prefix}"
