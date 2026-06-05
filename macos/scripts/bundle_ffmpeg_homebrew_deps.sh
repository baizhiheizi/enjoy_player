#!/bin/sh
# Bundles Homebrew dylibs required by ffmpeg_kit_flutter_new prebuilt macOS frameworks.
# Those binaries were linked against /opt/homebrew/opt/* at build time; without this
# step (or the same libs installed on the machine), dyld fails at launch.
#
# Also re-signs embedded FFmpegKit / media_kit prebuilt frameworks on Release so they
# share the app signing team (avoids dyld "different Team IDs").
set -eu

APP_BUNDLE="${1:-}"
if [ -z "${APP_BUNDLE}" ] || [ ! -d "${APP_BUNDLE}" ]; then
  echo "usage: $0 <path/to/Enjoy Player.app>" >&2
  exit 1
fi

FRAMEWORKS_DIR="${APP_BUNDLE}/Contents/Frameworks"
if [ ! -d "${FRAMEWORKS_DIR}" ]; then
  echo "bundle_ffmpeg_homebrew_deps: missing Frameworks dir in ${APP_BUNDLE}" >&2
  exit 1
fi

is_macho() {
  file "$1" 2>/dev/null | grep -q 'Mach-O'
}

resolve_sign_identity() {
  id="${EXPANDED_CODE_SIGN_IDENTITY:-}"
  if [ -n "${id}" ] && [ "${id}" != "-" ]; then
    printf '%s' "${id}"
    return
  fi
  id="${CODE_SIGN_IDENTITY:-}"
  if [ -n "${id}" ] && [ "${id}" != "-" ]; then
    printf '%s' "${id}"
    return
  fi
  id="$(security find-identity -v -p codesigning 2>/dev/null \
    | awk -F'"' '/Developer ID Application/ { print $2; exit }')"
  if [ -n "${id}" ]; then
    printf '%s' "${id}"
    return
  fi
  id="$(security find-identity -v -p codesigning 2>/dev/null \
    | awk -F'"' '/Apple Development/ { print $2; exit }')"
  if [ -n "${id}" ]; then
    printf '%s' "${id}"
  fi
}

homebrew_deps_for() {
  otool -L "$1" 2>/dev/null | awk '/\/opt\/homebrew\// { print $1 }'
}

references_homebrew() {
  homebrew_deps_for "$1" | grep -q .
}

MACHO_LIST="$(mktemp)"
DEPS="$(mktemp)"
BUNDLED="$(mktemp)"
: >"${MACHO_LIST}"
: >"${DEPS}"
: >"${BUNDLED}"

find "${APP_BUNDLE}/Contents" -type f 2>/dev/null | while read -r f; do
  if is_macho "$f" && references_homebrew "$f"; then
    echo "$f"
  fi
done >"${MACHO_LIST}"

while read -r bin; do
  [ -n "${bin}" ] || continue
  homebrew_deps_for "${bin}" >>"${DEPS}" || true
done <"${MACHO_LIST}"

sort -u "${DEPS}" -o "${DEPS}"

bundle_one() {
  src="$1"
  base="$(basename "${src}")"
  dest="${FRAMEWORKS_DIR}/${base}"

  if [ ! -f "${src}" ]; then
    formula="$(echo "${src}" | sed -n 's#/opt/homebrew/opt/\([^/]*\)/.*#\1#p')"
    echo "bundle_ffmpeg_homebrew_deps: missing ${src}" >&2
    if [ -n "${formula}" ]; then
      echo "Install Homebrew deps: brew bundle install --file=macos/Brewfile" >&2
      echo "  (or: brew install ${formula})" >&2
    fi
    exit 1
  fi

  if grep -Fxq "${src}" "${BUNDLED}" 2>/dev/null; then
    return 0
  fi

  if [ ! -f "${dest}" ]; then
    cp -f "${src}" "${dest}"
    chmod 755 "${dest}"
    install_name_tool -id "@rpath/${base}" "${dest}" >/dev/null 2>&1 || true
  fi
  echo "${src}" >>"${BUNDLED}"
  homebrew_deps_for "${dest}" >>"${DEPS}" || true
}

while :; do
  ADDED=0
  PENDING="$(mktemp)"
  cp "${DEPS}" "${PENDING}"
  while read -r dep; do
    [ -n "${dep}" ] || continue
    if grep -Fxq "${dep}" "${BUNDLED}" 2>/dev/null; then
      continue
    fi
    ADDED=1
    bundle_one "${dep}"
  done <"${PENDING}"
  rm -f "${PENDING}"
  sort -u "${DEPS}" -o "${DEPS}"
  if [ "${ADDED}" -eq 0 ]; then
    break
  fi
done

BUNDLED_COUNT="$(wc -l <"${BUNDLED}" | tr -d ' ')"

if [ "${BUNDLED_COUNT}" -gt 0 ]; then
  while read -r bin; do
    [ -n "${bin}" ] || continue
    while read -r src; do
      [ -n "${src}" ] || continue
      base="$(basename "${src}")"
      install_name_tool -change "${src}" "@rpath/${base}" "${bin}" 2>/dev/null || true
    done <"${BUNDLED}"
  done <"${MACHO_LIST}"
fi

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
MACOS_DIR="$(dirname "${SCRIPT_DIR}")"
if [ "${CONFIGURATION:-Debug}" = "Release" ] || [ "${ENABLE_HARDENED_RUNTIME:-}" = "YES" ]; then
  ENTITLEMENTS="${MACOS_DIR}/Runner/Release.entitlements"
  CODESIGN_EXTRA="--options runtime --timestamp"
  RESIGN_ALL_FRAMEWORKS=1
else
  ENTITLEMENTS="${MACOS_DIR}/Runner/DebugProfile.entitlements"
  CODESIGN_EXTRA="--timestamp=none"
  RESIGN_ALL_FRAMEWORKS=0
fi

if [ "${CODE_SIGNING_ALLOWED:-YES}" = "NO" ]; then
  if [ "${BUNDLED_COUNT}" -gt 0 ]; then
    echo "bundle_ffmpeg_homebrew_deps: bundled ${BUNDLED_COUNT} Homebrew dylib(s); skipping codesign (unsigned build)"
  else
    echo "bundle_ffmpeg_homebrew_deps: skipping codesign (unsigned build)"
  fi
  rm -f "${MACHO_LIST}" "${DEPS}" "${BUNDLED}"
  exit 0
fi

SIGN_IDENTITY="$(resolve_sign_identity)"
if [ -z "${SIGN_IDENTITY}" ]; then
  echo "bundle_ffmpeg_homebrew_deps: no code signing identity found" >&2
  exit 1
fi

sign_path() {
  target="$1"
  use_entitlements="${2:-0}"
  if [ "${use_entitlements}" -eq 1 ]; then
    # shellcheck disable=SC2086
    codesign --force --sign "${SIGN_IDENTITY}" ${CODESIGN_EXTRA} \
      --entitlements "${ENTITLEMENTS}" \
      "${target}"
  else
    # shellcheck disable=SC2086
    codesign --force --sign "${SIGN_IDENTITY}" ${CODESIGN_EXTRA} "${target}"
  fi
}

if [ "${BUNDLED_COUNT}" -gt 0 ]; then
  while read -r src; do
    [ -n "${src}" ] || continue
    sign_path "${FRAMEWORKS_DIR}/$(basename "${src}")"
  done <"${BUNDLED}"

  while read -r bin; do
    [ -n "${bin}" ] || continue
    sign_path "${bin}"
  done <"${MACHO_LIST}"
fi

if [ "${RESIGN_ALL_FRAMEWORKS}" -eq 1 ]; then
  while IFS= read -r f; do
    case "${f}" in
      *.debug.dylib) continue ;;
    esac
    if is_macho "${f}"; then
      sign_path "${f}"
    fi
  done <<EOF
$(find "${FRAMEWORKS_DIR}" -type f 2>/dev/null)
EOF

  while IFS= read -r fw; do
    sign_path "${fw}"
  done <<EOF
$(find "${FRAMEWORKS_DIR}" -maxdepth 1 -name '*.framework' -type d 2>/dev/null)
EOF

  EXECUTABLE="${APP_BUNDLE}/Contents/MacOS/$(basename "${APP_BUNDLE}" .app)"
  if [ -f "${EXECUTABLE}" ]; then
    sign_path "${EXECUTABLE}" 1
  fi

  sign_path "${APP_BUNDLE}" 1
fi

if [ "${BUNDLED_COUNT}" -gt 0 ]; then
  echo "bundle_ffmpeg_homebrew_deps: bundled ${BUNDLED_COUNT} Homebrew dylib(s) into ${FRAMEWORKS_DIR}"
elif [ "${RESIGN_ALL_FRAMEWORKS}" -eq 1 ]; then
  echo "bundle_ffmpeg_homebrew_deps: re-signed embedded frameworks in ${FRAMEWORKS_DIR}"
fi

rm -f "${MACHO_LIST}" "${DEPS}" "${BUNDLED}"
