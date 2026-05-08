# Feature: Echo mode (shadow reading)

## MVP behavior

- Echo region stores line indices + start/end times (seconds).
- `normalizeEchoWindow`, `clampSeekTimeToEchoWindow`, `decideEchoPlaybackTime` match web `echo-utils.ts` semantics (segment end **pauses** and rewinds to segment start for replay — not auto-loop).
- `PlayerController` applies clamp / pause-and-rewind while echo active.
- State persisted in `echo_sessions` (latest session per `targetType` + `targetId`).
- **Shadow reading**: below the echo region, [`ShadowReadingPanel`](../../lib/features/shadow_reading/presentation/shadow_reading_panel.dart) supports mic recording (saved to `recordings`), playback of takes via [`shadow_recording_playback`](../../lib/core/audio/shadow_recording_playback.dart) (Windows `PlaySound`, Linux CLI, `just_audio` elsewhere), optional **pitch contour** analysis (FFmpeg PCM extract + YIN envelope — see `shadow_reading/`).

## Future

- Multi-line echo regions with draggable selection UI.
- Cloud pronunciation assessment (web parity).
