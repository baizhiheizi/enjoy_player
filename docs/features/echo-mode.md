# Feature: Echo mode (shadow reading)

## MVP behavior

- Echo region stores line indices + start/end times (seconds).
- `normalizeEchoWindow`, `clampSeekTimeToEchoWindow`, `decideEchoPlaybackTime` match web `echo-utils.ts` semantics (segment end **pauses** and rewinds to segment start for replay — not auto-loop).
- `PlayerController` applies clamp / pause-and-rewind while echo active.
- State persisted in `echo_sessions` (latest session per `targetType` + `targetId`).
- **Shadow reading**: below the echo region, [`ShadowReadingPanel`](../../lib/features/shadow_reading/presentation/shadow_reading_panel.dart) supports mic recording (saved to `recordings`), a **compact take player** (one take visible at a time, defaulting to the newest; overflow menu to switch takes), **play/pause** with **elapsed / duration** on the dedicated **`media_kit`** preview player ([`recording_preview_player`](../../lib/core/audio/recording_preview_player.dart)), optional **pitch contour** analysis (FFmpeg PCM extract + YIN envelope — see `shadow_reading/`).

## Future

- Multi-line echo regions with draggable selection UI.
- Cloud pronunciation assessment (web parity).
