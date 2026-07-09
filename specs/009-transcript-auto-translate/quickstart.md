# Quickstart: Transcript Auto-Translate

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Validation/run guide — not an implementation reference. Implementation detail
lives in `tasks.md` (produced by `/speckit-tasks`).

## Prerequisites

- Device/emulator on Android, iOS, macOS, or Windows (no web).
- Signed in with **native** language set and different from the media’s primary
  transcript language (e.g. primary `en`, native `zh`).
- A library item with a usable **primary** transcript (≥100 lines preferred for
  lazy-priority checks; a short clip is fine for picker smoke).
- Translation service reachable (Enjoy worker default or configured BYOK
  translation/LLM modality).

## Commands

```bash
# Required when @riverpod / Drift annotations change (expected for AutoTranslateCtrl):
dart run build_runner build

flutter analyze
flutter test
```

Targeted tests (adjust paths to match tasks.md once written):

```bash
flutter test test/features/transcript/auto_translate_scheduler_test.dart
flutter test test/features/transcript/auto_translate_skeleton_test.dart
flutter test test/features/transcript/subtitle_track_picker_sheet_test.dart
```

## Validation scenarios

### V1 — Select Auto translate (happy path)

1. Open media with primary transcript; open subtitle picker → Translation.
2. **Expect**: **Auto translate** appears after **None**, with language/AI cue
   ([picker contract](./contracts/auto-translate-picker-ui.md)).
3. Select Auto translate.
4. **Expect**: secondary lines fill near the current playback position first;
   list/playback remain usable; no blocking modal.
5. **Expect**: completed lines persist under primary with existing secondary
   styling.

Pass: FR-001–FR-006, SC-002/SC-003.

### V2 — Lazy priority on seek

1. With Auto translate running on a long transcript, seek far from the start.
2. **Expect**: newly nearby pending lines translate before distant pending
   lines; already-ready lines are not redone.

Pass: [scheduler contract](./contracts/auto-translate-scheduler.md) S1–S2.

### V3 — Re-translate

1. With Auto translate selected and many lines ready, open picker and choose
   **Re-translate** (confirm if prompted).
2. **Expect**: progress returns; lines refresh as new results arrive; playback
   continues.

Pass: FR-007/FR-008, SC-006.

### V4 — Persist / resume

1. Partially complete Auto translate; leave media; reopen; select Auto translate.
2. **Expect**: finished lines appear immediately; only remaining lines schedule.

Pass: FR-009/FR-010, SC-005.

### V5 — Blocked states

1. Signed out → select Auto translate → **Expect** sign-in guidance, no spin forever.
2. Native language equals primary language → **Expect** explanation, no translate calls.
3. Force transient line failures in tests → **Expect** retries then calm failed
   state without aborting the whole job.

Pass: FR-011/FR-012, SC-004/SC-007.

### V6 — Coexistence

1. Media that already has a non-AI translation track (e.g. YouTube bilingual).
2. **Expect**: that track remains selectable; Auto translate remains an
   additional option; switching away from Auto translate shows the other track.

Pass: FR-013/FR-016.

## Manual performance check

On a ~500-line transcript with Auto translate running: play, scrub, and scroll.
Reviewers should not observe sustained hitching attributable to the scheduler
(SC-008). Note device and result in the PR.
