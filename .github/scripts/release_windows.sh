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

BUILD_INSTALLER=true
RELEASE_PUBLISH_GITHUB=false

release_parse_common_args "$@"
for arg in ${RELEASE_EXTRA_ARGS[@]+"${RELEASE_EXTRA_ARGS[@]}"}; do
  case "${arg}" in
    --no-installer) BUILD_INSTALLER=false ;;
    --publish-github) RELEASE_PUBLISH_GITHUB=true ;;
    -h | --help)
      sed -n '2,8p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: ${arg}" >&2
      exit 1
      ;;
  esac
done

release_log_publish_only

if [[ "${RELEASE_SKIP_CHECKS}" != true ]]; then
  echo ">>> Pre-release checks"
  release_run_checks "${root}"
  release_pwsh "${root}/.github/scripts/ensure_nuget_feed.ps1"
fi

if [[ "${RELEASE_SKIP_BUILD}" != true ]]; then
  # Load publish env before building so POSTHOG_* (and other build inputs)
  # apply to the binary, not just the publish step.
  release_load_publish_env "${root}"
  defines=()
  release_append_posthog_defines defines

  # package:sqlite3 3.x downloads its prebuilt library from
  # github.com/simolus3/sqlite3.dart/releases with Dart HttpClient (no
  # retries); a dropped TLS handshake fails the whole build with "Building
  # native assets failed". Prefetch into the dart_build shared cache with
  # curl (which retries), the way the CI smoke build does.
  echo ">>> Prefetch sqlite3 Windows native libs"
  bash "${root}/tool/prefetch_sqlite3_libs.sh" windows \
    || echo "prefetch_sqlite3_libs: skipped; the dart_build hook will fetch on its own" >&2

  echo ">>> Build Windows release (direct channel)"
  release_pwsh "${root}/windows/scripts/fetch_ffmpeg.ps1"
  flutter build windows --release --dart-define=DISTRIBUTION_CHANNEL=direct ${defines[@]+"${defines[@]}"}

  if [[ "${BUILD_INSTALLER}" == true ]]; then
    echo ">>> Build Inno Setup installer"
    bash "${root}/.github/scripts/sync_release_version.sh"
    release_pwsh "${root}/.github/scripts/ensure_inno_setup.ps1"
    iscc "${root}/windows/installer/enjoy_player.iss"
  fi
fi

if [[ "${RELEASE_PUBLISH}" == true ]]; then
  release_load_publish_env "${root}"
  installer="$(release_windows_installer_path "${root}")"
  if [[ ! -f "${installer}" ]]; then
    echo "No installer at ${installer} (expected pubspec version $(release_version))" >&2
    exit 1
  fi
  publish_args=(--windows-installer "${installer}")
  echo ">>> Publish (${installer})"
  release_publish_to_s3 "${root}" "${publish_args[@]}"
fi

if [[ "${RELEASE_PUBLISH_GITHUB}" == true ]]; then
  release_publish_github "${root}" windows
fi

release_print_artifacts "${root}" windows
echo "Done."
