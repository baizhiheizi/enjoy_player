# ADR-0059: Phone/tablet orientation policy and aspect-based player layout

## Status

Accepted

## Context

Accidental phone landscape rotation distracts language practice. Tablets
reasonably support both orientations. Separately, `VideoPlayerLayout` chose
side-by-side video + transcript when width exceeded `breakpointTranscriptSideBySide`
(720), so portrait-wide tablets looked like desktop even when held upright.

## Decision

1. **Form factor orientation policy** (Android/iOS): classify devices by
   logical shortest side (≥ 600 → tablet, else phone). Phones prefer portrait
   only (`SystemChrome` + iPhone `Info.plist`). Tablets allow all orientations.
   Desktop platforms do not call `setPreferredOrientations`.
2. **Player content layout**: stack vs side-by-side is driven by the player
   layout constraints’ aspect (`width > height` → side-by-side; otherwise
   stacked), not by the 720 width breakpoint.
3. **Retain 720 for other UI**: transport-bar packing and similar width-driven
   chrome continue to use `breakpointTranscriptSideBySide`.

Helpers live in `lib/core/platform/device_form_factor.dart` and
`player_content_layout.dart`.

## Consequences

- Portrait tablets stack video over transcript even when wider than 720.
- Narrow landscape windows (including desktop reshape) can side-by-side below 720.
- Phones no longer auto-rotate into landscape app chrome.
- Product change is documented here; feature pages (`player.md`, `app-ui.md`)
  describe the user-visible layout rule.
