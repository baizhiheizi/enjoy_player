#!/usr/bin/env bash
# Pre-fetch the Gradle wrapper distribution so the APK build never depends on
# the wrapper's own no-retry download.
#
# Why:
#   On 2026-11-24 the Android APK smoke failed at the very first Gradle
#   invocation with
#
#     Exception in thread "main" java.util.zip.ZipException: zip END header not found
#       at org.gradle.wrapper.Install.unzip(Install.java:214)
#
#   The wrapper had downloaded a *truncated* distribution zip during a network
#   brownout on this runner's route to services.gradle.org ("curl: (35)
#   OpenSSL SSL_connect: SSL_ERROR_SYSCALL") and then failed to unzip it. The
#   wrapper downloads with no retry and no integrity check, and it leaves the
#   truncated zip on disk — so the same corrupt archive is served again by the
#   actions/cache restore of ~/.gradle/wrapper/dists and the failure repeats on
#   every later run until the cache entry is evicted.
#
# What:
#   1. Makes sure the Gradle wrapper is in the project. Flutter injects it from
#      its own SDK cache at build time (android/gradlew and the wrapper jar are
#      gitignored), so a script that runs before the build has to do the same.
#   2. Sweeps the wrapper dists tree and deletes any distribution zip that is
#      not a readable archive (this is the corrupt archive a cache restore
#      hands back).
#   3. Downloads the distribution with curl — retries, Range resume, and a
#      post-download integrity check — into the wrapper's own dist directory,
#      so the wrapper finds a valid archive and only has to unzip it.
#
# The wrapper's dist directory is named with a hash of the distribution URL, so
# the script lets the wrapper create it (one `gradlew --version` attempt) and
# then looks the directory up, instead of re-deriving Gradle's own hash.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
android_dir="${root}/android"

log() {
  echo "[prefetch_gradle_distribution] $*"
}

resolve_flutter_root() {
  if [ -n "${FLUTTER_ROOT:-}" ] && [ -d "${FLUTTER_ROOT}/bin/cache/artifacts" ]; then
    printf '%s\n' "${FLUTTER_ROOT}"
    return 0
  fi
  local flutter_bin sdk_dir
  if flutter_bin="$(command -v flutter 2>/dev/null)"; then
    sdk_dir="$(cd "$(dirname "${flutter_bin}")/cache/dart-sdk/bin" 2>/dev/null && pwd || true)"
    if [ -n "${sdk_dir}" ] && [ -x "${sdk_dir}/dart" ]; then
      sdk_dir="$(cd "$(dirname "${sdk_dir}")/../.." && pwd)"
      if [ -d "${sdk_dir}/bin/cache/artifacts" ]; then
        printf '%s\n' "${sdk_dir}"
        return 0
      fi
    fi
  fi
  if [ -f "${android_dir}/local.properties" ]; then
    local sdk
    sdk="$(sed -nE 's/^[[:space:]]*flutter\.sdk[[:space:]]*=[[:space:]]*(.*)$/\1/p' \
      "${android_dir}/local.properties" | head -n 1 | sed 's/[[:space:]]*$//')"
    if [ -n "${sdk}" ] && [ -d "${sdk}/bin/cache/artifacts" ]; then
      printf '%s\n' "${sdk}"
      return 0
    fi
  fi
  return 1
}

ensure_wrapper_present() {
  local flutter_root artifact
  if ! flutter_root="$(resolve_flutter_root)"; then
    log "Could not locate the Flutter SDK; skipping the wrapper injection."
    return 1
  fi
  artifact="${flutter_root}/bin/cache/artifacts/gradle_wrapper"
  if [ ! -d "${artifact}" ]; then
    log "The Flutter SDK has no gradle_wrapper artifact; skipping the wrapper injection."
    return 1
  fi
  if [ ! -x "${android_dir}/gradlew" ]; then
    log "Injecting the Gradle wrapper from the Flutter SDK (gitignored, so it is absent on a fresh checkout)."
    cp "${artifact}/gradlew" "${android_dir}/gradlew"
    cp "${artifact}/gradlew.bat" "${android_dir}/gradlew.bat"
    chmod +x "${android_dir}/gradlew"
  fi
  if [ ! -f "${android_dir}/gradle/wrapper/gradle-wrapper.jar" ]; then
    mkdir -p "${android_dir}/gradle/wrapper"
    cp "${artifact}/gradle/wrapper/gradle-wrapper.jar" \
      "${android_dir}/gradle/wrapper/gradle-wrapper.jar"
  fi
  return 0
}

wrapper_properties="${android_dir}/gradle/wrapper/gradle-wrapper.properties"
if [ ! -f "${wrapper_properties}" ]; then
  echo "prefetch_gradle_distribution: ${wrapper_properties} is missing." >&2
  exit 1
fi

distribution_url="$(sed -nE 's/^[[:space:]]*distributionUrl[[:space:]]*=[[:space:]]*(.*)$/\1/p' \
  "${wrapper_properties}" | head -n1 | sed 's/[[:space:]]*$//')"
distribution_url="${distribution_url//\\:/:}"
if [ -z "${distribution_url}" ]; then
  echo "prefetch_gradle_distribution: no distributionUrl in ${wrapper_properties}." >&2
  exit 1
fi

dist_name="$(basename "${distribution_url}")"
dist_name="${dist_name%.zip}"
gradle_user_home="${GRADLE_USER_HOME:-${HOME}/.gradle}"
dists_root="${gradle_user_home}/wrapper/dists"

zip_is_valid() {
  local archive="$1"
  [ -s "${archive}" ] || return 1
  if command -v unzip >/dev/null 2>&1; then
    unzip -tqq "${archive}" >/dev/null 2>&1
    return $?
  fi
  tail -c 22 "${archive}" | grep -q "PK" 2>/dev/null
}

sweep_corrupt_zips() {
  local archive
  while IFS= read -r archive; do
    if ! zip_is_valid "${archive}"; then
      log "Removing truncated distribution archive ${archive}"
      rm -f "${archive}"
    fi
  done < <(find "${dists_root}/${dist_name}" -maxdepth 2 -name "${dist_name}.zip" -type f 2>/dev/null || true)
}

resolve_dist_dir() {
  local candidate
  for candidate in "${dists_root}/${dist_name}"/*/; do
    [ -d "${candidate}" ] || continue
    printf '%s\n' "${candidate%/}"
    return 0
  done
  return 1
}

download_distribution() {
  local target_dir="$1"
  local archive="${target_dir}/${dist_name}.zip"
  local attempt delay
  for attempt in 1 2 3 4 5; do
    delay=$((attempt * 10))
    log "Downloading ${distribution_url} (attempt ${attempt}/5)…"
    if curl -fsSL --http1.1 --retry 3 --retry-delay 5 --retry-all-errors \
      -C - -o "${archive}" "${distribution_url}"; then
      if zip_is_valid "${archive}"; then
        return 0
      fi
      log "Downloaded archive is not a readable zip; retrying."
      rm -f "${archive}"
    else
      log "Download failed; retrying in ${delay}s."
    fi
    sleep "${delay}"
  done
  return 1
}

if ! ensure_wrapper_present; then
  log "The Gradle wrapper is unavailable; leaving the distribution to the wrapper."
  exit 0
fi

sweep_corrupt_zips

log "Resolving the Gradle distribution ${dist_name}…"
if (cd "${android_dir}" && ./gradlew --version >/dev/null 2>&1); then
  log "Gradle distribution already present."
  exit 0
fi

dist_dir="$(resolve_dist_dir || true)"
if [ -z "${dist_dir}" ]; then
  log "The wrapper did not create a distribution directory; nothing to pre-fetch."
  exit 0
fi

mkdir -p "${dist_dir}"
download_distribution "${dist_dir}" || {
  echo "prefetch_gradle_distribution: could not download ${distribution_url}." >&2
  exit 1
}

log "Verifying the Gradle distribution…"
if (cd "${android_dir}" && ./gradlew --version >/dev/null 2>&1); then
  log "Gradle distribution is ready."
  exit 0
fi

echo "prefetch_gradle_distribution: the wrapper still cannot use ${distribution_url}." >&2
exit 1
