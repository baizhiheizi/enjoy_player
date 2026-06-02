#!/usr/bin/env bash
# Windows direct-download release — same steps as release_windows.yml.
#
# Usage:
#   bash .github/scripts/release_windows.sh              # build + installer
#   bash .github/scripts/release_windows.sh --publish    # build + upload feeds
#   bash .github/scripts/release_windows.sh --feeds-only # build + local feeds only
#   bash .github/scripts/release_windows.sh --publish-only --publish
set -euo pipefail

lib="$(dirname "$0")/release_lib.sh"
# shellcheck source=release_lib.sh
source "${lib}"

root="$(release_repo_root)"
cd "${root}"

SKIP_CHECKS=false
SKIP_BUILD=false
BUILD_INSTALLER=true
PUBLISH=false
FEEDS_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-checks) SKIP_CHECKS=true; shift ;;
    --skip-build | --publish-only) SKIP_BUILD=true; shift ;;
    --no-installer) BUILD_INSTALLER=false; shift ;;
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
  release_pwsh "${root}/.github/scripts/ensure_nuget_feed.ps1"
fi

if [[ "${SKIP_BUILD}" != true ]]; then
  echo ">>> Build Windows release (direct channel)"
  release_pwsh "${root}/windows/scripts/fetch_ffmpeg.ps1"
  flutter build windows --release --dart-define=DISTRIBUTION_CHANNEL=direct

  if [[ "${BUILD_INSTALLER}" == true ]]; then
    echo ">>> Build Inno Setup installer"
    release_pwsh "${root}/.github/scripts/sync_windows_installer_version.ps1"
    release_pwsh "${root}/.github/scripts/ensure_inno_setup.ps1"
    iscc "${root}/windows/installer/enjoy_player.iss"
  fi
fi

if [[ "${PUBLISH}" == true ]]; then
  release_load_publish_env "${root}"
  installer="$(ls -1 "${root}/build/windows/installer/"EnjoyPlayerSetup-v*.exe 2>/dev/null | head -1 || true)"
  if [[ -z "${installer}" ]]; then
    echo "No installer at build/windows/installer/EnjoyPlayerSetup-v*.exe" >&2
    exit 1
  fi
  publish_args=(--windows-installer "${installer}")
  if [[ "${FEEDS_ONLY}" == true ]]; then
    publish_args=(--feeds-only "${publish_args[@]}")
  else
    export RELEASE_REQUIRE_S3=1
  fi
  echo ">>> Publish (${installer})"
  bash "${root}/.github/scripts/publish_player_release_to_s3.sh" "${publish_args[@]}"
fi

release_print_artifacts "${root}" windows
echo "Done."
