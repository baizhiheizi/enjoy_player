#!/usr/bin/env bash
# Android release — same steps as release_android.yml (Play AAB + direct APKs).
#
# Usage:
#   bash .github/scripts/release_android.sh
#   bash .github/scripts/release_android.sh --publish
#   bash .github/scripts/release_android.sh --feeds-only --publish-only --publish
set -euo pipefail

lib="$(dirname "$0")/release_lib.sh"
# shellcheck source=release_lib.sh
source "${lib}"

root="$(release_repo_root)"
cd "${root}"

BUILD_APK=true
BUILD_AAB=true

release_parse_common_args "$@"
for arg in ${RELEASE_EXTRA_ARGS[@]+"${RELEASE_EXTRA_ARGS[@]}"}; do
  case "${arg}" in
    --no-apk) BUILD_APK=false ;;
    --no-aab) BUILD_AAB=false ;;
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
  release_run_android_checks "${root}"
fi

if [[ "${RELEASE_SKIP_BUILD}" != true ]]; then
  if [[ -f "${root}/.github/scripts/setup_android_signing.sh" ]]; then
    if ! bash "${root}/.github/scripts/setup_android_signing.sh"; then
      if [[ -f "${root}/android/key.properties" ]]; then
        echo "Using existing android/key.properties (signing setup skipped)."
      elif [[ -n "${GITHUB_ACTIONS:-}" || "${RELEASE_PUBLISH}" == true ]]; then
        echo "Android signing setup failed; CI/publish requires a release keystore." >&2
        exit 1
      else
        echo "WARNING: No release keystore; APK/AAB will be debug-signed." >&2
      fi
    fi
  fi

  echo ">>> Prune stale Android JNI merge cache (flutter/flutter#187553)"
  bash "${root}/tool/prune_android_jni_merge_cache.sh"

  # Always patch pub-cache plugins for AGP 9 (also covers --skip-checks and
  # Windows hosts where ~/.pub-cache is not the Flutter cache).
  echo ">>> Apply AGP 9 pub plugin patches"
  bash "${root}/tool/patch_agp9_pub_plugins.sh"
  # Drop stale share_plus outputs from pre-patch builds (empty UP-TO-DATE Kotlin).
  rm -rf "${root}/build/share_plus"

  release_stop_gradle_daemons "${root}"

  if [[ "${BUILD_AAB}" == true ]]; then
    echo ">>> Build App Bundle (store / Play)"
    flutter build appbundle --release --flavor store
  fi

  if [[ "${BUILD_APK}" == true ]]; then
    echo ">>> Build sideload APKs (direct / per ABI)"
    flutter build apk --release --split-per-abi --flavor direct \
      --dart-define=DISTRIBUTION_CHANNEL=direct
  fi

  bash "${root}/.github/scripts/rename_release_artifacts.sh" android

  if [[ "${BUILD_AAB}" == true ]]; then
    aab="$(release_android_aab_path "${root}")"
    if [[ ! -f "${aab}" ]]; then
      echo "Expected Play AAB not found at ${aab} after rename." >&2
      echo "Check build/app/outputs/bundle/release/ for app-release.aab." >&2
      exit 1
    fi
  fi

  if [[ "${BUILD_APK}" == true ]]; then
    arm64_apk="$(release_android_apk_path "${root}" "arm64-v8a")"
    if [[ ! -f "${arm64_apk}" ]]; then
      echo "Expected sideload APK not found at ${arm64_apk} after rename." >&2
      echo "Check build/app/outputs/flutter-apk/ for app-*-direct-release.apk outputs." >&2
      exit 1
    fi
  fi
fi

if [[ "${RELEASE_PUBLISH}" == true ]]; then
  release_load_publish_env "${root}"
  apk_dir="${root}/build/app/outputs/flutter-apk"
  publish_args=()
  for abi in arm64-v8a armeabi-v7a x86_64; do
    f="$(release_android_apk_path "${root}" "${abi}")"
    if [[ -f "${f}" ]]; then
      publish_args+=(--android-apk "android_${abi//-/_}" "${f}")
    fi
  done
  if [[ ${#publish_args[@]} -eq 0 ]]; then
    echo "No sideload APKs to publish in ${apk_dir}" >&2
    exit 1
  fi
  if [[ "${RELEASE_FEEDS_ONLY}" == true ]]; then
    publish_args=(--feeds-only "${publish_args[@]}")
  else
    export RELEASE_REQUIRE_S3=1
  fi
  echo ">>> Publish Android sideload APKs"
  bash "${root}/.github/scripts/publish_player_release_to_s3.sh" "${publish_args[@]}"
fi

release_print_artifacts "${root}" android
echo "Done."
