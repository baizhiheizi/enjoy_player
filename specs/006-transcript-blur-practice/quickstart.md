# Quickstart: Transcript Blur (Practice / Listening-Focus Mode)

**Feature**: [spec.md](spec.md) · [research.md](research.md) ·
[data-model.md](data-model.md) ·
[contracts/transcript_blur_api.md](contracts/transcript_blur_api.md)
**Phase**: 1 (validation guide)
**Date**: 2026-07-08

This is a runnable validation guide for the transcript blur feature.
It covers **manual smoke scenarios** that prove the feature works
end-to-end across the supported platforms. It does **not** include
implementation code — that lives in `tasks.md` (next phase) and the
final implementation.

> **Platforms**: Android, iOS, macOS, Windows. (No Flutter web.)
> **Targets**: any library item with a transcript (local audio, local
> video, YouTube via the WebView engine, cloud-imported tracks).

---

## Prerequisites

1. App builds and runs: `flutter run -d <device>`.
2. A library item is opened that already has at least 10 transcript
   cues. If you don't have one:
   - Import a local `.srt` / `.vtt` via the **CC → Add subtitle**
     flow in the transcript picker, OR
   - Sign in and open a media item that has cloud captions.
3. Transcript panel is visible (right of player on desktop, bottom
   sheet on mobile).

---

## Manual validation scenarios

### Q-01 — Toggle on / off

**Goal**: Verify the toggle exists, turns blur on/off instantly, and
persists.

1. Open a media item. Confirm the transcript panel shows clear text.
2. Locate the **Blur practice** icon in the transcript panel toolbar.
   Tooltip on hover reads "Blur practice (focus on listening)".
3. Tap the icon.
   - **Expected**: every visible cue body becomes blurred within one
     frame; timestamps, recording badges, and rails stay sharp.
4. Close the app fully (swipe on mobile, ⌘Q on macOS, Alt+F4 on
   Windows).
5. Reopen the app and open the same media item.
   - **Expected**: blur practice mode is **still on** (persisted).

Pass criteria: Steps 3 and 5 both match.

### Q-02 — Desktop hover reveal

**Goal**: Verify hover reveals and re-blurs without flicker.

**Platforms**: macOS, Windows.

1. With blur practice on (Q-01), move the mouse pointer over the
   middle of cue 5.
   - **Expected**: cue 5's body text becomes clear within one frame.
2. Move the pointer away from cue 5.
   - **Expected**: cue 5 re-blurs within one frame.
3. Drag the pointer quickly from cue 5 → cue 6 → cue 7 in under a
   second.
   - **Expected**: only the cue currently under the pointer is
     revealed at any moment; no visible flicker; the prior cue
     re-blurs the moment the pointer leaves it.

Pass criteria: All three expectations.

### Q-03 — Active line is NEVER auto-revealed

**Goal**: Verify the spec's 2026-07-08 clarification — the active
playback cue is treated like every other cue.

1. With blur practice on, press play.
2. Watch the active line move through the transcript.
   - **Expected**: the active line stays blurred the entire time. No
     auto-reveal. No flicker between blurred and revealed.
3. Pause and manually seek to a later cue via the transport scrub bar.
   - **Expected**: the new active cue is blurred; the previous one is
     blurred.
4. Stop playback and let the playhead sit between cues.
   - **Expected**: zero cues are force-revealed; the panel stays
     fully blurred (unless a hover/tap-reveal is in flight).

Pass criteria: Steps 2, 3, 4.

### Q-04 — Mobile tap-reveal seek + hold

**Goal**: Verify tap seeks playback AND starts a 3-second hold.

**Platforms**: Android, iOS.

1. With blur practice on, pause playback.
2. Tap cue 8 (a blurred cue).
   - **Expected**: playback seeks to cue 8's start time AND cue 8
     becomes clear.
3. Wait 3 seconds without tapping.
   - **Expected**: cue 8 re-blurs within one frame, even though it is
     now the active cue (because playback did not leave it).
4. While cue 8 is still revealed (within the 3 s), tap cue 12.
   - **Expected**: cue 8 re-blurs immediately; cue 12 becomes clear
     and the 3 s timer restarts.

Pass criteria: All three expectations.

### Q-05 — Tap-reveal on the active cue

**Goal**: Verify tap-reveal still works when the cue is already the
active cue.

1. With blur practice on, start playback; let cue 8 become active.
2. Tap cue 8 (the active, blurred cue).
   - **Expected**: cue 8 reveals for 3 seconds, then re-blurs.
3. Stop playback at cue 8 (still revealed).
   - **Expected**: the hold continues until expiry; it does NOT get
     extended just because the cue is "active".

Pass criteria: Both expectations.

### Q-06 — Hold-duration setting

**Goal**: Verify the hold-duration setting is reachable and applies.

1. Open **Settings → Transcript** (search "tap-reveal" if the section
   is collapsed).
2. Find the **Tap-reveal hold duration** slider (default 3 s). Set it
   to 7 seconds.
3. Go back to the transcript panel; with blur practice on, tap a
   cue.
   - **Expected**: cue stays clear for ~7 seconds.
4. Restart the app and tap again.
   - **Expected**: cue still stays clear for 7 seconds (persisted).

Pass criteria: Both expectations.

### Q-07 — Reduced motion

**Goal**: Verify reduced-motion users get instant on/off.

**Platforms**: any.

1. Enable **Reduce motion** in the OS / accessibility settings:
   - macOS: System Settings → Accessibility → Display → Reduce motion.
   - iOS: Settings → Accessibility → Motion → Reduce Motion.
   - Windows: Settings → Accessibility → Visual effects → Animation
     effects → Off.
   - Android: Settings → Accessibility → Remove animations.
2. With blur practice on, hover across adjacent cues.
   - **Expected**: blur/unblur is instant — no fade transition.
3. Toggle the toolbar icon on/off.
   - **Expected**: the blur disappears / appears instantly; no fade.

Pass criteria: Both expectations.

### Q-08 — Screen reader parity

**Goal**: Verify TalkBack / VoiceOver reads blurred cues normally.

**Platforms**: iOS (VoiceOver), Android (TalkBack), macOS (VoiceOver).

1. Enable the platform screen reader.
2. With blur practice on, swipe to focus a blurred cue.
   - **Expected**: the reader announces the full cue text and
     timestamp, exactly as if blur were off.
3. Focus the **Blur practice** toggle.
   - **Expected**: the reader announces the toggle's on/off state
     (e.g., "Blur practice, switch, on").

Pass criteria: Both expectations.

### Q-09 — Echo mode

**Goal**: Verify blur still applies inside the echo region.

1. With blur practice on, enable **Echo mode** for the current
   transcript (use the existing echo entry point).
2. Confirm cues inside the echo card are blurred; hover/tap-reveal
   still works on them.
3. Disable blur practice.
   - **Expected**: echo cues return to normal rendering immediately.

Pass criteria: All three expectations.

### Q-10 — Empty transcript (toggle disabled)

**Goal**: Verify the toggle is disabled when no lines exist.

1. Open a media item with no transcript and confirm the empty state.
2. The **Blur practice** toolbar MUST show but the toggle MUST be
   disabled with the "No transcript lines to practice with" tooltip.

Pass criteria: Both expectations.

---

## Automated checks (run in CI / pre-PR)

```bash
# 1. Generate code (new @Riverpod notifier produces .g.dart).
dart run build_runner build --delete-conflicting-outputs

# 2. Static analysis.
flutter analyze

# 3. Unit + widget tests for the new code paths.
flutter test test/features/transcript/transcript_blur_preferences_provider_test.dart
flutter test test/features/transcript/transcript_blur_tile_test.dart
flutter test test/features/transcript/transcript_blur_hold_test.dart
flutter test test/features/transcript/transcript_blur_active_line_stays_blurred_test.dart
flutter test test/features/transcript/transcript_blur_long_list_perf_test.dart

# 4. Full suite to catch regressions.
flutter test
```

The new tests above cover the scenarios Q-01 (toggle on/off),
Q-02 (hover), Q-03 (active line never revealed), Q-04 (tap-reveal
seek+hold), and a long-list performance smoke (10 000 lines).

---

## Rollback plan

The feature is fully isolated behind `prefs.transcript_blur_practice_enabled`
(default `false`). If a regression is reported:

1. Bump the default to `false` (already the default — no action
   needed).
2. Force `enabled = false` at hydration time in
   `TranscriptBlurPreferencesCtrl.build` if a kill switch is needed
   urgently; remove once the regression is fixed.

No migrations are required — the only persisted data is two new
key/value rows in `settings`, which are harmless when the feature is
turned off.
