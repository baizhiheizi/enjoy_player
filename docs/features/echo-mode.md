# Feature: Echo mode (shadow reading)

## MVP behavior

- Echo region stores line indices + start/end times (seconds). The line indices are the source of truth; the cached seconds are re-derived from the current transcript at enforcement time (falling back to the cached value when no transcript is loaded), so a re-segmented transcript yields fresh boundaries.
- `normalizeEchoWindow`, `clampSeekTimeToEchoWindow`, `decideEchoPlaybackTime` match web `echo-utils.ts` semantics (segment end **pauses** and rewinds to segment start for replay — not auto-loop).
- `normalizeEchoWindow` also widens windows narrower than `endGuard + seekEpsilon`: such a window has no playable position — the end guard fires pause-and-rewind the instant the rewind-to-start seek lands, looping seek → pause → seek (issue #659; reachable via arbitrary start/end query params or a sub-40 ms cue). Media too short for even the minimum drops the window instead of churning enforcement.
- Open-time poster capture is skipped when a session restores to position 0 with echo active: the capture seek would be corrected back into the echo window by the live enforcer, capturing the wrong frame and pausing/churning playback right after open (issue #659). A later open without echo still captures.
- `PlayerController` applies clamp / pause-and-rewind while echo active. The reactive per-tick correction and the proactive seek clamp are serialized through one [`EchoEnforcer`](../../lib/features/player/application/echo_enforcer.dart) — a single in-flight seek/pause at a time so they can't interleave. Enforcement runs on every position event, so the segment-end pause-and-rewind fires within ~50 ms of the boundary (not deferred to the 400 ms session-emit bucket).
- State persisted in `echo_sessions` (latest session per `targetType` + `targetId`). Position is durably written mid-playback: the [`PlaybackSessionPersister`](../../lib/features/player/application/playback_session_persister.dart) coalesces updates on a 450 ms debounce but forces a flush once pending data is older than ~2 s, so a crash never loses more than ~2 s of progress at any playback rate.
- **Shadow reading**: below the echo region, [`ShadowReadingPanel`](../../lib/features/shadow_reading/presentation/shadow_reading_panel.dart) supports mic recording (saved to `recordings`); optional **pitch contour** analysis (FFmpeg PCM extract + YIN envelope — see `shadow_reading/`), `PitchContourSection` can be **parent-driven** (`expanded` / `showHeader: false` for chart-only body). The player embed renders the **takes strip** + dock-owned record controls (see *Presentation* below); the vocabulary embed keeps the **idle toolbar** (pitch icon, centered FAB, play + **pronunciation assess** + more **grouped at center** — delete in more menu with **confirm dialog**) and **recording-only focus** (FAB + countdown vs segment; pitch/takes hidden).
- **Transcript**: while echo is active, only cues inside the current echo segment show the “active line” highlight (avoids gap/overlap confusing a cue outside the brown region). Tapping another cue still seeks/plays from that cue and recenters the echo segment on it (`PlayerInteractions._seekLine`).
- **Pronunciation assessment**: Enjoy Worker Azure token + native `azure_speech` assessment; results stored in `pronunciation_score` + `assessment_json` on the recording row, queued for metadata sync. Toolbar **sparkles** runs assessment; **score badge** re-opens [`AssessmentResultDialog`](../../lib/features/shadow_reading/presentation/assessment_result_dialog.dart) / sheet via Enjoy modals on the **root** navigator so results clear the YouTube surface host ([ADR-0065](../decisions/0065-enjoy-modals-root-navigator.md); wide uses the **rail breakpoint** 900px, not the transcript 720px). Take menu shows per-take scores and **Re-assess** when the current take already has JSON. **Languages**: Azure locale comes from the recording/media language via [`resolveAzureAssessmentLocaleForPractice`](../../lib/core/application/app_language_catalog.dart). Unknown media tags (`und`, empty — common for YouTube imports) fall back to the learner's focus language; real unsupported languages still disable the control with an explanatory tooltip. **Touch / a11y**: idle pitch / play / overflow controls use **≥44×44** hit targets where possible; the assessment badge control is **44×44** with explicit **Semantics** (label + button) and uses `MaterialType.transparency` when unscored so Android hit-testing does not drop taps on a transparent canvas Material. The takes cluster is wrapped in `FittedBox(scaleDown)` so play / assess / menu stay inside the half-width hit box on narrow phones.
- **Microphone selection**: the recorder reads its capture device from [`recordingInputDeviceCtrlProvider`](../../lib/features/shadow_reading/application/recording_input_device_controller.dart) and passes it to [`RecordConfig.device`](../../lib/features/shadow_reading/presentation/shadow_reading_panel.dart) on every take. Settings → **Recording → Microphone** opens a picker (`Auto` plus every device returned by `AudioRecorder.listInputDevices()`); the choice is persisted to [`SettingsKeys.prefsRecordingInputDeviceId`](../../lib/data/db/settings_keys.dart). When no preference is set, [`pickPreferredInputDeviceId`](../../lib/features/shadow_reading/application/recording_input_device_picker.dart) skips known **virtual / loopback / shared-audio** capture devices (GlideX, VoiceMeeter, VB-Audio CABLE, Stereo Mix, NVIDIA Broadcast, …) so Windows defaults like *GlideX Shared Audio* don't silently capture only zeros.
- **Share practice poster**: when the open media has at least one local recording **and** echo mode is active, the **top bar** shows the **Share** pill ([`SharePracticePosterButton`](../../lib/features/share_poster/presentation/share_practice_poster_button.dart)) next to Subtitles (icon + label from 1100px, per the Duet board). It opens a preview sheet ([`PracticePosterPreviewSheet`](../../lib/features/share_poster/presentation/practice_poster_preview_sheet.dart)) with a **9:16** branded poster (cover, title, hero line, takes / sentences / spoken stats, QR to `https://player.enjoy.bot`). **iOS / Android** export via the system share sheet (`share_plus`, e.g. WeChat); **Windows / macOS** save PNG via file picker. The poster is **echo-tailored**: the cover uses the live video frame captured from the active echo region (with a YouTube WebView fallback), and the hero quote is resolved from the echo region's transcript lines with ellipsis on cut — see [`share-poster.md`](share-poster.md). The share pill is **not** rendered in the top bar while echo mode is off; users who want to share earlier takes enter echo mode first (or rely on the share entry on Library rows) — see [ADR-0068](../decisions/0068-shadow-toolbar-share-button.md). The vocabulary embed's toolbar keeps its own share entry.

## Future

- Multi-line echo regions with draggable selection UI.


## Presentation — the Echo lens (Duet, ADR-0093)

The loop block stands on the ground inside you-colored corner brackets
(20px arms, 10px outer radius; 22 / 9 on phones — no full border). The section gutter
shows the loop start time once (mono, you-ink) next to a
`LOOP · LINE n · x.x S` overline; loop lines carry no gutter chrome of
their own. Loop lines grow in place: Literata 500 sized by the board —
one line clamps 22–28px with viewport width, two lines 20–24, three or
more 19; the video column uses 20/18 and phones 23/20. The video column
and phones drop the loop's time gutter, and the takes strip aligns with
the loop text (66px inset on desktop). The
Earlier / Later line pill handles (paper pill on youLine, docked over
the top and bottom bracket edges, hidden while recording) drive the
same `expandEchoBackward` / `shrinkEchoForward` controller calls as
before. Neighbour lines fade by distance through `echoLensOpacity`
(0.65 / 0.35 / 0.2) at the board's lens sizes (16 / 15 / 14
desktop, 14.5 / 13.5 in the video column and on phones) and restore to full ink on hover. While a take is recording,
the label swaps to a pulsing dot plus `RECORDING TAKE n`, and a 4px
progress bar with the localized countdown caption runs under the loop
lines. The old merged card's side rail, surface shell, in-card
dividers, and active-line plate are gone; lines sit flat inside the
brackets.

### Takes strip and dock (player embed)

In the player, the panel below the loop renders as the board's takes
strip instead of the idle toolbar: a `TAKES` overline, one stadium chip
per take (play circle, take number, mono duration, an uncolored score
chip that re-opens the assessment, or a `Score` action that runs it),
the "press R and say it back" hint when the region has no takes, and
the Pitch pill on the right toggling the contour. The chips render as
one horizontal line: touch pans natively; on desktop the strip carries
a scrollbar thumb (hover to drag) and maps the vertical mouse wheel to
the horizontal axis — claimed through the pointer-signal resolver, so
the page behind does not scroll while the line overflows (an
unoverflowed line leaves the wheel to the page). Record / cancel /
stop live in the dock (Original + record group; Cancel + stop ring
while recording), so the panel renders nothing while recording. The
vocabulary "Echo reading" embed keeps the centered-FAB toolbar with the
take menu (delete with confirm dialog lives there; the player strip
draws none — where take management lands in the player is tracked as an
open decision in
[`docs/design/duet/STATUS.md`](../design/duet/STATUS.md)).
