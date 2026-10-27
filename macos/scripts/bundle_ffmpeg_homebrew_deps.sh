#!/bin/bash
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
CONTENTS_MACOS_DIR="${APP_BUNDLE}/Contents/MacOS"
MAIN_EXECUTABLE="${CONTENTS_MACOS_DIR}/$(basename "${APP_BUNDLE}" .app)"
if [ ! -d "${FRAMEWORKS_DIR}" ]; then
  echo "bundle_ffmpeg_homebrew_deps: missing Frameworks dir in ${APP_BUNDLE}" >&2
  exit 1
fi

# The bundle is only as good as the kegs it was built against, so the build
# machine's Homebrew state belongs in the build log.
if command -v brew >/dev/null 2>&1; then
  echo "bundle_ffmpeg_homebrew_deps: Homebrew keg state on this build machine:"
  brew list --versions 2>/dev/null || true
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

# Every LC_LOAD_DYLIB of $1, across all slices of a fat binary, as otool -L
# prints them: one "<path>:" header per slice, the load commands indented with
# their "(compatibility version ...)" suffix. Install names may contain spaces
# (an app called "Enjoy Player" links @rpath/Enjoy Player.debug.dylib), so the
# name is everything before the suffix, not the first whitespace field.
otool_deps() {
  otool -L "$1" 2>/dev/null | awk '
    /^[[:space:]]/ {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      sub(/[[:space:]]+\(compatibility version.*$/, "", line)
      print line
    }
  '
}

homebrew_deps_for() {
  otool_deps "$1" | grep '^/opt/homebrew/' || true
}

# Bare @rpath dylib references (e.g. @rpath/libbrotlicommon.1.dylib). Framework
# references (@rpath/Foo.framework/...) are skipped: they resolve inside the
# bundle's own frameworks, never to a Homebrew keg.
rpath_dylib_deps_for() {
  otool_deps "$1" | grep -E '^@rpath/[^/]+\.dylib$' || true
}

references_homebrew() {
  homebrew_deps_for "$1" | grep -q .
}

homebrew_formula_for() {
  printf '%s' "$1" | sed -n 's#/opt/homebrew/opt/\([^/]*\)/.*#\1#p; s#/opt/homebrew/Cellar/\([^/]*\)/.*#\1#p'
}

resolve_homebrew_dep() {
  dep="$1"
  if [ -f "${dep}" ]; then
    printf '%s' "${dep}"
    return 0
  fi

  case "${dep}" in
    /opt/homebrew/*)
      base="$(basename "${dep}")"
      if command -v brew >/dev/null 2>&1; then
        # The reference names the formula it came from
        # (/opt/homebrew/opt/<formula>/... or /opt/homebrew/Cellar/<formula>/...),
        # so ask that one keg first instead of walking every installed formula.
        formula="$(homebrew_formula_for "${dep}")"
        if [ -n "${formula}" ]; then
          prefix="$(brew --prefix "${formula}" 2>/dev/null || true)"
          candidate="${prefix}/lib/${base}"
          if [ -f "${candidate}" ]; then
            printf '%s' "${candidate}"
            return 0
          fi
        fi
        # Some Homebrew-built libraries use a relocatable install name such as
        # /opt/homebrew/*/libssl.3.dylib. Resolve it to the active keg without
        # baking the release machine's Cellar version into the app.
        while IFS= read -r candidate_formula; do
          [ -n "${candidate_formula}" ] || continue
          prefix="$(brew --prefix "${candidate_formula}" 2>/dev/null || true)"
          candidate="${prefix}/lib/${base}"
          if [ -f "${candidate}" ]; then
            printf '%s' "${candidate}"
            return 0
          fi
        done <<EOF
$(brew list --formula 2>/dev/null || true)
EOF
      fi
      ;;
  esac

  return 1
}

# Resolves an @rpath/<name> reference to the file that has to be bundled.
# $1: the reference, $2: directory of the keg the referencer came from.
resolve_rpath_dep() {
  reference="$1"
  keg_dir="$2"
  name="${reference#@rpath/}"
  [ -n "${name}" ] || return 1

  if [ -n "${keg_dir}" ]; then
    for candidate_dir in "${keg_dir}" "${keg_dir}/../lib"; do
      if [ -f "${candidate_dir}/${name}" ]; then
        printf '%s' "${candidate_dir}/${name}"
        return 0
      fi
    done
  fi

  if command -v brew >/dev/null 2>&1; then
    while IFS= read -r formula; do
      [ -n "${formula}" ] || continue
      prefix="$(brew --prefix "${formula}" 2>/dev/null || true)"
      candidate="${prefix}/lib/${name}"
      if [ -f "${candidate}" ]; then
        printf '%s' "${candidate}"
        return 0
      fi
    done <<EOF
$(brew list --formula 2>/dev/null || true)
EOF
  fi

  return 1
}

# LC_RPATH entries of $1, across all slices. Cached per file: otool -l prints
# every load command of a fat binary, and the closure check asks for the same
# file once per dependency.
macho_rpaths() {
  cache="${RPATH_CACHE_DIR}/$(printf '%s' "$1" | tr '/' '_')"
  if [ ! -f "${cache}" ]; then
    otool -l "$1" 2>/dev/null | awk '
      /^[[:space:]]*path[[:space:]]/ {
        line = $0
        sub(/^[[:space:]]*path[[:space:]]+/, "", line)
        sub(/[[:space:]]*\(offset.*$/, "", line)
        print line
      }
    ' >"${cache}"
  fi
  cat "${cache}"
}

# Load commands dyld must actually be able to satisfy: LC_LOAD_DYLIB,
# LC_LOAD_UPWARD_DYLIB and LC_REEXPORT_DYLIB of $1, across all slices. Weak
# links are skipped (a missing weak library is legal at runtime — Xcode's
# Swift back-deployment libs are weak and copied by a later build phase), and
# so is LC_ID_DYLIB (otool -L prints the install id as a dependency-looking
# line, but dyld never resolves it).
macho_strong_deps() {
  otool -l "$1" 2>/dev/null | awk '
    /^Load command/ { current = "" }
    /^[[:space:]]*cmd (LC_LOAD_DYLIB|LC_LOAD_UPWARD_DYLIB|LC_REEXPORT_DYLIB)[[:space:]]*$/ { current = "load" }
    current == "load" && /^[[:space:]]*name[[:space:]]/ {
      line = $0
      sub(/^[[:space:]]*name[[:space:]]+/, "", line)
      sub(/[[:space:]]*\(offset.*$/, "", line)
      print line
      current = ""
    }
  '
}

MACHO_LIST="$(mktemp)"
RPATH_CACHE_DIR="$(mktemp -d)"
WORKLIST="$(mktemp)"
BUNDLED="$(mktemp)"
DEP_REWRITES="$(mktemp)"
: >"${MACHO_LIST}"
: >"${WORKLIST}"
: >"${BUNDLED}"
: >"${DEP_REWRITES}"

cleanup() {
  rm -f "${MACHO_LIST}" "${WORKLIST}" "${BUNDLED}" "${DEP_REWRITES}"
  rm -rf "${RPATH_CACHE_DIR}"
}
trap cleanup EXIT

while IFS= read -r -d '' f; do
  if is_macho "$f" && references_homebrew "$f"; then
    printf '%s\n' "$f"
  fi
done < <(find "${APP_BUNDLE}/Contents" -type f -print0 2>/dev/null) >"${MACHO_LIST}"

while read -r bin; do
  [ -n "${bin}" ] || continue
  while read -r dep; do
    [ -n "${dep}" ] || continue
    printf 'brew\t%s\t\n' "${dep}" >>"${WORKLIST}"
  done <<EOF
$(homebrew_deps_for "${bin}")
EOF
done <"${MACHO_LIST}"

while :; do
  sort -u "${WORKLIST}" -o "${WORKLIST}"
  [ -s "${WORKLIST}" ] || break
  PENDING="$(mktemp)"
  cp "${WORKLIST}" "${PENDING}"
  : >"${WORKLIST}"
  while IFS="$(printf '\t')" read -r kind reference keg_dir; do
    [ -n "${reference}" ] || continue
    case "${kind}" in
      brew) src="$(resolve_homebrew_dep "${reference}" || true)" ;;
      rpath)
        name="${reference#@rpath/}"
        if [ -f "${FRAMEWORKS_DIR}/${name}" ] || [ -f "${CONTENTS_MACOS_DIR}/${name}" ]; then
          continue
        fi
        src="$(resolve_rpath_dep "${reference}" "${keg_dir}" || true)"
        ;;
      *) continue ;;
    esac
    if [ -z "${src}" ]; then
      if [ "${kind}" = "rpath" ]; then
        echo "bundle_ffmpeg_homebrew_deps: cannot resolve ${reference}" >&2
        continue
      fi
      echo "bundle_ffmpeg_homebrew_deps: cannot resolve ${reference}" >&2
      echo "Install Homebrew deps: brew bundle install --file=macos/Brewfile" >&2
      exit 1
    fi
    if grep -Fxq "${src}" "${BUNDLED}" 2>/dev/null; then
      printf '%s\t%s\n' "${reference}" "${src}" >>"${DEP_REWRITES}"
      continue
    fi
    echo "${src}" >>"${BUNDLED}"
    base="$(basename "${src}")"
    dest="${FRAMEWORKS_DIR}/${base}"
    if [ ! -f "${dest}" ]; then
      cp -f "${src}" "${dest}"
      chmod 755 "${dest}"
      install_name_tool -id "@rpath/${base}" "${dest}" >/dev/null 2>&1 || true
      # Homebrew's relocatable kegs point their own dependencies at
      # @rpath/<name>. Without @loader_path on the copy, that name resolves
      # outside Contents/Frameworks and dyld aborts at launch.
      install_name_tool -add_rpath "@loader_path" "${dest}" >/dev/null 2>&1 || true
    fi
    printf '%s\t%s\n' "${reference}" "${src}" >>"${DEP_REWRITES}"
    while read -r dep; do
      [ -n "${dep}" ] || continue
      printf 'brew\t%s\t\n' "${dep}" >>"${WORKLIST}"
    done <<EOF
$(homebrew_deps_for "${dest}")
EOF
    while read -r dep; do
      [ -n "${dep}" ] || continue
      printf 'rpath\t%s\t%s\n' "${dep}" "$(dirname "${src}")" >>"${WORKLIST}"
    done <<EOF
$(rpath_dylib_deps_for "${dest}")
EOF
  done <"${PENDING}"
  rm -f "${PENDING}"
done

BUNDLED_COUNT="$(wc -l <"${BUNDLED}" | tr -d ' ')"

if [ "${BUNDLED_COUNT}" -gt 0 ]; then
  rewrite_homebrew_deps() {
    bin="$1"
    while IFS="$(printf '\t')" read -r reference src; do
      [ -n "${reference}" ] || continue
      base="$(basename "${src}")"
      [ "${reference}" = "@rpath/${base}" ] && continue
      install_name_tool -change "${reference}" "@rpath/${base}" "${bin}" 2>/dev/null || true
    done <"${DEP_REWRITES}"
  }

  while read -r bin; do
    [ -n "${bin}" ] || continue
    rewrite_homebrew_deps "${bin}"
  done <"${MACHO_LIST}"

  # Rewrite dependencies of copied dylibs too (for example libssl -> libcrypto).
  while read -r src; do
    [ -n "${src}" ] || continue
    rewrite_homebrew_deps "${FRAMEWORKS_DIR}/$(basename "${src}")"
  done <"${BUNDLED}"

  while read -r bin; do
    [ -n "${bin}" ] || continue
    if references_homebrew "${bin}"; then
      echo "bundle_ffmpeg_homebrew_deps: unresolved Homebrew load path in ${bin}" >&2
      homebrew_deps_for "${bin}" >&2
      exit 1
    fi
  done <"${MACHO_LIST}"
  while read -r src; do
    [ -n "${src}" ] || continue
    bin="${FRAMEWORKS_DIR}/$(basename "${src}")"
    if references_homebrew "${bin}"; then
      echo "bundle_ffmpeg_homebrew_deps: unresolved Homebrew load path in ${bin}" >&2
      homebrew_deps_for "${bin}" >&2
      exit 1
    fi
  done <"${BUNDLED}"
fi

# Closure check: every load command of every Mach-O in the bundle has to point
# at a system library, the dyld shared cache, or a file that is actually there.
# A dangling @rpath reference only surfaces as a launch crash on the user's
# machine, long after the release pipeline went green.
bundle_path_exists() {
  candidate="$1"
  [ -e "${candidate}" ] && return 0
  case "${candidate}" in
    *.framework/*)
      framework_dir="${candidate%%.framework/*}.framework"
      [ -d "${framework_dir}" ] && return 0
      ;;
  esac
  return 1
}

# @rpath resolution as dyld performs it: the loading image's LC_RPATH entries
# followed by the main executable's. The dyld shared cache is not visible to
# the shell, so exactly one cache-served family is whitelisted by name:
# /usr/lib/swift/libswift*.dylib, the OS Swift runtime the toolchain's
# back-deployment libraries link through the executable's /usr/lib/swift
# rpath. Everything else has to exist as a file.
resolve_rpath_against() {
  owner="$1"
  name="$2"
  owner_dir="$(dirname "${owner}")"
  while read -r rp; do
    [ -n "${rp}" ] || continue
    case "${rp}" in
      @loader_path*) candidate="${owner_dir}${rp#@loader_path}" ;;
      @executable_path*) candidate="${CONTENTS_MACOS_DIR}${rp#@executable_path}" ;;
      /*) candidate="${rp}" ;;
      *) continue ;;
    esac
    probe="${candidate}/${name}"
    case "${probe}" in
      /usr/lib/swift/libswift*.dylib) return 0 ;;
    esac
    bundle_path_exists "${probe}" && return 0
  done < <(macho_rpaths "${owner}")
  return 1
}

resolve_bundle_dep() {
  loader="$1"
  dep="$2"
  loader_dir="$(dirname "${loader}")"
  case "${dep}" in
    /usr/lib/* | /System/* | /usr/libexec/*)
      return 0
      ;;
    @rpath/*)
      name="${dep#@rpath/}"
      case "${name}" in
        *.framework/*)
          framework="${name%%/*}"
          [ -d "${FRAMEWORKS_DIR}/${framework}" ] && return 0
          return 1
          ;;
      esac
      resolve_rpath_against "${loader}" "${name}" && return 0
      if [ -f "${MAIN_EXECUTABLE}" ]; then
        resolve_rpath_against "${MAIN_EXECUTABLE}" "${name}" && return 0
      fi
      bundle_path_exists "${FRAMEWORKS_DIR}/${name}" && return 0
      bundle_path_exists "${CONTENTS_MACOS_DIR}/${name}" && return 0
      return 1
      ;;
    @loader_path/*)
      bundle_path_exists "${loader_dir}/${dep#@loader_path/}"
      return $?
      ;;
    @executable_path/*)
      bundle_path_exists "${CONTENTS_MACOS_DIR}/${dep#@executable_path/}"
      return $?
      ;;
    /opt/homebrew/* | /usr/local/*)
      return 1
      ;;
    /*)
      bundle_path_exists "${dep}"
      return $?
      ;;
  esac
  return 1
}

closure_failures=0
while IFS= read -r -d '' f; do
  is_macho "$f" || continue
  while read -r dep; do
    [ -n "${dep}" ] || continue
    if ! resolve_bundle_dep "${f}" "${dep}"; then
      echo "bundle_ffmpeg_homebrew_deps: unresolved dependency ${dep} in ${f#"${APP_BUNDLE}/"}" >&2
      closure_failures=$((closure_failures + 1))
    fi
  done <<EOF
$(macho_strong_deps "${f}")
EOF
done < <(find "${APP_BUNDLE}/Contents" -type f -print0 2>/dev/null)

if [ "${closure_failures}" -gt 0 ]; then
  echo "bundle_ffmpeg_homebrew_deps: ${closure_failures} unresolved dylib dependency/dependencies in ${APP_BUNDLE}" >&2
  exit 1
fi

if [ "${BUNDLED_COUNT}" -gt 0 ]; then
  while read -r src; do
    [ -n "${src}" ] || continue
    echo "bundle_ffmpeg_homebrew_deps: ${src} -> ${FRAMEWORKS_DIR}/$(basename "${src}")"
  done <"${BUNDLED}"
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

  EXECUTABLE="${MAIN_EXECUTABLE}"
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

