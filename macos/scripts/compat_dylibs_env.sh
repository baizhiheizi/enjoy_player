#!/bin/bash
# Shared constants for the macOS Homebrew-dylib compatibility layer.
#
# The vendored FFmpegKit frameworks (packages/ffmpeg_kit_flutter_new) were
# linked against /opt/homebrew kegs, so every macOS build has to provide those
# dylibs. Homebrew bottles carry the bottle tag's macOS as LC_BUILD_VERSION
# minos (26.0 for current arm64 bottles) and FreeType >= 2.15 bottles link
# /usr/lib/libhvf.dylib (macOS 26 only), so keg copies crash dyld on every
# older macOS. Releases resolve the dylibs from a prefix built with
# MACOSX_DEPLOYMENT_TARGET = the app's minimum instead (ADR-0102).

# The minimum macOS the direct-download app supports; must match
# MACOSX_DEPLOYMENT_TARGET in macos/Runner.xcconfig and docs/packaging.md.
COMPAT_MIN_MACOS_VERSION="12.0"

# Home directory of the deployment-target-12.0 dylib prefix, populated by
# macos/scripts/build_compat_dylibs.sh (cached across builds; override with
# ENJOY_MACOS_COMPAT_PREFIX when experimenting).
compat_dylibs_prefix() {
  printf '%s' "${ENJOY_MACOS_COMPAT_PREFIX:-${HOME}/Library/Caches/ai.enjoy.player/macos-compat}"
}

# /usr/lib dylibs the bundled Mach-O binaries may link. Everything else under
# /usr/lib fails the bundler's gate: system libs appear and disappear with OS
# releases (libhvf.dylib exists only on macOS 26+), and dyld aborts at launch
# when a strong dependency is missing on the user's older macOS. Add a name
# here only after confirming it exists on every macOS >= 12.0.
compat_allowed_usr_libs() {
  cat <<'EOF'
libSystem.B.dylib
libSystem.dylib
libc++.1.dylib
libobjc.dylib
libobjc.A.dylib
libz.1.dylib
libbz2.1.0.dylib
libiconv.2.dylib
libcharset.1.dylib
libcompression.dylib
libexpat.1.dylib
libffi.dylib
libresolv.9.dylib
libsqlite3.dylib
libxar.1.dylib
EOF
}
