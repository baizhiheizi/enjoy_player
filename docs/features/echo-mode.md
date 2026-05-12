# Feature: Echo mode (shadow reading)

## MVP behavior

- Echo region stores line indices + start/end times (seconds).
- `normalizeEchoWindow`, `clampSeekTimeToEchoWindow`, `decideEchoPlaybackTime` match web `echo-utils.ts` semantics (segment end **pauses** and rewinds to segment start for replay — not auto-loop).
- `PlayerController` applies clamp / pause-and-rewind while echo active.
- State persisted in `echo_sessions` (latest session per `targetType` + `targetId`).
- **Shadow reading**: below the echo region, [`ShadowReadingPanel`](../../lib/features/shadow_reading/presentation/shadow_reading_panel.dart) supports mic recording (saved to `recordings`), **idle toolbar** (pitch icon, centered FAB, play + **pronunciation assess** + more **grouped at center** — delete in more menu with **confirm dialog**), **recording-only focus** (FAB + countdown vs segment; pitch/takes hidden), optional **pitch contour** analysis (FFmpeg PCM extract + YIN envelope — see `shadow_reading/`), `PitchContourSection` can be **parent-driven** (`expanded` / `showHeader: false` for chart-only body).
- **Transcript**: while echo is active, only cues inside the current echo segment show the “active line” highlight (avoids gap/overlap confusing a cue outside the brown region). Tapping another cue still seeks/plays from that cue and recenters the echo segment on it (`PlayerInteractions._seekLine`).
- **Pronunciation assessment**: Enjoy Worker Azure token + native `azure_speech` assessment; results stored in `pronunciation_score` + `assessment_json` on the recording row, queued for metadata sync. Toolbar **sparkles** runs assessment; **score badge** re-opens [`AssessmentResultDialog`](../../lib/features/shadow_reading/presentation/assessment_result_dialog.dart). Take menu shows per-take scores and **Re-assess** when the current take already has JSON.
- **Microphone selection**: the recorder reads its capture device from [`recordingInputDeviceCtrlProvider`](../../lib/features/shadow_reading/application/recording_input_device_controller.dart) and passes it to [`RecordConfig.device`](../../lib/features/shadow_reading/presentation/shadow_reading_panel.dart) on every take. Settings → **Recording → Microphone** opens a picker (`Auto` plus every device returned by `AudioRecorder.listInputDevices()`); the choice is persisted to [`SettingsKeys.prefsRecordingInputDeviceId`](../../lib/data/db/settings_keys.dart). When no preference is set, [`pickPreferredInputDeviceId`](../../lib/features/shadow_reading/application/recording_input_device_picker.dart) skips known **virtual / loopback / shared-audio** capture devices (GlideX, VoiceMeeter, VB-Audio CABLE, Stereo Mix, NVIDIA Broadcast, …) so Windows defaults like *GlideX Shared Audio* don't silently capture only zeros.

## Future

- Multi-line echo regions with draggable selection UI.
