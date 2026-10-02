#!/usr/bin/env bash
# Wrap the Flutter Linux release bundle into a self-contained AppImage.
#
# Usage:
#   bash linux/packaging/make_appimage.sh --version 0.5.0 --bundle build/linux/x64/release/bundle --output dist/
#
# Produces: dist/enjoy-player-<version>-x86_64.AppImage
#
# Requires: appimagetool-x86_64.AppImage (downloaded on first run, cached under ~/.cache/appimagetool/).
#
# YouTube playback (ADR-0091 / specs/047 T027): the GStreamer runtime + plugin
# set and the transitive dependency closure of the bundled WPE WebKit are copied
# into the image, and AppRun wires GST_PLUGIN_PATH / LD_LIBRARY_PATH to them.
# Build on the release baseline (Ubuntu 22.04) so bundled library versions match
# the oldest supported glibc — building on a newer distro produces an image that
# only runs on similarly new systems.
set -euo pipefail

VERSION=""
BUNDLE_DIR=""
OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --bundle)  BUNDLE_DIR="$2"; shift 2 ;;
    --output)  OUTPUT_DIR="$2"; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$VERSION" || -z "$BUNDLE_DIR" || -z "$OUTPUT_DIR" ]]; then
  echo "Usage: make_appimage.sh --version <v> --bundle <dir> --output <dir>" >&2
  exit 1
fi

BUNDLE_DIR="$(realpath "$BUNDLE_DIR")"
OUTPUT_DIR="$(realpath "$OUTPUT_DIR")"
APP_NAME="enjoy-player-${VERSION}-x86_64"
APPDIR="$(mktemp -d)"
trap 'rm -rf "$APPDIR"' EXIT

echo "==> Preparing AppDir from $BUNDLE_DIR"
cp -a "$BUNDLE_DIR"/* "$APPDIR"/

# --- GStreamer runtime + plugins (YouTube playback, specs/047 T027) ---
#
# WPE loads media code via dlopen at runtime, so link-time dependency walkers
# never see these; copy the whole plugin directory (whitelisting individual
# plugins lost a real playback session to a missing element).
PLUGINS_DIR="$(pkg-config --variable=pluginsdir gstreamer-1.0 2>/dev/null || true)"
if [[ -z "$PLUGINS_DIR" || ! -d "$PLUGINS_DIR" ]]; then
  echo "error: GStreamer plugins directory not found via pkg-config (gstreamer-1.0). Install the GStreamer dev packages — see docs/features/linux-platform.md" >&2
  exit 1
fi
APP_GST_DIR="$APPDIR/usr/lib/gstreamer-1.0"
mkdir -p "$APP_GST_DIR"
echo "==> Bundling GStreamer plugins from $PLUGINS_DIR"
cp -a "$PLUGINS_DIR"/*.so* "$APP_GST_DIR"/
if [[ -f "$PLUGINS_DIR/gst-plugin-scanner" ]]; then
  cp -a "$PLUGINS_DIR/gst-plugin-scanner" "$APP_GST_DIR"/
fi

# --- Transitive dependency closure (no linuxdeploy in this pipeline) ---
#
# Every non-glibc shared library reachable from the bundle's own libraries and
# the copied GStreamer plugins lands in usr/lib; glibc is always taken from the
# host. Newer build-machine libraries stay backward compatible for older hosts,
# which is why the release build runs on the oldest supported baseline.
is_glibc_core() {
  case "$(basename "$1")" in
    ld-linux-*|libc.so*|libm.so*|libdl.so*|libpthread.so*|librt.so*|libresolv.so*|libcrypt.so*) return 0 ;;
    *) return 1 ;;
  esac
}

APP_USR_LIB="$APPDIR/usr/lib"
mkdir -p "$APP_USR_LIB"

link_soname() {
  local real="$1"
  command -v readelf >/dev/null 2>&1 || return 0
  local soname
  soname="$(readelf -d "$real" 2>/dev/null | awk -F'[][]' '/SONAME/ {print $2; exit}')"
  [[ -n "$soname" ]] || return 0
  [[ -e "$APP_USR_LIB/$soname" || -e "$APPDIR/lib/$soname" ]] && return 0
  ln -s "$(basename "$real")" "$APP_USR_LIB/$soname"
}

DEP_LIST="$(mktemp)"
sources=("$APPDIR"/lib/*.so* "$APP_GST_DIR"/*.so*)
for _ in $(seq 1 12); do
  : > "$DEP_LIST"
  for f in "${sources[@]}"; do
    [[ -f "$f" ]] || continue
    while read -r lib; do
      [[ -n "$lib" ]] || continue
      is_glibc_core "$lib" && continue
      [[ -e "$APPDIR/lib/$(basename "$lib")" ]] && continue
      [[ -e "$APP_USR_LIB/$(basename "$lib")" ]] && continue
      echo "$lib" >> "$DEP_LIST"
    done < <(ldd "$f" 2>/dev/null | awk '$2 == "=>" && $3 ~ /^\// {print $3}; !($2 == "=>") && $1 ~ /^\// {print $1}')
  done
  sort -u "$DEP_LIST" -o "$DEP_LIST"
  [[ -s "$DEP_LIST" ]] || break
  while IFS= read -r lib; do
    cp -aL "$lib" "$APP_USR_LIB/$(basename "$lib")"
    link_soname "$APP_USR_LIB/$(basename "$lib")"
    sources+=("$APP_USR_LIB/$(basename "$lib")")
  done < "$DEP_LIST"
done
rm -f "$DEP_LIST"

MISSING="$(find "$APPDIR" -name '*.so*' -exec sh -c 'ldd "$1" 2>/dev/null | grep "not found"' _ {} \; | sort -u || true)"
if [[ -n "$MISSING" ]]; then
  echo "warning: unresolved libraries inside the AppDir:" >&2
  echo "$MISSING" >&2
fi

# Desktop entry (required by AppImage spec — must be at AppDir root AND in usr/share/applications).
# `%u` passes the launched URI (e.g. enjoyplayer://auth/callback) and
# `MimeType=x-scheme-handler/enjoyplayer` registers the PKCE callback scheme
# so browsers/xdg-open can find the app (ADR-0084).
mkdir -p "$APPDIR"/usr/share/applications
cat > "$APPDIR"/enjoy-player.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Enjoy Player
Comment=Cross-platform language-learning player
Exec=enjoy_player %u
Icon=enjoy_player
Categories=AudioVideo;Player;Education;
MimeType=x-scheme-handler/enjoyplayer;
Terminal=false
EOF
cp "$APPDIR"/enjoy-player.desktop "$APPDIR"/usr/share/applications/enjoy-player.desktop

# Icon (use the app's logo; a minimal placeholder if not found)
mkdir -p "$APPDIR"/usr/share/icons/hicolor/256x256/apps
if [[ -f "$BUNDLE_DIR/data/flutter_assets/assets/logo-light.svg" ]]; then
  cp "$BUNDLE_DIR/data/flutter_assets/assets/logo-light.svg" \
     "$APPDIR"/usr/share/icons/hicolor/256x256/apps/enjoy_player.svg
  # Also put a copy in the AppDir root for appimagetool
  cp "$BUNDLE_DIR/data/flutter_assets/assets/logo-light.svg" "$APPDIR"/enjoy_player.svg
else
  touch "$APPDIR"/enjoy_player.png
fi

# AppRun wires the bundled GStreamer + library paths before exec (T027), so the
# image never mixes plugin versions with the host's GStreamer.
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(CDPATH= cd -- "$(dirname -- "$(readlink -f "$0")")" && pwd)"
export LD_LIBRARY_PATH="$HERE/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export GST_PLUGIN_PATH="$HERE/usr/lib/gstreamer-1.0"
export GST_PLUGIN_SYSTEM_PATH="$HERE/usr/lib/gstreamer-1.0"
if [ -x "$HERE/usr/lib/gstreamer-1.0/gst-plugin-scanner" ]; then
  export GST_PLUGIN_SCANNER="$HERE/usr/lib/gstreamer-1.0/gst-plugin-scanner"
fi
exec "$HERE/enjoy_player" "$@"
EOF
chmod +x "$APPDIR/AppRun"

echo "==> AppDir contents: $(du -sh "$APPDIR" | awk '{ print $1 }')"

# Download appimagetool on first run (cache it)
CACHE_DIR="${HOME}/.cache/appimagetool"
mkdir -p "$CACHE_DIR"
APPIMAGETOOL="${CACHE_DIR}/appimagetool-x86_64.AppImage"
APPIMAGETOOL_BIN="${CACHE_DIR}/squashfs-root/AppRun"

if [[ ! -x "$APPIMAGETOOL_BIN" ]]; then
  if [[ ! -f "$APPIMAGETOOL" ]]; then
    echo "==> Downloading appimagetool..."
    curl -fsSL -o "$APPIMAGETOOL" \
      "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$APPIMAGETOOL"
  fi
  # Extract so we can run without FUSE
  echo "==> Extracting appimagetool (no FUSE required)..."
  (cd "$CACHE_DIR" && "$APPIMAGETOOL" --appimage-extract >/dev/null 2>&1) || \
    (cd "$CACHE_DIR" && bash "$APPIMAGETOOL" --appimage-extract >/dev/null 2>&1)
fi

mkdir -p "$OUTPUT_DIR"

echo "==> Building $APP_NAME.AppImage"
ARCH=x86_64 "$APPIMAGETOOL_BIN" "$APPDIR" "$OUTPUT_DIR/$APP_NAME.AppImage"

echo "==> AppImage produced: $OUTPUT_DIR/$APP_NAME.AppImage"
sha256sum "$OUTPUT_DIR/$APP_NAME.AppImage" | awk '{ print $1 }'
