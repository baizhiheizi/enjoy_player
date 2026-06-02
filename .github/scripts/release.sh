#!/usr/bin/env bash
# Local + CI release entry point. Delegates to platform scripts (same logic as GitHub workflows).
#
# Usage:
#   bash .github/scripts/release.sh --platform windows
#   bash .github/scripts/release.sh --platform windows --publish
#   bash .github/scripts/release.sh --platform windows --feeds-only
#   bash .github/scripts/release.sh --platform android --publish
#   bash .github/scripts/release.sh --platform apple --notarize --publish
#
# From repo root on Windows (loads publish_env.local.ps1 when present):
#   pwsh ./release.ps1 -Platform windows -Publish
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
scripts="${root}/.github/scripts"

PLATFORM=""
ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    -h | --help)
      cat <<'EOF'
Enjoy Player release (shared local + CI logic)

  bash .github/scripts/release.sh --platform <windows|android|apple> [options]

Common options (forwarded to the platform script):
  --skip-checks       Skip flutter analyze / test
  --publish-only      Skip build; publish existing artifacts
  --publish           Upload to dl.enjoy.bot (needs S3 env / publish_env.local.*)
  --feeds-only        Build feeds locally (build/update-feeds/) without S3 upload

Windows:
  --no-installer      Skip Inno Setup .exe

Android:
  --no-apk            Skip sideload APKs
  --no-aab            Skip Play App Bundle

Apple (macOS host):
  --notarize          Notarize macOS .app for direct download
  --testflight        Upload IPA to TestFlight

Env: copy .github/scripts/publish_env.example.ps1 → publish_env.local.ps1
     or publish_env.example.sh → publish_env.local.sh
EOF
      exit 0
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z "${PLATFORM}" ]]; then
  echo "Missing --platform (windows|android|apple). Try --help." >&2
  exit 1
fi

case "${PLATFORM}" in
  windows)
    exec bash "${scripts}/release_windows.sh" "${ARGS[@]}"
    ;;
  android)
    exec bash "${scripts}/release_android.sh" "${ARGS[@]}"
    ;;
  apple)
    exec bash "${scripts}/release_apple.sh" "${ARGS[@]}"
    ;;
  *)
    echo "Unknown platform: ${PLATFORM}" >&2
    exit 1
    ;;
esac
