#!/usr/bin/env bash
# Pre-fetch the Flutter engine Android artifacts (io.flutter:*) into a local
# Maven repository, so the Gradle build resolves them from disk.
#
# Why:
#   The Flutter Gradle plugin resolves the engine artifacts — the embedding
#   plus one libflutter.so jar per ABI — from
#   $FLUTTER_STORAGE_BASE_URL/download.flutter.io. Gradle downloads them with
#   no retry, and on this runner's network the China mirror
#   (storage.flutter-io.cn) intermittently resets the TLS handshake
#   ("Remote host terminated the handshake"). One reset fails the whole APK
#   build, and the artifacts are ~520 MB in total, so the retry is expensive.
#
# What:
#   Downloads each artifact with curl (retries + Range resume) into
#     build/flutter-engine-maven/io/flutter/<artifact>/<version>/
#   in Maven layout. android/build.gradle.kts registers that directory as the
#   first repository, so Gradle resolves io.flutter:* from disk and never
#   touches the mirror.
#
# The artifact version comes from the installed Flutter SDK
# (bin/cache/engine.stamp), so a Flutter bump moves to a new engine version
# automatically instead of leaving this script pinned to a stale one.
#
# Usage:
#   bash tool/prefetch_flutter_engine_android_libs.sh            # debug + release
#   bash tool/prefetch_flutter_engine_android_libs.sh debug
#   FLUTTER_ENGINE_MAVEN_REPO=/tmp/repo bash tool/prefetch_flutter_engine_android_libs.sh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  echo "Usage: $0 [mode ...]" >&2
  echo "  modes: debug release profile (default: debug release)" >&2
}

modes=()
for arg in "$@"; do
  case "${arg}" in
    debug | release | profile) modes+=("${arg}") ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown mode: ${arg}" >&2
      usage
      exit 2
      ;;
  esac
done
if [ "${#modes[@]}" -eq 0 ]; then
  modes=(debug release)
fi

repo_dir="${FLUTTER_ENGINE_MAVEN_REPO:-${root}/build/flutter-engine-maven}"

# ABIs the Flutter Gradle plugin adds for an Android build. This is
# FlutterPluginConstants.DEFAULT_PLATFORMS in the Flutter SDK: android-arm,
# android-arm64 and android-x64. The 32-bit x86 ABI is not built.
abis=(armeabi_v7a arm64_v8a x86_64)

# The Flutter SDK root, from FLUTTER_ROOT, from `flutter` on PATH, or from
# android/local.properties — the same sources the Gradle build uses.
resolve_flutter_root() {
  if [ -n "${FLUTTER_ROOT:-}" ] && [ -f "${FLUTTER_ROOT}/bin/cache/engine.stamp" ]; then
    printf '%s\n' "${FLUTTER_ROOT}"
    return 0
  fi
  local flutter_bin
  if flutter_bin="$(command -v flutter 2>/dev/null)"; then
    local resolved
    resolved="$(readlink -f "${flutter_bin}")"
    local candidate
    candidate="$(dirname "$(dirname "${resolved}")")"
    if [ -f "${candidate}/bin/cache/engine.stamp" ]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  fi
  if [ -f "${root}/android/local.properties" ]; then
    local sdk
    sdk="$(sed -nE 's/^[[:space:]]*flutter\.sdk[[:space:]]*=[[:space:]]*(.*)$/\1/p' \
      "${root}/android/local.properties" | head -n 1 | sed 's/[[:space:]]*$//')"
    if [ -n "${sdk}" ] && [ -f "${sdk}/bin/cache/engine.stamp" ]; then
      printf '%s\n' "${sdk}"
      return 0
    fi
  fi
  echo "prefetch_flutter_engine_android_libs: cannot locate the Flutter SDK." >&2
  echo "  Set FLUTTER_ROOT, put flutter on PATH, or run 'flutter pub get' once" \
    "so android/local.properties exists." >&2
  exit 1
}

flutter_root="$(resolve_flutter_root)"

engine_stamp="$(tr -d '[:space:]' < "${flutter_root}/bin/cache/engine.stamp")"
if [ -z "${engine_stamp}" ]; then
  echo "prefetch_flutter_engine_android_libs: empty engine.stamp in ${flutter_root}." >&2
  exit 1
fi
engine_version="1.0.0-${engine_stamp}"

# The realm is a path prefix ("beta/", "stable/") that the Flutter SDK keeps
# next to the engine stamp; it is empty on stable channels.
engine_realm="$(tr -d '[:space:]' < "${flutter_root}/bin/cache/engine.realm" 2>/dev/null || true)"
if [ -n "${engine_realm}" ]; then
  engine_realm="${engine_realm}/"
fi

# The China mirror is tried first because it is routed DIRECT by the runner's
# OpenClash rules and costs no proxy bytes; the upstream bucket is the
# fallback for when the mirror is in one of its reset bursts.
base_urls=()
if [ -n "${FLUTTER_STORAGE_BASE_URL:-}" ]; then
  base_urls+=("${FLUTTER_STORAGE_BASE_URL}")
fi
base_urls+=("https://storage.googleapis.com")

repo_urls=()
for base in "${base_urls[@]}"; do
  url="${base%/}/${engine_realm}download.flutter.io"
  duplicate=0
  for existing in ${repo_urls[@]+"${repo_urls[@]}"}; do
    if [ "${existing}" = "${url}" ]; then
      duplicate=1
      break
    fi
  done
  if [ "${duplicate}" -eq 0 ]; then
    repo_urls+=("${url}")
  fi
done

sha1_of() {
  if command -v sha1sum >/dev/null 2>&1; then
    sha1sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 1 "$1" | awk '{print $1}'
  else
    echo "Need sha1sum or shasum on PATH." >&2
    exit 1
  fi
}

md5_of() {
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "$1" | awk '{print $1}'
  elif command -v md5 >/dev/null 2>&1; then
    md5 -q "$1"
  else
    echo ""
  fi
}

# A jar is complete when it starts with a local file header and its central
# directory ends the file with the end-of-central-directory record.
jar_is_valid() {
  local path="$1"
  [ -s "${path}" ] || return 1
  [ "$(head -c 2 "${path}")" = "PK" ] || return 1
  local eocd
  eocd="$(tail -c 22 "${path}" 2>/dev/null | od -An -tx1 | tr -d ' \n')"
  case "${eocd}" in
    504b0506*) return 0 ;;
    *) return 1 ;;
  esac
}

pom_is_valid() {
  local path="$1" artifact="$2" version="$3"
  [ -s "${path}" ] || return 1
  grep -q "<artifactId>${artifact}</artifactId>" "${path}" || return 1
  grep -q "<version>${version}</version>" "${path}" || return 1
}

file_is_valid() {
  local path="$1" kind="$2" artifact="$3" version="$4"
  case "${kind}" in
    jar) jar_is_valid "${path}" ;;
    pom) pom_is_valid "${path}" "${artifact}" "${version}" ;;
    *) return 1 ;;
  esac
}

write_checksums() {
  local path="$1"
  sha1_of "${path}" > "${path}.sha1"
  local md5
  md5="$(md5_of "${path}")"
  if [ -n "${md5}" ]; then
    printf '%s\n' "${md5}" > "${path}.md5"
  fi
}

# Downloads one file, resuming a partial transfer instead of starting over.
# The mirror serves 206 for Range requests, so a transfer that dies half way
# through continues where it stopped rather than re-fetching ~180 MB.
download_file() {
  local url="$1" dest="$2" kind="$3" artifact="$4" version="$5"
  local label="${artifact}-${version}.${kind}"
  local tmp="${dest}.partial"
  local attempt=0
  local max_attempts=8
  local status=0

  while [ "${attempt}" -lt "${max_attempts}" ]; do
    attempt=$((attempt + 1))
    status=0
    curl -fL \
      --no-progress-meter \
      --connect-timeout 30 \
      --max-time 1800 \
      --speed-limit 1024 \
      --speed-time 60 \
      -C - \
      -o "${tmp}" \
      "${url}" || status=$?
    if [ "${status}" -eq 0 ] || file_is_valid "${tmp}" "${kind}" "${artifact}" "${version}"; then
      mv "${tmp}" "${dest}"
      return 0
    fi
    # curl exits 33 when the server cannot serve the requested range; drop the
    # partial file so the next attempt starts a fresh transfer.
    if [ "${status}" -eq 33 ]; then
      rm -f "${tmp}"
    fi
    echo "  attempt ${attempt}/${max_attempts} failed for ${label}; retrying" >&2
    sleep $((attempt < 4 ? attempt * 2 : 8))
  done
  rm -f "${tmp}"
  return 1
}

# Fetches one artifact from the first repository that serves it.
fetch_artifact() {
  local artifact="$1" extension="$2"
  local dest_dir="${repo_dir}/io/flutter/${artifact}/${engine_version}"
  local dest="${dest_dir}/${artifact}-${engine_version}.${extension}"
  local label="${artifact}-${engine_version}.${extension}"

  mkdir -p "${dest_dir}"

  if [ -f "${dest}" ] && file_is_valid "${dest}" "${extension}" "${artifact}" "${engine_version}"; then
    write_checksums "${dest}"
    echo "OK  ${label} (cached)"
    return 0
  fi
  rm -f "${dest}"

  local url
  local served=0
  for url in "${repo_urls[@]}"; do
    echo "Downloading ${label} from ${url}"
    if download_file "${url}/io/flutter/${artifact}/${engine_version}/${label}" \
      "${dest}" "${extension}" "${artifact}" "${engine_version}"; then
      served=1
      break
    fi
    echo "  ${url} did not serve ${label}" >&2
  done
  if [ "${served}" -ne 1 ]; then
    echo "prefetch_flutter_engine_android_libs: could not download ${label}." >&2
    return 1
  fi

  if ! file_is_valid "${dest}" "${extension}" "${artifact}" "${engine_version}"; then
    echo "prefetch_flutter_engine_android_libs: ${label} failed verification." >&2
    rm -f "${dest}"
    return 1
  fi

  write_checksums "${dest}"
  echo "OK  ${label}"
}

echo "prefetch_flutter_engine_android_libs: engine ${engine_version} (${flutter_root})"
echo "  repository: ${repo_dir}"
for url in "${repo_urls[@]}"; do
  echo "  source: ${url}"
done

artifacts=()
for mode in "${modes[@]}"; do
  artifacts+=("flutter_embedding_${mode}")
  for abi in "${abis[@]}"; do
    artifacts+=("${abi}_${mode}")
  done
done

# The POMs are a couple of kilobytes each; fetch them first and in order, so
# the (much larger) jars below can run in parallel.
for artifact in "${artifacts[@]}"; do
  fetch_artifact "${artifact}" pom
done

# The jars are ~180 MB each. Gradle used to fetch them in parallel from inside
# the build, so keep them in parallel here: on a link where one connection is
# the bottleneck, four at a time is the difference between minutes and half an
# hour. Each download keeps its own retry and resume state.
max_parallel="${FLUTTER_ENGINE_PREFETCH_PARALLEL:-4}"
pids=()
failures=0

for artifact in "${artifacts[@]}"; do
  fetch_artifact "${artifact}" jar &
  pids+=("$!")
  if [ "${#pids[@]}" -ge "${max_parallel}" ]; then
    pid="${pids[0]}"
    pids=("${pids[@]:1}")
    wait "${pid}" || failures=$((failures + 1))
  fi
done

for pid in ${pids[@]+"${pids[@]}"}; do
  wait "${pid}" || failures=$((failures + 1))
done

if [ "${failures}" -ne 0 ]; then
  echo "prefetch_flutter_engine_android_libs: ${failures} artifact(s) could not be fetched." >&2
  exit 1
fi

echo "prefetch_flutter_engine_android_libs: ${#artifacts[@]} engine artifact(s) ready under ${repo_dir}"
