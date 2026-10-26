#!/usr/bin/env bash
# Re-shoot the store screenshots in assets/store/ from the Duet gallery.
# Renders every `Store…` scene in test/duet_gallery at the store's exact pixel
# size, then flattens each (App Store Connect rejects alpha) into the listing
# file name. Needs ImageMagick (magick or convert).
#
# Usage: bash tool/store_screenshots.sh
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

if command -v magick >/dev/null 2>&1; then
  im=(magick)
elif command -v convert >/dev/null 2>&1; then
  im=(convert)
else
  echo "error: ImageMagick (magick or convert) is required" >&2
  exit 1
fi

flutter test --tags gallery --run-skipped test/duet_gallery --plain-name Store

shots="build/duet_gallery"
store="assets/store"

while read -r board target; do
  [ -n "$board" ] || continue
  "${im[@]}" "$shots/$board.png" -background white -alpha remove -alpha off \
    -quality 92 "$store/$target"
  echo "$store/$target"
done <<'EOF'
StoreIosPhoneHome ios_phone_home_portrait_screenshot.png
StoreIosPhonePlayer ios_phone_player_portrait_screenshot.png
StoreIosPhoneAssessment ios_phone_assessment_portrait_screenshot.png
StoreIosPhoneCraft ios_phone_craft_portrait_screenshot.png
StoreIosPhoneVocabulary ios_phone_vocabulary_portrait_screenshot.png
StoreIosPadPlayerPortrait ios_pad_player_portrait_screenshot.png
StoreIosPadPlayerLandscape ios_pad_player_landscape_screenshot.png
StoreIosPadCraftPortrait ios_pad_craft_portrait_screenshot.png
StoreIosPadDiscoverPortrait ios_pad_discover_portrait_screenshot.png
StoreAndroidPhoneHome android_phone_screenshot_1.jpg
StoreAndroidPhonePlayer android_phone_screenshot_2.jpg
StoreAndroidPhoneAssessment android_phone_screenshot_3.jpg
StoreAndroidPhoneVocabulary android_phone_screenshot_4.jpg
StoreAndroidPadPlayer android_pad_screenshot_1.jpg
StoreMacosPlayer macos_player_screenshot.png
EOF
