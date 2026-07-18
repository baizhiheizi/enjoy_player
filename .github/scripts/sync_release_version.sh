#!/usr/bin/env bash
# Sync platform-specific version metadata from pubspec.yaml.
#
# Source of truth: pubspec.yaml (version: X.Y.Z+N)
# - Android versionName/versionCode — read from pubspec at `flutter build` time
# - iOS/macOS CFBundle* — read from pubspec via Flutter-Generated.xcconfig
# - Windows .exe FileVersion — read from pubspec at `flutter build` time
# - Linux build metadata and AppImage filename — read from pubspec
# - Windows Inno Setup installer — MyAppVersion must be synced manually (below)
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${root}"

version="$(bash "${root}/.github/scripts/read_pubspec_version.sh")"
build="$(bash "${root}/.github/scripts/read_pubspec_version.sh" --build)"

iss="${root}/windows/installer/enjoy_player.iss"
if [[ ! -f "${iss}" ]]; then
  echo "Missing ${iss}" >&2
  exit 1
fi

tmp="$(mktemp)"
sed "s/^#define MyAppVersion \".*\"/#define MyAppVersion \"${version}\"/" "${iss}" > "${tmp}"
mv "${tmp}" "${iss}"

echo "Release version ${version}+${build}"
echo "  pubspec.yaml              ${version}+${build} (source of truth)"
echo "  windows/installer         MyAppVersion=${version}"
echo "  android                   versionName/versionCode from pubspec at build"
echo "  ios/macos                 CFBundle* from pubspec at build"
echo "  windows/runner            FileVersion from pubspec at build"
echo "  linux                     build metadata/AppImage version from pubspec"
