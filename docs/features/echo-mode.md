# Feature: Echo mode (shadow reading)

## MVP behavior

- Echo region stores line indices + start/end times (seconds).
- `normalizeEchoWindow`, `clampSeekTimeToEchoWindow`, `decideEchoPlaybackTime` match web `echo-utils.ts` semantics.
- `PlayerController` applies loop/clamp while echo active.
- State persisted in `echo_sessions` (latest session per `targetType` + `targetId`).

## Future

- Multi-line echo regions with draggable selection UI.
- Haptic / recording integration for pronunciation practice.
