# Feature: Echo mode (shadow reading)

## MVP behavior

- Echo region stores line indices + start/end times (seconds).
- `normalizeEchoWindow`, `clampSeekTimeToEchoWindow`, `decideEchoPlaybackTime` match web `echo-utils.ts` semantics (segment end **pauses** and rewinds to segment start for replay — not auto-loop).
- `PlayerController` applies clamp / pause-and-rewind while echo active.
- State persisted in `echo_sessions` (latest session per `targetType` + `targetId`).
- **Shadow reading**: below the echo region, [`ShadowReadingPanel`](../../lib/features/shadow_reading/presentation/shadow_reading_panel.dart) supports mic recording (saved to `recordings`), **idle toolbar** (pitch icon, centered FAB, play + more **grouped at center** — delete in more menu with **confirm dialog**), **recording-only focus** (FAB + countdown vs segment; pitch/takes hidden), optional **pitch contour** analysis (FFmpeg PCM extract + YIN envelope — see `shadow_reading/`), `PitchContourSection` can be **parent-driven** (`expanded` / `showHeader: false` for chart-only body).
- **Transcript**: while echo is active, only cues inside the current echo segment show the “active line” highlight (avoids gap/overlap confusing a cue outside the brown region). Tapping another cue still seeks/plays from that cue and recenters the echo segment on it (`PlayerInteractions._seekLine`).

## Future

- Multi-line echo regions with draggable selection UI.
- Cloud pronunciation assessment (web parity).
