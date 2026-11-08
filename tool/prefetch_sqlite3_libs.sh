#!/usr/bin/env bash
# Pre-fetch package:sqlite3 native libraries into the dart build hook shared
# cache, so the build hook reuses them instead of downloading from github.com
# at every build.
#
# Why:
#   package:sqlite3 3.x uses a Dart hooks build hook that downloads its
#   precompiled library for the target OS/ABI from
#   github.com/simolus3/sqlite3.dart/releases at every `flutter build` and
#   `flutter test`. The download uses Dart HttpClient with no retries and a
#   single SYN — any transient network blip, GitHub rate-limiting, or a network
#   that drops the TLS handshake makes the connection fail and the whole build
#   dies with "Building native assets failed" (the self-hosted runners also pin
#   HTTP/1.1 for github.com for the same reason).
#
#   Two more failure modes showed up in practice:
#     * github.com/.../releases/download/<tag>/<asset> answers 504 at
#       GitHub's own edge for some assets of a fresh release, while the
#       api.github.com release-asset endpoint serves the same bytes.
#     * a download that returns the wrong bytes (truncated or proxied body)
#       fails the hook's SHA256 check, and the hook has no retry either.
#   So every asset is fetched with curl (retries + SHA256 verification) and,
#   when the browser download URL fails, falls back to the GitHub API asset
#   endpoint. A failing asset never stops the remaining ones: the report at
#   the end names every asset that could not be prepared.
#
# What:
#   The hook downloads into
#     .dart_tool/hooks_runner/shared/sqlite3/build/download-<hash8>/<libname>
#   where <hash8> is the first 8 hex chars of the library's expected SHA256
#   (one directory per OS/ABI) and <libname> is libsqlite3.so, libsqlite3.dylib
#   or sqlite3.dll depending on the target OS. On the next hook run the file
#   there is reused when its SHA256 matches the pinned value, so the GitHub
#   fetch is skipped entirely.
#
#   The release tag and every expected SHA256 are read from the installed
#   package:sqlite3 itself (its asset_hashes.dart), so a sqlite3 version bump
#   cannot leave this script pointing at a stale release the way a hand-copied
#   hash list does. Curl retries and verifies SHA256, so a partial or tampered
#   download fails fast instead of poisoning the cache.
#
#   Only the architectures a build can actually use are fetched: the Linux and
#   Windows builds are single-architecture and use the host's, the macOS app
#   ships a universal binary and keeps both, the iOS device slice keeps arm64,
#   and Android keeps every ABI the APK bundles.
#
# Usage:
#   bash tool/prefetch_sqlite3_libs.sh                 # android (default)
#   bash tool/prefetch_sqlite3_libs.sh macos           # macOS (arm64 + x64)
#   bash tool/prefetch_sqlite3_libs.sh macos ios       # several platforms
#   SQLITE3_BASE_URL=https://mirror.example/sqlite3-3.7.0 \
#     bash tool/prefetch_sqlite3_libs.sh macos
#   SQLITE3_API_ROOT= \
#     bash tool/prefetch_sqlite3_libs.sh macos          # no API fallback
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "${root}"

usage() {
  echo "Usage: $0 [platform ...]" >&2
  echo "  platforms: android linux macos ios ios_sim windows (default: android)" >&2
}

platforms=()
for arg in "$@"; do
  case "${arg}" in
    android | linux | macos | ios | ios_sim | windows) platforms+=("${arg}") ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown platform: ${arg}" >&2
      usage
      exit 2
      ;;
  esac
done
if [ "${#platforms[@]}" -eq 0 ]; then
  platforms=(android)
fi

# The hook's shared output directory is keyed by package name, not OS/ABI, so
# every platform lands under the same tree.
cache_dir="${root}/.dart_tool/hooks_runner/shared/sqlite3/build"

repo_slug="simolus3/sqlite3.dart"
api_root="${SQLITE3_API_ROOT-https://api.github.com}"

# An explicit token raises the API rate limit; the asset bytes are public, so
# the fallback also works anonymously.
auth_args=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
  auth_args=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" 2>/dev/null | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
  else
    echo "Need sha256sum or shasum on PATH." >&2
    exit 1
  fi
}

lib_filename_for() {
  case "$1" in
    android | linux) echo "libsqlite3.so" ;;
    macos | ios | ios_sim) echo "libsqlite3.dylib" ;;
    windows) echo "sqlite3.dll" ;;
  esac
}

# The architecture the build links against, or an empty string when every
# architecture of the platform can be used.
arches_for() {
  case "$1" in
    linux | windows)
      case "$(uname -m 2>/dev/null || echo unknown)" in
        x86_64 | amd64) echo "x64" ;;
        aarch64 | arm64) echo "arm64" ;;
        armv7l | armv7 | armv8l) echo "arm" ;;
        i386 | i686) echo "ia32" ;;
        *) echo "" ;;
      esac
      ;;
    ios | macos | ios_sim | android) echo "" ;;
    *) echo "" ;;
  esac
}

# Matches the SQLite github release asset for one target OS at the start of a
# "<name> <sha256>" line. The `[^.]+` arch segment keeps libsqlite3mc /
# libsqlcipher (different LibraryType) out, and the `\.ios\.` in the ios
# pattern never matches `...ios_sim...` because the char after `ios` is `_`.
asset_pattern_for() {
  local platform="$1" arch="$2"
  case "${platform}" in
    android) echo '^libsqlite3\.[^.]+\.android\.so ' ;;
    linux) echo "^libsqlite3\\.${arch}\\.linux\\.so " ;;
    macos) echo '^libsqlite3\.[^.]+\.macos\.dylib ' ;;
    ios) echo '^libsqlite3\.[^.]+\.ios\.dylib ' ;;
    ios_sim) echo '^libsqlite3\.[^.]+\.ios_sim\.dylib ' ;;
    windows) echo "^sqlite3\\.${arch}\\.windows\\.dll " ;;
  esac
}

resolve_sqlite3_root() {
  local uri version candidate
  if [ -f .dart_tool/package_config.json ]; then
    uri="$(awk -v RS='}' '
      /"name"[[:space:]]*:[[:space:]]*"sqlite3"/ {
        if (match($0, /"rootUri"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
          s = substr($0, RSTART, RLENGTH)
          sub(/^"rootUri"[[:space:]]*:[[:space:]]*"/, "", s)
          sub(/"$/, "", s)
          print s
          exit
        }
      }
    ' .dart_tool/package_config.json)"
    if [ -n "${uri}" ]; then
      printf '%s\n' "${uri#file://}"
      return 0
    fi
  fi

  version="$(awk '
    /^  sqlite3:/ { found = 1 }
    found && /^    version:/ { gsub(/"/, "", $2); print $2; exit }
  ' pubspec.lock 2>/dev/null || true)"
  if [ -z "${version}" ]; then
    echo "prefetch_sqlite3_libs: cannot locate package:sqlite3." >&2
    echo "  No .dart_tool/package_config.json and no version in pubspec.lock;" \
      "run 'flutter pub get' first." >&2
    exit 1
  fi
  for candidate in \
    "${PUB_CACHE:-${HOME}/.pub-cache}/hosted/pub.dev/sqlite3-${version}" \
    "${HOME}/.pub-cache/hosted/pub.dev/sqlite3-${version}"; do
    if [ -f "${candidate}/lib/src/hook/asset_hashes.dart" ]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  echo "prefetch_sqlite3_libs: sqlite3-${version} not found in the pub cache." >&2
  exit 1
}

pkg_root="$(resolve_sqlite3_root)"
hashes_file="${pkg_root}/lib/src/hook/asset_hashes.dart"
if [ ! -f "${hashes_file}" ]; then
  echo "prefetch_sqlite3_libs: ${hashes_file} not found." >&2
  exit 1
fi

release_tag="$(sed -n "s/^const String? releaseTag = '\([^']*\)';.*/\1/p" \
  "${hashes_file}" | head -n 1)"
if [ -z "${release_tag}" ]; then
  echo "prefetch_sqlite3_libs: no releaseTag in ${hashes_file}." >&2
  echo "  package:sqlite3 must be built with its release asset hashes." >&2
  exit 1
fi

base_url="${SQLITE3_BASE_URL:-https://github.com/${repo_slug}/releases/download/${release_tag}}"

echo "prefetch_sqlite3_libs: ${release_tag} (${pkg_root})"

release_json=""
release_json_tmp=""

cleanup_release_json() {
  if [ -n "${release_json_tmp}" ]; then
    rm -f "${release_json_tmp}"
  fi
}
trap cleanup_release_json EXIT

# The release manifest is fetched once and reused for every fallback lookup.
fetch_release_json() {
  [ -n "${api_root}" ] || return 1
  if [ -n "${release_json}" ]; then
    return 0
  fi
  local tmp
  tmp="$(mktemp -t sqlite3-release-XXXXXX)"
  if ! curl -fsSL \
    --retry 2 \
    --retry-delay 2 \
    --retry-all-errors \
    --connect-timeout 30 \
    --max-time 120 \
    ${auth_args[@]+"${auth_args[@]}"} \
    -o "${tmp}" \
    "${api_root}/repos/${repo_slug}/releases/tags/${release_tag}"; then
    rm -f "${tmp}"
    return 1
  fi
  release_json="${tmp}"
  release_json_tmp="${tmp}"
}

# Maps a release asset name to its numeric asset id. The REST manifest lists
# "id" before "name" inside every asset object, so the last id seen when the
# wanted name shows up is that asset's id. jq is not available on every
# runner, so the manifest is parsed with awk.
api_asset_id() {
  local name="$1"
  fetch_release_json || return 1
  awk -v want="${name}" '
    index($0, "\"assets\": [") > 0 { inassets = 1 }
    !inassets { next }
    match($0, /"id": [0-9]+/) { id = substr($0, RSTART + 6, RLENGTH - 6) }
    index($0, "\"name\": \"" want "\"") > 0 { if (id != "") { print id; exit } }
  ' "${release_json}"
}

download_from_api() {
  local name="$1" dest="$2" id
  id="$(api_asset_id "${name}" | head -n 1)"
  if [ -z "${id}" ]; then
    return 1
  fi
  curl -fL \
    --retry 2 \
    --retry-delay 2 \
    --retry-all-errors \
    --connect-timeout 30 \
    --max-time 600 \
    ${auth_args[@]+"${auth_args[@]}"} \
    -H "Accept: application/octet-stream" \
    -o "${dest}" \
    "${api_root}/repos/${repo_slug}/releases/assets/${id}"
}

download_one() {
  local name="$1" sha="$2" dest_name="$3"
  local dest_dir="${cache_dir}/download-${sha:0:8}"
  local dest="${dest_dir}/${dest_name}"
  local tmp="${dest}.partial" actual attempt
  mkdir -p "${dest_dir}"

  if [ -f "${dest}" ] && [ "$(sha256_of "${dest}")" = "${sha}" ]; then
    echo "OK  ${name} (cached, sha256 verified)"
    return 0
  fi

  # Drop empty / partial leftovers so curl doesn't trip "Failed writing body".
  rm -f "${dest}" "${tmp}"
  for attempt in 1 2 3; do
    if curl -fL \
      --retry 2 \
      --retry-delay 2 \
      --retry-all-errors \
      --connect-timeout 30 \
      --max-time 600 \
      -o "${tmp}" \
      "${base_url}/${name}"; then
      actual="$(sha256_of "${tmp}" || true)"
      if [ "${actual}" = "${sha}" ]; then
        mv "${tmp}" "${dest}"
        echo "OK  ${name}"
        return 0
      fi
      echo "SHA256 mismatch for ${name} (attempt ${attempt})" >&2
    else
      echo "Download failed for ${name} (attempt ${attempt})" >&2
    fi
    rm -f "${tmp}"

    if download_from_api "${name}" "${tmp}"; then
      actual="$(sha256_of "${tmp}" || true)"
      if [ "${actual}" = "${sha}" ]; then
        mv "${tmp}" "${dest}"
        echo "OK  ${name} (via the GitHub API asset endpoint)"
        return 0
      fi
      echo "SHA256 mismatch for ${name} via the API (attempt ${attempt})" >&2
    fi
    rm -f "${tmp}"
    sleep 2
  done

  echo "prefetch_sqlite3_libs: ${name} could not be fetched." >&2
  return 1
}

total=0
failed=""
for platform in "${platforms[@]}"; do
  dest_name="$(lib_filename_for "${platform}")"
  arch="$(arches_for "${platform}")"
  if [ -z "${arch}" ]; then
    arch='[^.]+'
  fi
  pattern="$(asset_pattern_for "${platform}" "${arch}")"
  found=0
  while IFS= read -r entry; do
    [ -n "${entry}" ] || continue
    name="${entry%% *}"
    sha="${entry##* }"
    found=$((found + 1))
    total=$((total + 1))
    if ! download_one "${name}" "${sha}" "${dest_name}"; then
      failed="${failed} ${name}"
    fi
  done < <(
    awk -F"'" '
      /^[[:space:]]/ {
        name = $2; sha = $4
        if (length(sha) == 64 && sha ~ /^[0-9a-f]+$/) print name, sha
      }' "${hashes_file}" | grep -E "${pattern}"
  )
  if [ "${found}" -eq 0 ]; then
    echo "prefetch_sqlite3_libs: no assets matched platform '${platform}'." >&2
    echo "  package:sqlite3 may have changed its release layout." >&2
    exit 1
  fi
done

if [ -n "${failed}" ]; then
  echo "prefetch_sqlite3_libs: could not fetch:${failed}" >&2
  exit 1
fi

echo "prefetch_sqlite3_libs: ${total} sqlite3 lib(s) ready under ${cache_dir}"
