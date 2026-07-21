# Quickstart: Orientation & Player Layout Polish

**Feature**: 026-orientation-layout-polish | **Date**: 2026-07-20

Validation guide after implementation. See [contracts/](contracts/) and [data-model.md](data-model.md) for exact predicates.

## Prerequisites

- Flutter SDK matching repo `pubspec.yaml`
- At least one of: Android emulator/device, iOS Simulator/device
- Optional: desktop target for window reshape

## Automated checks

```bash
# Pure helpers + layout widget contract
flutter test test/core/platform/
flutter test test/features/player/video_player_layout_test.dart

# Repo gates before push
bash .github/scripts/validate_ci_gates.sh
# or on Windows Git Bash / WSL:
# bash .github/scripts/validate_ci_gates.sh --fix
```

**Expect**:

- Form-factor unit cases: desktop always desktop; mobile &lt;600 phone; ≥600 tablet.
- Preferred orientations: phone portrait-only; tablet all; desktop null.
- Widget layout cases from [player-content-layout.md](contracts/player-content-layout.md) (especially **800×1000 stacked** and **700×400 side-by-side**).

## Manual: phone (no auto-rotate)

1. Enable OS auto-rotate.
2. Launch the app on a phone-class device/simulator (shortest side &lt; 600).
3. Browse Library / Discover / Settings; tilt to landscape.
4. **Expect**: UI stays portrait; no landscape chrome.
5. Open a video with transcript in the player; tilt again.
6. **Expect**: still portrait; stacked video above transcript.

## Manual: tablet (auto-rotate OK)

1. Enable OS auto-rotate.
2. Launch on a tablet-class device/simulator (shortest side ≥ 600), or iPad simulator.
3. Rotate browsing screens to landscape and back.
4. **Expect**: app follows orientation.
5. Open player with transcript in **portrait**.
6. **Expect**: stacked layout even if width &gt; 720.
7. Rotate to **landscape**.
8. **Expect**: side-by-side; playback position continuous (±1s); transcript cue still findable.
9. Drag transcript split; rotate away and back to landscape.
10. **Expect**: usable transcript width restored (preference or safe clamp).

## Manual: desktop window reshape

1. Run Windows, macOS, or Linux desktop build.
2. Open player with transcript.
3. Resize window to wider-than-tall → **Expect** side-by-side.
4. Resize to taller-than-wide → **Expect** stacked.
5. Confirm no orientation lock interferes with free resize.

## Docs check

- [ ] `docs/features/player.md` describes aspect-based player layout
- [ ] `docs/features/app-ui.md` `VideoPlayerLayout` row updated
- [ ] ADR-0059 present when the behavior ships
