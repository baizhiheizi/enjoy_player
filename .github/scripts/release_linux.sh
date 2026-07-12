#!/usr/bin/env bash
# Linux AppImage release: build + package + publish.
#
# Usage:
#   bash .github/scripts/release.sh --platform linux
#   bash .github/scripts/release_linux.sh [--publish] [--publish-only] [--skip-build] [--skip-checks]
#
# Integrates with the existing release.sh dispatcher and the same S3 publishing
# infrastructure the other release scripts use.
set -euo pipefail

scripts="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$scripts/../.." && pwd)"

PUBLISH=false
PUBLISH_ONLY=false
SKIP_BUILD=false
SKIP_CHECKS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --publish) PUBLISH=true; shift ;;
    --publish-only) PUBLISH_ONLY=true; shift ;;
    --skip-build) SKIP_BUILD=true; shift ;;
    --skip-checks) SKIP_CHECKS=true; shift ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

if ! $PUBLISH_ONLY; then
  if ! $SKIP_CHECKS; then
    echo "==> Pre-release checks"
    flutter analyze
    flutter test
  fi

  if ! $SKIP_BUILD; then
    echo "==> Building Linux release"
    flutter build linux --release
  fi

  # Read version from pubspec.yaml
  VERSION="$(grep '^version:' "$root/pubspec.yaml" | awk '{print $2}' | cut -d'+' -f1)"
  echo "==> Package version: $VERSION"

  echo "==> Building AppImage"
  bash "$root/linux/packaging/make_appimage.sh" \
    --version "$VERSION" \
    --bundle "$root/build/linux/x64/release/bundle" \
    --output "$root/build/linux/x64/release"
else
  VERSION="$(grep '^version:' "$root/pubspec.yaml" | awk '{print $2}' | cut -d'+' -f1)"
fi

APPIMAGE="$root/build/linux/x64/release/enjoy-player-${VERSION}-x86_64.AppImage"

if [[ ! -f "$APPIMAGE" ]]; then
  echo "ERROR: AppImage not found at $APPIMAGE" >&2
  exit 1
fi

SHA256="$(sha256sum "$APPIMAGE" | awk '{print $1}')"
echo "==> SHA-256: $SHA256"

if $PUBLISH || $PUBLISH_ONLY; then
  echo "==> Publishing to dl.enjoy.bot"
  PUBLISH_PREFIX="${PUBLISH_PREFIX:-player}"
  PUBLISH_BUCKET="${PUBLISH_BUCKET:-}"
  if [[ -z "$PUBLISH_BUCKET" ]]; then
    echo "ERROR: PUBLISH_BUCKET not set. Source publish_env.local.sh or set the env var." >&2
    exit 1
  fi

  S3_KEY="${PUBLISH_PREFIX}/v${VERSION}/enjoy-player-${VERSION}-x86_64.AppImage"
  S3_URL="s3://${PUBLISH_BUCKET}/${S3_KEY}"

  echo "==> Uploading $APPIMAGE → $S3_URL"
  aws s3 cp "$APPIMAGE" "$S3_URL" --no-progress

  echo "==> Done. Update latest.json manually with:"
  echo "    \"linux\": {"
  echo "      \"url\": \"https://dl.enjoy.bot/${S3_KEY}\","
  echo "      \"sha256\": \"$SHA256\","
  echo "      \"format\": \"appimage\""
  echo "    }"
fi

echo "==> Linux release done"
echo "  AppImage: $APPIMAGE"
echo "  SHA-256:  $SHA256"
echo "  Version:  $VERSION"
