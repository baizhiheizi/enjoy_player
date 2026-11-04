#!/bin/bash
set -euo pipefail

# Builds the Homebrew dylibs referenced by the vendored FFmpegKit frameworks
# (packages/ffmpeg_kit_flutter_new) with the app's minimum deployment target,
# into a cached prefix that macos/scripts/bundle_ffmpeg_homebrew_deps.sh
# resolves before /opt/homebrew kegs.
#
# Why not the kegs directly: Homebrew arm64 bottles are built on the current
# bottle-tag OS, so their LC_BUILD_VERSION minos rises with every Homebrew
# support-window shift (26.0 today) and FreeType >= 2.15 bottles link
# /usr/lib/libhvf.dylib, which does not exist before macOS 26. Bundling keg
# copies therefore crashes dyld at launch on every older macOS (#1187).
#
# Sources are pinned by URL + sha256; each package builds once into
# .built/<name> markers, so re-runs resume and CI/dev builds are no-ops
# unless a pin changes. Run with --force to rebuild from scratch.
#
# Build tools (cmake / meson / ninja / pkg-config) come from macos/Brewfile;
# they execute on the build machine only, so their own deployment target is
# irrelevant.

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
# shellcheck source=compat_dylibs_env.sh
source "${SCRIPT_DIR}/compat_dylibs_env.sh"

PREFIX="$(compat_dylibs_prefix)"
WORKDIR="${PREFIX}/src"
BUILT_DIR="${PREFIX}/.built"
MIN_V="${COMPAT_MIN_MACOS_VERSION}"

usage() {
  sed -n '2,20p' "$0"
  exit 1
}

FORCE=0
for arg in "$@"; do
  case "${arg}" in
    --force) FORCE=1 ;;
    -h | --help) usage ;;
    *) echo "Unknown option: ${arg}" >&2; usage ;;
  esac
done

export CC=clang
export CXX=clang++
export MACOSX_DEPLOYMENT_TARGET="${MIN_V}"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig"
# -L makes bare -l flags (-liconv, -lz) resolve inside the prefix — the same
# self-consistent closure the bundle ships — instead of whatever the SDK's
# stubs provide.
export LDFLAGS="-L${PREFIX}/lib"
CFLAGS="-mmacosx-version-min=${MIN_V} -O2"
LDFLAGS_COMPAT="-mmacosx-version-min=${MIN_V} -L${PREFIX}/lib"
CPUS="$(sysctl -n hw.ncpu)"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "build_compat_dylibs: missing '$1' — run: brew bundle install --file=macos/Brewfile" >&2
    exit 1
  }
}
require_tool cmake
require_tool meson
require_tool ninja
require_tool pkg-config

# The dylibs must load on MIN_V; enforce it on every arch slice at build time
# so a toolchain regression fails here instead of on a user's Mac.
assert_minos() {
  file="$1"
  worst="$(vtool -show-build "${file}" 2>/dev/null | awk '
    /^ platform/ { platform = $2 }
    /^ +minos / { if (platform == "MACOS") print $2 }
  ' | sort -t. -k1,1n -k2,2n | tail -1)"
  if [ -z "${worst}" ]; then
    echo "build_compat_dylibs: cannot read LC_BUILD_VERSION of ${file}" >&2
    exit 1
  fi
  too_new="$(awk -v a="${worst}" -v b="${MIN_V}" 'BEGIN {
    split(a, x, "."); split(b, y, ".")
    if (x[1] > y[1] || (x[1] == y[1] && x[2] > y[2])) print "yes"
  }')"
  if [ "${too_new}" = "yes" ]; then
    echo "build_compat_dylibs: ${file} built for macOS ${worst} > ${MIN_V}" >&2
    exit 1
  fi
}

fetch() {
  name="$1"; url="$2"; sha="$3"
  archive="${WORKDIR}/$(basename "${url}")"
  mkdir -p "${WORKDIR}"
  if [ ! -f "${archive}" ] || { [ "${sha}" != "PENDING" ] && \
      ! shasum -a 256 -c <<< "${sha}  ${archive}" >/dev/null 2>&1; }; then
    echo ">>> fetch ${name}" >&2
    curl -fsSL --http1.1 --retry 5 --retry-delay 5 --retry-all-errors \
      -o "${archive}" "${url}"
  fi
  if [ "${sha}" = "PENDING" ]; then
    echo "build_compat_dylibs: pin this sha256 for ${name}: $(shasum -a 256 "${archive}" | awk '{print $1}')" >&2
  elif ! shasum -a 256 -c <<< "${sha}  ${archive}" >/dev/null 2>&1; then
    echo "build_compat_dylibs: sha256 mismatch for ${archive}" >&2
    exit 1
  fi
}

extract() {
  name="$1"
  dir="${WORKDIR}/${name}.extracted"
  rm -rf "${dir}"
  mkdir -p "${dir}"
  tar -xf "${WORKDIR}/$(basename "$2")" -C "${dir}"
  unpacked="$(find "${dir}" -mindepth 1 -maxdepth 1 -type d | head -1)"
  [ -n "${unpacked}" ] || { echo "build_compat_dylibs: empty archive for ${name}" >&2; exit 1; }
  printf '%s' "${unpacked}"
}

stage() {
  name="$1"
  if [ -f "${BUILT_DIR}/${name}" ] && [ "${FORCE}" -ne 1 ]; then
    return 1
  fi
  echo ">>> build ${name}"
  rm -f "${BUILT_DIR}/${name}"
  return 0
}

mark_built() {
  mkdir -p "${BUILT_DIR}"
  touch "${BUILT_DIR}/$1"
}

# Rewrites every prefix-relative install name to @rpath/<basename> and adds
# @loader_path so the copies resolve inside Contents/Frameworks/ (the same
# layout Homebrew's relocatable kegs use, which the bundler already follows).
# Version-less dev symlinks (libz.dylib -> libz.1.dylib) are skipped: the
# glob would otherwise rewrite the pointed-at file's ID with the unversioned
# name.
relocatable() {
  for lib in "${PREFIX}/lib/"*.dylib; do
    [ -L "${lib}" ] && continue
    while IFS= read -r dep; do
      [ -n "${dep}" ] || continue
      install_name_tool -change "${dep}" "@rpath/$(basename "${dep}")" "${lib}" 2>/dev/null || true
    done < <(otool -L "${lib}" 2>/dev/null | awk -v p="${PREFIX}/lib/" '/^\t/ { line = $0; sub(/^[[:space:]]+/, "", line); sub(/[[:space:]]+\(compatibility version.*$/, "", line); if (index(line, p) == 1) print line }')
    install_name_tool -id "@rpath/$(basename "${lib}")" "${lib}" >/dev/null 2>&1 || true
    install_name_tool -add_rpath "@loader_path" "${lib}" >/dev/null 2>&1 || true
    codesign -f -s - --timestamp=none "${lib}" >/dev/null 2>&1 || true
  done
}

mkdir -p "${PREFIX}" "${WORKDIR}" "${BUILT_DIR}"
if [ "${FORCE}" -eq 1 ]; then
  rm -rf "${PREFIX}/lib" "${PREFIX}/include" "${PREFIX}/share" "${PREFIX}/bin" "${BUILT_DIR}"
  mkdir -p "${PREFIX}/lib" "${BUILT_DIR}"
fi
[ -d "${PREFIX}/lib" ] || mkdir -p "${PREFIX}/lib"

# ---------------------------------------------------------------- zlib
if stage zlib; then
  url=https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz
  sha=9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23
  src="$(fetch zlib "${url}" "${sha}"; extract zlib "${url}")"
  (
    cd "${src}"
    CFLAGS="${CFLAGS}" ./configure --prefix="${PREFIX}"
    make -j"${CPUS}" >/dev/null
    make install >/dev/null
  )
  mark_built zlib
fi

# ---------------------------------------------------------------- libiconv
if stage libiconv; then
  url=https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.19.tar.gz
  sha=88dd96a8c0464eca144fc791ae60cd31cd8ee78321e67397e25fc095c4a19aa6
  src="$(fetch libiconv "${url}" "${sha}"; extract libiconv "${url}")"
  (
    cd "${src}"
    ./configure --prefix="${PREFIX}" --enable-shared --disable-static \
      CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS_COMPAT}"
    make -j"${CPUS}" >/dev/null
    make install >/dev/null
  )
  mark_built libiconv
fi

# ---------------------------------------------------------------- brotli
if stage brotli; then
  url=https://github.com/google/brotli/archive/refs/tags/v1.2.1.tar.gz
  sha=98d35d11a78dc453aebb7d10c3748f3f73ff78c8267c0dc697b8631f67bf7e8f
  src="$(fetch brotli "${url}" "${sha}"; extract brotli "${url}")"
  rm -rf "${WORKDIR}/brotli.build"
  cmake -S "${src}" -B "${WORKDIR}/brotli.build" -GNinja \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MIN_V}" \
    -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON >/dev/null
  ninja -C "${WORKDIR}/brotli.build" install >/dev/null
  mark_built brotli
fi

# ---------------------------------------------------------------- libpng
if stage libpng; then
  url=https://downloads.sourceforge.net/project/libpng/libpng16/1.6.59/libpng-1.6.59.tar.xz
  sha=d80dd2a38a37f803cb9b6ac7b14bd6e74ddc3b654780a8380bdf93523fdb4389
  src="$(fetch libpng "${url}" "${sha}"; extract libpng "${url}")"
  (
    cd "${src}"
    ./configure --prefix="${PREFIX}" --enable-shared --disable-static \
      CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS_COMPAT}"
    make -j"${CPUS}" >/dev/null
    make install >/dev/null
  )
  mark_built libpng
fi

# ---------------------------------------------------------------- freetype
# 2.13.3 deliberately: 2.15.0+ can link Apple's HVF driver (macOS 26-only
# /usr/lib/libhvf.dylib) when built against the macOS 26 SDK.
if stage freetype; then
  url=https://download.savannah.gnu.org/releases/freetype/freetype-2.13.3.tar.xz
  sha=0550350666d427c74daeb85d5ac7bb353acba5f76956395995311a9c6f063289
  src="$(fetch freetype "${url}" "${sha}"; extract freetype "${url}")"
  (
    cd "${src}"
    ./configure --prefix="${PREFIX}" --enable-shared --disable-static \
      --with-brotli --without-harfbuzz --without-bzip2 \
      CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS_COMPAT}"
    make -j"${CPUS}" >/dev/null
    make install >/dev/null
  )
  mark_built freetype
fi

# ---------------------------------------------------------------- fribidi
if stage fribidi; then
  url=https://github.com/fribidi/fribidi/releases/download/v1.0.18/fribidi-1.0.18.tar.xz
  sha=1de5e8073d035388b71d0b2d452b1da1f8caeea8a7702997b401fe1b6250727f
  src="$(fetch fribidi "${url}" "${sha}"; extract fribidi "${url}")"
  rm -rf "${WORKDIR}/fribidi.build"
  meson setup "${WORKDIR}/fribidi.build" "${src}" \
    --prefix="${PREFIX}" --default-library=shared --buildtype=release \
    -Ddocs=false -Dtests=false >/dev/null
  ninja -C "${WORKDIR}/fribidi.build" install >/dev/null
  mark_built fribidi
fi

# ---------------------------------------------------------------- graphite2
if stage graphite2; then
  url=https://github.com/silnrsi/graphite/releases/download/1.3.15/graphite2-1.3.15.tgz
  sha=c6bc8b4252724665297f7cad0c55897285c673f9b8e6db3522ace833593fe0b1
  src="$(fetch graphite2 "${url}" "${sha}"; extract graphite2 "${url}")"
  rm -rf "${WORKDIR}/graphite2.build"
  cmake -S "${src}" -B "${WORKDIR}/graphite2.build" -GNinja \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MIN_V}" \
    -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON \
    -DGRAPHITE2_COMPARE_RENDERER=OFF -DGRAPHITE2_TESTS=OFF >/dev/null
  ninja -C "${WORKDIR}/graphite2.build" install >/dev/null
  mark_built graphite2
fi

# ---------------------------------------------------------------- pcre2
if stage pcre2; then
  url=https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.49/pcre2-10.49.tar.bz2
  sha=53c156e1ba416a20da8e65395daa132da0d80e76910424caca3fcdae7831d384
  src="$(fetch pcre2 "${url}" "${sha}"; extract pcre2 "${url}")"
  (
    cd "${src}"
    ./configure --prefix="${PREFIX}" --enable-shared --disable-static \
      --disable-pcre2-16 --disable-pcre2-32 --enable-jit --disable-docs \
      CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS_COMPAT}"
    make -j"${CPUS}" >/dev/null
    make install >/dev/null
  )
  mark_built pcre2
fi

# ---------------------------------------------------------------- gettext
# Only the libintl runtime is needed; configuring gettext-runtime alone skips
# the message tools entirely.
if stage gettext; then
  url=https://ftp.gnu.org/gnu/gettext/gettext-1.0.tar.gz
  sha=85d99b79c981a404874c02e0342176cf75c7698e2b51fe41031cf6526d974f1a
  src="$(fetch gettext "${url}" "${sha}"; extract gettext "${url}")"
  (
    cd "${src}/gettext-runtime"
    ./configure --prefix="${PREFIX}" --enable-shared --disable-static \
      --disable-java --disable-native-java --disable-curses --disable-openmp \
      CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS_COMPAT}"
    make -C intl -j"${CPUS}" >/dev/null
    make -C intl install >/dev/null
  )
  mark_built gettext
fi

# ---------------------------------------------------------------- glib
if stage glib; then
  url=https://download.gnome.org/sources/glib/2.90/glib-2.90.1.tar.xz
  sha=93c941aa17d5eb1d53fe838365f29a8b4e539c222a256d974ec8f30fc413e396
  src="$(fetch glib "${url}" "${sha}"; extract glib "${url}")"
  rm -rf "${WORKDIR}/glib.build"
  meson setup "${WORKDIR}/glib.build" "${src}" \
    --prefix="${PREFIX}" --default-library=shared --buildtype=release \
    -Dtests=false -Dnls=disabled -Dsysprof=disabled >/dev/null
  ninja -C "${WORKDIR}/glib.build" install >/dev/null
  mark_built glib
fi

# ---------------------------------------------------------------- harfbuzz
if stage harfbuzz; then
  url=https://github.com/harfbuzz/harfbuzz/releases/download/15.0.0/harfbuzz-15.0.0.tar.xz
  sha=968536e9abd782f07f7954044c0c4020199fcdd39b41d221ec42d2a3be4a44df
  src="$(fetch harfbuzz "${url}" "${sha}"; extract harfbuzz "${url}")"
  rm -rf "${WORKDIR}/harfbuzz.build"
  meson setup "${WORKDIR}/harfbuzz.build" "${src}" \
    --prefix="${PREFIX}" --default-library=shared --buildtype=release \
    -Dglib=enabled -Dgobject=disabled -Dfreetype=enabled -Dgraphite2=enabled \
    -Dicu=disabled -Dcairo=disabled -Dtests=disabled -Ddocs=disabled \
    -Dintrospection=disabled >/dev/null
  ninja -C "${WORKDIR}/harfbuzz.build" install >/dev/null
  mark_built harfbuzz
fi

# ---------------------------------------------------------------- fontconfig
if stage fontconfig; then
  url=https://gitlab.freedesktop.org/fontconfig/fontconfig/-/archive/2.18.3/fontconfig-2.18.3.tar.gz
  sha=9ae01e1d53acdef56010c5451cd34aa41d325b2faccd8606448d8fa01b2496b3
  src="$(fetch fontconfig "${url}" "${sha}"; extract fontconfig "${url}")"
  rm -rf "${WORKDIR}/fontconfig.build"
  meson setup "${WORKDIR}/fontconfig.build" "${src}" \
    --prefix="${PREFIX}" --default-library=shared --buildtype=release \
    -Ddoc=disabled -Dtests=disabled -Dtools=disabled -Dcache-build=disabled \
    -Dadditional-fonts-dirs=no \
    -Ddefault-fonts-dirs=/System/Library/Fonts,/Library/Fonts >/dev/null
  ninja -C "${WORKDIR}/fontconfig.build" install >/dev/null
  mark_built fontconfig
fi

# ---------------------------------------------------------------- libsamplerate
if stage libsamplerate; then
  url=https://github.com/libsndfile/libsamplerate/releases/download/0.2.2/libsamplerate-0.2.2.tar.xz
  sha=3258da280511d24b49d6b08615bbe824d0cacc9842b0e4caf11c52cf2b043893
  src="$(fetch libsamplerate "${url}" "${sha}"; extract libsamplerate "${url}")"
  rm -rf "${WORKDIR}/libsamplerate.build"
  cmake -S "${src}" -B "${WORKDIR}/libsamplerate.build" -GNinja \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MIN_V}" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTING=OFF -DLIBSAMPLERATE_EXAMPLES=OFF >/dev/null
  ninja -C "${WORKDIR}/libsamplerate.build" install >/dev/null
  mark_built libsamplerate
fi

# ---------------------------------------------------------------- openssl
if stage openssl; then
  url=https://github.com/openssl/openssl/releases/download/openssl-3.6.3/openssl-3.6.3.tar.gz
  sha=243a86649cf6f23eeb6a2ff2456e09e5d77dd9018a54d3d96b0c6bdd6ba6c7f1
  src="$(fetch openssl "${url}" "${sha}"; extract openssl "${url}")"
  (
    cd "${src}"
    ./Configure darwin64-arm64-cc --prefix="${PREFIX}" --openssldir="${PREFIX}/ssl" \
      shared no-tests no-docs no-apps -mmacosx-version-min="${MIN_V}"
    make -j"${CPUS}" build_sw >/dev/null
    make install_sw >/dev/null
  )
  mark_built openssl
fi

# ---------------------------------------------------------------- srt
if stage srt; then
  url=https://github.com/Haivision/srt/archive/refs/tags/v1.5.7.tar.gz
  sha=017cd1e437ef2073a4dd10ddf7b55e86bc3d6ebac0393d13bd22f6a57055d32b
  src="$(fetch srt "${url}" "${sha}"; extract srt "${url}")"
  rm -rf "${WORKDIR}/srt.build"
  cmake -S "${src}" -B "${WORKDIR}/srt.build" -GNinja \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MIN_V}" \
    -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON \
    -DENABLE_APPS=OFF -DENABLE_EXAMPLES=OFF -DENABLE_TESTING=OFF \
    -DOPENSSL_ROOT_DIR="${PREFIX}" >/dev/null
  ninja -C "${WORKDIR}/srt.build" install >/dev/null
  mark_built srt
fi

relocatable

echo ">>> verifying deployment target of ${PREFIX}/lib"
for lib in "${PREFIX}/lib/"*.dylib; do
  assert_minos "${lib}"
done

echo "build_compat_dylibs: prefix ready at ${PREFIX} (min macOS ${MIN_V})"
for lib in "${PREFIX}/lib/"*.dylib; do
  echo "  $(basename "${lib}")"
done
