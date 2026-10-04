#!/usr/bin/env bash
# Compare Duet board renders with gallery captures: render on the left, app on
# the right, at the same scale. Writes build/duet_gallery/compare/<Board>.png.
#
# Usage: tool/duet_compare.sh [Board ...]
# Without arguments, compares every captured board that has a render.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

renders="docs/design/duet/renders"
shots="build/duet_gallery"
compare="$shots/compare"

if ! command -v magick >/dev/null 2>&1 && ! command -v convert >/dev/null 2>&1; then
  echo "error: ImageMagick (magick or convert) is required" >&2
  exit 1
fi

append() {
  if command -v magick >/dev/null 2>&1; then magick "$@"; else convert "$@"; fi
}

boards=("$@")
if [ ${#boards[@]} -eq 0 ]; then
  for shot in "$shots"/*.png; do
    [ -e "$shot" ] || continue
    boards+=("$(basename "$shot" .png)")
  done
fi

if [ ${#boards[@]} -eq 0 ]; then
  echo "no gallery captures in $shots — run:" >&2
  echo "  flutter test --tags gallery --run-skipped test/duet_gallery" >&2
  exit 1
fi

mkdir -p "$compare"
missing=0
for board in "${boards[@]}"; do
  render="$renders/$board.webp"
  shot="$shots/$board.png"
  if [ ! -e "$render" ] || [ ! -e "$shot" ]; then
    echo "skip $board (missing $([ ! -e "$render" ] && echo "$render" || echo "$shot"))"
    missing=$((missing + 1))
    continue
  fi
  height="$([ "$(identify -format '%h' "$render")" -le "$(identify -format '%h' "$shot")" ] \
    && identify -format '%h' "$render" || identify -format '%h' "$shot")"
  append \
    \( "$render" -resize "x$height" \) \
    \( "$shot" -resize "x$height" \) \
    -background '#888888' -splice 4x0+0+0 +append \
    "$compare/$board.png"
  echo "compare/$board.png"
done

[ "$missing" -eq 0 ] || echo "$missing board(s) skipped"
