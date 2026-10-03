#!/usr/bin/env bash
# Install Linux build packages only when missing (self-hosted runners).
#
# On the shared gh-sr agentic runner pool, most of these are now baked into
# the container image at build time via `container_runner_image.extra_apt_packages`
# in runners.yml, so this should normally be a fast no-op there. Kept as a
# safety net for any Linux runner (agentic image rebuild pending, or a plain
# native host) where a package isn't baked in yet.
set -euo pipefail

packages=(
  clang
  cmake
  curl
  git
  jq
  ninja-build
  pkg-config
  unzip
  xz-utils
  zip
  python3
  python3-venv
  libgtk-3-dev
  liblzma-dev
  libsqlite3-dev
  libgstreamer1.0-dev
  libgstreamer-plugins-base1.0-dev
  libsecret-1-dev
  libmpv-dev
  libepoxy-dev
  libwayland-dev
  libsoup-3.0-dev
  libjavascriptcoregtk-4.1-dev
  libglvnd-dev
)

# WPE WebKit has no Ubuntu packages (noble), so the plugin compiles against a
# pinned Debian bookworm build extracted into a runner-local prefix. Compile-
# time only: the shipped artifact resolves WPE from the host (ADR-0092).
if ! pkg-config --exists wpe-webkit-2.0 2>/dev/null; then
  WPE_ROOT="${WPE_ROOT:-$HOME/.cache/wpe-webkit-2.54b}"
  if [ ! -e "$WPE_ROOT/usr/lib/x86_64-linux-gnu/pkgconfig/wpe-webkit-2.0.pc" ]; then
    echo "WPE WebKit not installed — extracting pinned Debian build into $WPE_ROOT"
    mkdir -p "$WPE_ROOT"
    for deb in \
      https://deb.debian.org/debian/pool/main/w/wpewebkit/libwpewebkit-2.0-dev_2.54.0-2_amd64.deb \
      https://deb.debian.org/debian/pool/main/w/wpewebkit/libwpewebkit-2.0-1_2.54.0-2_amd64.deb \
      https://deb.debian.org/debian/pool/main/libw/libwpe/libwpe-1.0-1_1.16.3-2_amd64.deb \
      https://deb.debian.org/debian/pool/main/w/wpebackend-fdo/libwpebackend-fdo-1.0-1_1.16.1-1+b1_amd64.deb \
      https://deb.debian.org/debian/pool/main/w/wpebackend-fdo/libwpebackend-fdo-1.0-dev_1.16.1-1+b1_amd64.deb \
      https://deb.debian.org/debian/pool/main/libw/libwpe/libwpe-1.0-dev_1.16.3-2_amd64.deb \
    ; do
      curl -fsSL -o "$WPE_ROOT/pkg.deb" "$deb"
      dpkg-deb -x "$WPE_ROOT/pkg.deb" "$WPE_ROOT"
      rm -f "$WPE_ROOT/pkg.deb"
    done
  fi
  # Debian pc files bake prefix=/usr and multiarch libdirs; repoint every /usr
  # reference at the extraction root so Cflags/Libs stay inside the prefix.
  find "$WPE_ROOT/usr" -name '*.pc' -print0 2>/dev/null |
    xargs -0 -r sed -i "s|=/usr|=$WPE_ROOT/usr|g"
  export PKG_CONFIG_PATH="$WPE_ROOT/usr/lib/x86_64-linux-gnu/pkgconfig:$WPE_ROOT/usr/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
  if [ -n "${GITHUB_ENV:-}" ]; then
    echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH" >> "$GITHUB_ENV"
  fi
fi

missing=()
for pkg in "${packages[@]}"; do
  if ! dpkg-query -W -f='${Status}' "${pkg}" 2>/dev/null | grep -q 'install ok installed'; then
    missing+=("${pkg}")
  fi
done

if [ "${#missing[@]}" -eq 0 ]; then
  echo "Linux build packages already installed."
  exit 0
fi

echo "Installing missing packages: ${missing[*]}"
sudo apt-get update -y
sudo apt-get install -y "${missing[@]}"
