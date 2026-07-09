---
description: "Task list for transcript auto-translate"
---

# Tasks: Transcript Auto-Translate

**Input**: Design documents from `/specs/009-transcript-auto-translate/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md (all present).

**Tests**: Automated tests are required for changed behavior (Constitution II / plan.md). Manual performance smoke for ~500-line scrolling is documented in [quickstart.md](quickstart.md) and remains a polish-phase verification note.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `lib/features/transcript/{application,data,domain,presentation}/`
- **Shared / AI**: `lib/features/ai/application/`, `lib/core/application/`, `lib/core/ids/`
- **Tests**: `test/features/transcript/`
- **Feature docs**: `docs/features/transcript.md`
- **ADRs**: `docs/decisions/0037-transcript-auto-translate.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm target paths and documentation touch points before new files are added.

- [x] T001 Verify feature-first target paths exist under `lib/features/transcript/{application,data,domain,presentation}/` and `test/features/transcript/` (create `domain/` only if missing)
- [x] T002 [P] Confirm docs touch points: update `docs/features/transcript.md` on ship; add ADR `docs/decisions/0037-transcript-auto-translate.md` and link from `docs/decisions/README.md` (content written in Polish phase)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain models, ARB keys, repository AI-track helpers, and controller shell that ALL user stories depend on. No Drift schema migration (research R7).

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 [P] Add domain models in `lib/features/transcript/domain/auto_translate.dart`: `AutoTranslateJobStatus` (`idle`/`running`/`paused`/`blocked`/`completed`/`failed`), `AutoTranslateBlockReason`, `AutoTranslateLineStatus`, `AutoTranslateUiState` (mediaId, status, blockReason, aiTranscriptId, primaryTranscriptId, targetLanguage, generation, pending/failed counts), plus pure helpers `autoTranslateFingerprint(...)` and `orderPendingLineIndexes({required int anchorIndex, required List<int> pending})` per [data-model.md](data-model.md) and [contracts/auto-translate-scheduler.md](contracts/auto-translate-scheduler.md)
- [x] T004 [P] Add English ARB keys (+ `@key` metadata) to `lib/l10n/app_en.arb` for at least: `subtitlesAutoTranslate`, `subtitlesAutoTranslateLanguageChip`, `subtitlesAutoTranslateRetranslate`, `subtitlesAutoTranslateRetranslateConfirmTitle`, `subtitlesAutoTranslateRetranslateConfirmBody`, `subtitlesAutoTranslateProgress`, `subtitlesAutoTranslatePendingLine`, `subtitlesAutoTranslateBlockedSignedOut`, `subtitlesAutoTranslateBlockedSameLanguage`, `subtitlesAutoTranslateBlockedNoPrimary`, `subtitlesAutoTranslateBlockedCredits`, `subtitlesAutoTranslateFailed`, `subtitlesAutoTranslateRetry` (friendly copy; no raw exceptions)
- [x] T005 [P] Mirror the same ARB keys in `lib/l10n/app_zh.arb` and `lib/l10n/app_zh_CN.arb`
- [x] T006 Add repository helpers in `lib/features/transcript/data/transcript_repository.dart`: `ensureAutoTranslateTrack({mediaId, primaryTranscriptId, targetLanguage, primaryLines})` (upsert `source: 'ai'` via `enjoyTranscriptId`, copy timings into empty-text skeleton, set `referenceId` to primary id), `updateAutoTranslateLineText({aiTranscriptId, lineIndex, text})`, `isAutoTranslateTrackStale({aiRow, primaryId, primaryLines})`, and `clearAutoTranslateTexts({aiTranscriptId})` for Re-translate; keep repository UI-free
- [x] T007 [P] Unit-test skeleton/fingerprint/order helpers in `test/features/transcript/auto_translate_skeleton_test.dart` (timeline length/timings match primary; `orderPendingLineIndexes` prefers anchor; stale when `referenceId` mismatches)
- [x] T008 [P] Unit-test repository AI upsert/progressive fill in `test/features/transcript/auto_translate_repository_test.dart` (ensure track, set secondary, fill one line, reopen leaves ready text)
- [x] T009 Create `AutoTranslateCtrl` shell in `lib/features/transcript/application/auto_translate_controller.dart` as `@Riverpod(keepAlive: true)` family keyed by `mediaId`: expose `AutoTranslateUiState`, methods `selectAutoTranslate()`, `pause()`, stubs for `retranslate()` / scheduler loop; read `effectiveNativeLanguage` here (not in repository); log via `logNamed('auto_translate')` only
- [x] T010 Run `dart run build_runner build --delete-conflicting-outputs` for `auto_translate_controller.g.dart` and regenerate l10n after ARB changes

**Checkpoint**: Domain + ARB + repository helpers + controller shell exist and unit tests for skeleton/repo pass. User stories can start.

---

## Phase 3: User Story 1 — Choose Auto translate as the translation track (Priority: P1) 🎯 MVP

**Goal**: Learner can select **Auto translate** in the translation subtitle list; the AI track becomes secondary and translated lines appear under primary cues as they complete (even if the full scheduler is still minimal).

**Independent Test**: Open media with a primary transcript, open the subtitle picker → Translation, select **Auto translate**, and confirm it is the active translation selection (summary shows Auto translate + language) and secondary text begins appearing under primary lines. Selecting **None** clears secondary.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T011 [P] [US1] Extend `test/features/transcript/subtitle_track_picker_sheet_test.dart` to assert Translation section order **None → Auto translate → other tracks**, AI `source: 'ai'` rows are not duplicated in the generic list, and selecting Auto translate invokes controller/repository secondary wiring (fakes)
- [x] T012 [P] [US1] Widget/unit test in `test/features/transcript/auto_translate_select_test.dart`: eligible `selectAutoTranslate` ensures AI track, sets `secondaryTranscriptId`, starts job `running`; selecting None pauses and clears secondary

### Implementation for User Story 1

- [x] T013 [P] [US1] Add `AutoTranslateOptionTile` in `lib/features/transcript/presentation/subtitle_track_picker_tiles.dart` (label, language chip, AI/auto badge per [contracts/auto-translate-picker-ui.md](contracts/auto-translate-picker-ui.md); no delete on this row)
- [x] T014 [US1] Wire Auto translate into `lib/features/transcript/presentation/subtitle_track_picker_sheet.dart` translation `RadioGroup`: insert option after `NoneOptionTile`; filter `source == 'ai'` from mapped tracks; on select call `autoTranslateCtrlProvider(mediaId).notifier.selectAutoTranslate()`; update `SelectionSummary` collapsed label for Auto translate + language
- [x] T015 [US1] Implement eligibility + select path in `lib/features/transcript/application/auto_translate_controller.dart`: require signed-in, primary present, `workerLanguageBase(source) != workerLanguageBase(native)`; on success `ensureAutoTranslateTrack` → `setSecondaryTranscript` → `status=running`; on block set `blocked` + reason without spinning forever
- [x] T016 [US1] Implement a minimal translate loop in `lib/features/transcript/application/auto_translate_controller.dart` that translates pending lines via `translationServiceProvider` (sequential or ≤2 concurrent), upserts each success with `updateAutoTranslateLineText`, and stops cleanly on `pause()` / secondary change away from AI track — enough for progressive display (full priority/retry polish is US2)
- [x] T017 [US1] Confirm secondary rendering reuses `secondaryTranscriptLinesForMediaProvider` + `TranscriptSecondaryMatcher` in `lib/features/transcript/presentation/transcript_scrollable_list.dart` with no parallel display path; empty AI texts simply omit secondary until filled

**Checkpoint**: US1 MVP — Auto translate is selectable, secondary AI track wires correctly, lines fill progressively, None/other tracks switch away.

---

## Phase 4: User Story 2 — Lazy, scheduled translation that stays out of the way (Priority: P1)

**Goal**: Scheduler prefers lines near playback, re-prioritizes on seek, caps concurrency, and retries transient failures without blocking playback or aborting the whole job.

**Independent Test**: On a long transcript with Auto translate running, seek to the middle and confirm nearby pending lines complete before distant ones; inject a transient failure and confirm bounded retry then calm per-line failure while other lines continue.

### Tests for User Story 2

- [x] T018 [P] [US2] Unit test scheduler behavior in `test/features/transcript/auto_translate_scheduler_test.dart` with a fake `TranslationCapability`: concurrency never exceeds 2; pending order follows anchor index; seek reorders without redoing ready lines; transient fail retries ≤3 with backoff; `AuthFailure`/`CreditsFailure` stop new scheduling; older `generation` completions ignored

### Implementation for User Story 2

- [x] T019 [US2] Extract/pure-refine priority queue + worker pool in `lib/features/transcript/application/auto_translate_controller.dart` (or `lib/features/transcript/application/auto_translate_scheduler.dart` if split keeps the controller thin): max 2 in-flight, exponential backoff retries, seek debounce/re-prioritize per [contracts/auto-translate-scheduler.md](contracts/auto-translate-scheduler.md) S1–S10
- [x] T020 [US2] Wire playback anchor: read the active cue index (or nearest line) from existing transcript/player highlight providers used by the transcript list — update `priorityAnchorIndex` on position changes without cancelling successful in-flight work
- [x] T021 [US2] Map `guardAiCall` failures in the scheduler path: transient → retry; credits/auth → job `blocked`/`failed` with friendly reason; exhausted line retries → mark line failed, continue others; log via `logNamed` only

**Checkpoint**: US2 — lazy priority + graceful retry proven by scheduler unit tests; playback remains usable.

---

## Phase 5: User Story 3 — Friendly progress, empty, and error states (Priority: P2)

**Goal**: Calm, localized progress/pending/blocked/failed UX in picker and transcript — no raw exceptions, no blocking modals for routine progress.

**Independent Test**: Exercise starting (no lines ready), partial progress, signed-out block, same-language block, and job failure; confirm friendly copy + Retry/Re-translate affordances and no raw exception text.

### Tests for User Story 3

- [x] T022 [P] [US3] Widget tests in `test/features/transcript/auto_translate_status_ui_test.dart` (and/or extend picker sheet tests): blocked signed-out shows auth guidance; same-language shows explanation; running shows compact progress; failed shows friendly message without exception strings

### Implementation for User Story 3

- [x] T023 [P] [US3] Add compact progress/blocked banner or summary chip in `lib/features/transcript/presentation/subtitle_track_picker_sheet.dart` (and/or `subtitle_track_picker_sections.dart`) driven by `autoTranslateCtrlProvider` — non-blocking, localized
- [x] T024 [US3] Add calm pending placeholder for empty secondary text while Auto translate job is `running` in `lib/features/transcript/presentation/transcript_line_tile.dart` / `transcript_scrollable_list.dart` (e.g. subtle “Translating…” using `subtitlesAutoTranslatePendingLine`); hide when job not active
- [x] T025 [US3] Reuse `AuthRequiredCallout` (or equivalent) for signed-out Auto translate attempts from the picker path in `lib/features/transcript/presentation/subtitle_track_picker_sheet.dart`, consistent with lookup translation

**Checkpoint**: US3 — status UX is friendly and compact across picker + list.

---

## Phase 6: User Story 4 — Re-translate (Priority: P2)

**Goal**: When Auto translate is active, learner can **Re-translate** (confirm on large completed jobs); new generation refreshes lines without blocking playback.

**Independent Test**: With Auto translate selected and many lines ready, invoke Re-translate (confirm if shown); lines clear/refresh and progress returns; Re-translate is hidden when None/another track is selected.

### Tests for User Story 4

- [x] T026 [P] [US4] Widget/unit tests in `test/features/transcript/auto_translate_retranslate_test.dart`: Re-translate visible only when Auto translate secondary is active; confirm dialog shown when ready-line count ≥ threshold (e.g. 50); `retranslate()` bumps generation, clears texts, reschedules; older generation results ignored

### Implementation for User Story 4

- [x] T027 [P] [US4] Implement `retranslate()` in `lib/features/transcript/application/auto_translate_controller.dart`: `generation++`, `clearAutoTranslateTexts` (or rebuild skeleton), reset line retry state, set `running`, restart scheduler
- [x] T028 [US4] Add Re-translate control in `lib/features/transcript/presentation/subtitle_track_picker_actions.dart` and/or `AutoTranslateOptionTile` trailing action; show only when Auto translate is selected; use `showEnjoyDialog` (or existing confirm pattern) when ready lines ≥ threshold per QR-007; wire to controller

**Checkpoint**: US4 — Re-translate discoverable in ≤2 taps from picker when Auto translate is selected.

---

## Phase 7: User Story 5 — Persist and resume without duplicate work (Priority: P3)

**Goal**: Reopen / re-select Auto translate reuses finished lines; only empty (and eligible failed) lines schedule; primary change does not silently show mismatched translations.

**Independent Test**: Partially complete Auto translate, leave and reopen media, select Auto translate again — finished lines appear immediately and only remaining lines schedule. Change primary while Auto translate was active — stale AI text is not presented as valid without rebuild/Re-translate.

### Tests for User Story 5

- [x] T029 [P] [US5] Unit/repository tests in `test/features/transcript/auto_translate_resume_test.dart`: resume schedules only empty indexes; stale `referenceId`/fingerprint triggers rebuild or blocked-needs-retranslate path; switching target language uses distinct AI id (language in `enjoyTranscriptId`)

### Implementation for User Story 5

- [x] T030 [US5] On `selectAutoTranslate` / media open while secondary is AI track, hydrate from Drift in `lib/features/transcript/application/auto_translate_controller.dart`: skip ready lines; continue pending; if `isAutoTranslateTrackStale` then rebuild skeleton (or set blocked with Re-translate CTA) per FR-015
- [x] T031 [US5] When primary transcript id changes while Auto translate is selected, handle in controller (watch `activeTranscriptIdProvider`): invalidate/rebuild AI track tied to new primary; do not leave old secondary text displayed as matching

**Checkpoint**: US5 — persist/resume and staleness rules hold.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Docs, ADR, verification gates, coexistence, performance note.

- [x] T032 [P] Write ADR `docs/decisions/0037-transcript-auto-translate.md` (AI track persistence, skeleton, scheduler priorities, staleness, coexistence with YouTube bilingual) and link it from `docs/decisions/README.md`
- [x] T033 [P] Update `docs/features/transcript.md`: document Auto translate picker option, progressive job UX, Re-translate, persist/resume; remove “auto-translate” from the Future section
- [x] T034 Verify coexistence: selecting a non-AI translation track pauses Auto translate and shows that track; Auto translate remains available afterward (`lib/features/transcript/presentation/subtitle_track_picker_sheet.dart` + controller) — cover with an assertion in picker or select tests if not already
- [x] T035 Run `dart run build_runner build --delete-conflicting-outputs`, `flutter gen-l10n` (if needed), `flutter analyze`, and `flutter test` (include new auto-translate tests + existing transcript picker/secondary matcher suites)
- [x] T036 Walk [quickstart.md](quickstart.md) V1–V6; record manual ~500-line scroll/play performance note (SC-008) in the PR description

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS** all user stories
- **US1 (Phase 3)**: Depends on Foundational — 🎯 MVP
- **US2 (Phase 4)**: Depends on Foundational + US1 minimal loop (T016) — hardens scheduler
- **US3 (Phase 5)**: Depends on US1 select + running states (can overlap late US2)
- **US4 (Phase 6)**: Depends on US1 active selection + controller job model
- **US5 (Phase 7)**: Depends on repository helpers + US1 select path (resume/staleness)
- **Polish (Phase 8)**: Depends on all desired stories complete

### User Story Dependencies

- **US1 (P1)**: After Foundational — no dependency on US2–US5
- **US2 (P1)**: After US1 minimal loop — independently testable via fake translator
- **US3 (P2)**: After US1 (needs real status states); independently testable with faked `AutoTranslateUiState`
- **US4 (P2)**: After US1; Re-translate tests can fake a completed job
- **US5 (P3)**: After Foundational repository helpers; can proceed once US1 select exists

### Within Each User Story

- Tests marked first SHOULD fail before implementation where practical
- Repository/domain before controller behavior; controller before picker wiring
- Story checkpoint before moving to the next priority when staffing is serial

### Parallel Opportunities

- T002–T005 (docs note + domain + ARBs) in parallel during early Phase 2
- T007–T008 tests in parallel once T003/T006 land
- T011–T012 and T013 in parallel at start of US1
- T022 and T023 in parallel in US3
- T026 and T027 in parallel in US4
- T032 and T033 in parallel in Polish

---

## Parallel Example: User Story 1

```bash
# After Foundational checkpoint:
# Parallel tests + tile widget:
Task: "Extend subtitle_track_picker_sheet_test.dart for Auto translate option order"
Task: "Add auto_translate_select_test.dart for select/None wiring"
Task: "Add AutoTranslateOptionTile in subtitle_track_picker_tiles.dart"

# Then serial integration:
Task: "Wire picker RadioGroup + SelectionSummary"
Task: "Implement selectAutoTranslate eligibility + ensure track"
Task: "Minimal translate loop + confirm secondary list rendering"
```

---

## Parallel Example: User Story 2

```bash
Task: "Write auto_translate_scheduler_test.dart with fake TranslationCapability"
# Then:
Task: "Implement priority queue + concurrency ≤2 + retries in controller/scheduler"
Task: "Wire playback anchor index updates"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Picker select + progressive secondary lines with a fake or real translator
5. Demo MVP before scheduler polish

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. US1 → selectable Auto translate + progressive fill (MVP)
3. US2 → lazy priority + retries
4. US3 → friendly status UX
5. US4 → Re-translate
6. US5 → persist/resume + staleness
7. Polish → ADR, feature doc, analyze/test, quickstart

### Parallel Team Strategy

1. Team completes Setup + Foundational together
2. After Foundational:
   - Dev A: US1 picker + select path
   - Dev B: US2 scheduler (against controller interfaces) once T009/T016 shape exists
   - Dev C: US3 status UI against faked `AutoTranslateUiState`
3. US4/US5 follow as capacity allows

---

## Notes

- [P] = different files, no incomplete-task dependencies
- [USn] maps to spec user stories for traceability
- No Drift migration in v1 — do not add schema tasks unless research is superseded
- Prefer fakes for `TranslationCapability` in unit tests; do not hit the real worker in CI
- Suggested MVP scope: **Phase 1–3 (US1) only**
- Format validation: all tasks use `- [x]`, `Tnnn`, optional `[P]`, story labels on US phases only, and file paths
