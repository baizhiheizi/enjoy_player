# Implementation Plan: Transcript Auto-Translate

**Branch**: `009-transcript-auto-translate` (create/switch when implementing; Spec Kit setup reported empty BRANCH while on current checkout) | **Date**: 2026-07-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/009-transcript-auto-translate/spec.md`

## Summary

Add **Auto translate** to the subtitle picker’s translation list. Selecting it
creates/resumes a durable `source: 'ai'` transcript track whose timeline mirrors
the primary cue timings, sets it as `secondaryTranscriptId`, and runs a **lazy,
playback-priority scheduler** that calls the existing single-line
`translationServiceProvider` with bounded concurrency and graceful retries.
Learners see progressive secondary lines without blocking playback, can
**Re-translate**, and reopen media without redoing finished work. No Drift
schema migration in v1.

## Technical Context

**Language/Version**: Dart ^3.12.0, Flutter stable, Riverpod 3.x
(`flutter_riverpod` / `riverpod_annotation`).

**Primary Dependencies**:
- Existing AI stack: `translationServiceProvider` → `TranslationCapability`
  (Enjoy `POST /translations` or BYOK per modality routing).
- Drift `AppDatabase` DAOs (`transcriptDao`, `echoSessionDao`).
- `logging` via `logNamed` (no `print()`).
- Shared UI: subtitle picker modules, `AuthRequiredCallout`, Enjoy dialogs/sheets.

**Storage**: Drift `Transcripts` + `EchoSessions` only. AI track id via
`enjoyTranscriptId(..., language, 'ai')`. Progressive `timelineJson` upserts.
**No schema migration (v1).**

**Testing**: `flutter test` — unit tests for scheduler priority/retry/skeleton/
staleness; repository tests for AI upsert + secondary wiring; widget tests for
picker Auto translate + Re-translate + blocked states. Fake
`TranslationCapability` for deterministic scheduling tests.
`dart run build_runner build` required for new `@Riverpod` controller(s).

**Target Platform**: Android, iOS, macOS, Windows. No Flutter web.

**Project Type**: Flutter native mobile/desktop app.

**Performance Goals**:
- First nearby translated lines within ~10 s under normal connectivity (SC-002).
- Max 2 concurrent translate calls; seek re-prioritizes without request storms.
- Playback + transcript scroll remain usable on ~500-line samples (SC-003/SC-008);
  avoid heavy work in `build` / list item builders; coalesce Drift writes.

**Constraints**:
- Local-first; translation calls only when signed in / eligible.
- Repository stays UI-free; read `effectiveNativeLanguage` in application layer.
- Do not instantiate `media_kit` `Player()` outside player engine/controller.
- Coexist with YouTube bilingual secondary tracks (ADR-0036); Auto translate is
  an additional option, not a replacement.
- Single-line translate API only — no new batch HTTP endpoint in this change.

**Scale/Scope**: Typical lessons hundreds of lines; must tolerate multi-thousand
line transcripts via lazy fill. One AI track per media + target language.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Post-design re-check (after Phase 0 + Phase 1):** ✅ PASS — no Constitution
exception. Design stays in feature-first transcript + AI capability boundaries;
persistence via existing Drift tables; Riverpod controller (no global singleton);
ARB + shared picker primitives; performance budget and docs/ADR called out;
`build_runner` + `flutter analyze` / `flutter test` are the verification gates.

### I. Architecture and Code Quality

- ✅ Changes live under:
  - `lib/features/transcript/application/` — `AutoTranslateCtrl` (scheduler,
    eligibility, UI state), providers.
  - `lib/features/transcript/data/transcript_repository.dart` — ensure AI
    skeleton, progressive timeline upsert helpers (UI-free).
  - `lib/features/transcript/presentation/` — picker tile/option, Re-translate
    affordance, calm progress cues in list/picker.
  - Reuse `lib/features/ai/application/ai_services.dart`
    (`translationServiceProvider`) — no raw HTTP from widgets.
  - Reuse `lib/core/application/app_preferences_provider.dart` /
    `app_language_catalog.dart` for native language + `workerLanguageBase`.
- ✅ Domain models UI-free; Drift DAOs only for persistence.
- ✅ Riverpod keepAlive/family controller; no new mutable global singleton.
- ✅ No `print()`; no new `media_kit` `Player()`.

### II. Testing Defines the Contract

Required automated tests:
- **Unit (scheduler)**: priority by playback index; concurrency ≤2; retry
  backoff; generation discard on Re-translate; pause on secondary change.
- **Unit (skeleton / staleness)**: timeline length/timings match primary;
  `referenceId` mismatch triggers rebuild/Re-translate path.
- **Repository**: upsert AI track; set secondary; progressive text fill;
  reopen leaves ready lines intact.
- **Widget**: Auto translate option after None; selection starts job (faked);
  Re-translate visible only when Auto translate selected; blocked signed-out /
  same-language copy without raw exceptions.
- **Manual**: long-transcript smoothness (document in PR) when automation cannot
  prove frame budget cheaply.

`dart run build_runner build` after `@Riverpod` additions.

### III. User Experience Consistency

- ✅ New strings in `lib/l10n/*.arb` + `flutter gen-l10n`.
- ✅ Picker uses existing sheet/dialog presentation and tile patterns
  (`EnjoyTappable*` / list tiles as today); confirm dialog for large Re-translate.
- ✅ Docs: update `docs/features/transcript.md` (remove Future auto-translate
  bullet; document behavior).

### IV. Performance Is a Requirement

- ✅ Budget: ≤2 in-flight requests; progressive upserts; no full-transcript
  translate before first paint of nearby lines; keep matcher inputs timing-aligned
  so list code paths stay unchanged.
- Evidence: unit tests for scheduling; manual scroll/play check on ~500 lines
  (quickstart V-performance).

### V. Documentation and Traceability

- ✅ Feature doc: `docs/features/transcript.md`.
- ✅ New ADR: `docs/decisions/0037-transcript-auto-translate.md` (AI track
  persistence, skeleton, scheduler, staleness) — number confirmed free after 0036.
- ✅ Link from `docs/decisions/README.md` when adding the ADR.
- No Constitution exception.

## Project Structure

### Documentation (this feature)

```text
specs/009-transcript-auto-translate/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── auto-translate-picker-ui.md
│   └── auto-translate-scheduler.md
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks) — not created here
```

### Source Code (repository root)

```text
lib/features/transcript/
├── application/
│   ├── auto_translate_controller.dart      # NEW — job + scheduler
│   ├── auto_translate_controller.g.dart    # generated
│   ├── transcript_line_alignment.dart      # reuse
│   ├── active_transcript_provider.dart     # reuse secondary id
│   └── transcript_lines_provider.dart      # reuse secondary lines
├── data/
│   └── transcript_repository.dart          # ensure AI track + progressive upsert
└── presentation/
    ├── subtitle_track_picker_sheet.dart    # wire Auto translate + Re-translate
    ├── subtitle_track_picker_tiles.dart    # AutoTranslateOptionTile
    ├── subtitle_track_picker_actions.dart  # optional Re-translate action
    └── transcript_scrollable_list.dart     # calm pending placeholder if needed

lib/features/ai/application/ai_services.dart   # reuse translationServiceProvider

lib/l10n/app_en.arb / app_zh.arb / app_zh_CN.arb

test/features/transcript/
├── auto_translate_scheduler_test.dart      # NEW
├── auto_translate_skeleton_test.dart       # NEW
└── subtitle_track_picker_sheet_test.dart   # extend

docs/features/transcript.md                 # update
docs/decisions/0037-transcript-auto-translate.md  # NEW
docs/decisions/README.md                    # link ADR
```

**Structure Decision**: Keep all orchestration inside the **transcript** feature
application layer; call the existing **AI** translation service rather than
adding a parallel HTTP client. Presentation changes stay in the already-split
subtitle picker modules. No new top-level feature package.

## Complexity Tracking

> No Constitution violations requiring justification.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

## Phase 0 & Phase 1 outputs

| Artifact | Path |
|----------|------|
| Research | [research.md](./research.md) |
| Data model | [data-model.md](./data-model.md) |
| Contracts | [contracts/auto-translate-picker-ui.md](./contracts/auto-translate-picker-ui.md), [contracts/auto-translate-scheduler.md](./contracts/auto-translate-scheduler.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Implementation notes (for `/speckit-tasks`)

1. Repository helpers: `ensureAutoTranslateTrack`, `updateAutoTranslateLineText`,
   staleness check vs primary.
2. `AutoTranslateCtrl`: eligibility → ensure skeleton → set secondary → run loop.
3. Picker: Auto translate option + Re-translate + filter AI row from generic list.
4. Optional compact pending placeholder under primary when secondary text empty
   **and** Auto translate job running (avoid blank confusion — US3).
5. ARB strings; ADR-0037; transcript feature doc.
6. Verify: `dart run build_runner build`, `flutter analyze`, `flutter test`,
   quickstart V1–V6 + manual performance note.
