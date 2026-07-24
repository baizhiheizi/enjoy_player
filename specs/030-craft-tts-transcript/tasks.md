# Tasks: Craft TTS Transcript Quality

**Input**: Design documents from `/specs/030-craft-tts-transcript/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included — constitution / plan require automated coverage; SC-006 calls for segmenter + blank-when-not-solid tests.

**Organization**: Tasks grouped by user story (US1–US4). US1 = solid cue quality (MVP); US2 = blank when not solid; US3 = STT replace path; US4 = discoverability.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Maps to spec user stories (US1–US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Confirm branch and design artifacts.

- [X] T001 Confirm branch `030-craft-tts-transcript` and design docs under `specs/030-craft-tts-transcript/` (`spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`)
- [X] T002 [P] Skim callers of `estimateTimeline` / `encodeTimelineJson` / `segmentWordBoundaries` (expect Craft save + tests only) and note in PR notes if anything else appears

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared solid-gate helper used by Craft save (US1 + US2) without changing save behavior yet.

**CRITICAL**: No user-story save/repo wiring until this helper exists and is tested.

- [X] T003 Add `buildCraftPrimaryTimelineJson(List<CraftWordBoundary> boundaries)` (or equivalent) in `lib/features/craft/domain/word_boundary_segmenter.dart` that: merges/segments via existing APIs, returns `String?` JSON when solid (≥1 non-empty segment), else `null`
- [X] T004 [P] Add unit tests for solid gate (`null` on empty boundaries / empty segments) in `test/features/craft/domain/word_boundary_segmenter_test.dart`

**Checkpoint**: Helper ready — US1 improves segmenter; US2 wires blank save.

---

## Phase 3: User Story 1 — Craft cues break cleanly on sentences (Priority: P1) 🎯 MVP

**Goal**: When solid word timings exist, saved transcript lines never start with punctuation-only text and prefer sentence boundaries over blind 6-word chops.

**Independent Test**: `flutter test test/features/craft/domain/word_boundary_segmenter_test.dart` — standalone `.` tokens do not start a line; multi-sentence samples break on sentence ends. Manual: Android/Windows Craft multi-sentence paragraph → clean lines.

### Tests for User Story 1

- [X] T005 [P] [US1] Extend `test/features/craft/domain/word_boundary_segmenter_test.dart` with cases: Azure-style standalone `.` / `?` / `。` tokens; sentence preference over `preferredWordsPerSegment`; CJK full-width punct; no empty/punct-only segment text

### Implementation for User Story 1

- [X] T006 [US1] Implement punctuation-token merge (attach to previous word; extend end timing to punct token end) in `lib/features/craft/domain/word_boundary_segmenter.dart` per `specs/030-craft-tts-transcript/contracts/craft-transcript-builder.md`
- [X] T007 [US1] Prefer sentence-end flush over fixed word-count chops inside `segmentWordBoundaries` in `lib/features/craft/domain/word_boundary_segmenter.dart`
- [X] T008 [US1] Wire `CraftController` save path in `lib/features/craft/application/craft_controller.dart` to use `buildCraftPrimaryTimelineJson` when boundaries non-empty (still keep temporary estimator fallback until US2 removes it, OR pass through solid JSON only—prefer calling helper for solid path now)

**Checkpoint**: MVP — solid timings produce clean cues (estimator may still exist for empty timings until US2).

---

## Phase 4: User Story 2 — No solid timings → blank transcript (Priority: P1)

**Goal**: Without solid timings, Craft saves playable audio with **no** primary transcript (no duration estimates). Player empty state can Generate via STT.

**Independent Test**: Unit/repo tests: `primaryTimelineJson: null` → no transcript row; controller with empty `previewWordBoundaries` does not call `encodeTimelineJson`. Manual: iOS/macOS or OpenAI BYOK Craft → empty transcript + Generate works.

### Tests for User Story 2

- [X] T009 [P] [US2] Extend `test/features/library/library_repository_craft_test.dart` for `importCraftedFromText` with `primaryTimelineJson: null` → audio exists, no transcript rows for target
- [X] T010 [P] [US2] Extend `test/features/library/library_repository_craft_test.dart` for `updateCraftedFromText` blank → deletes prior transcript rows for media
- [X] T011 [P] [US2] Extend `test/features/craft/application/craft_controller_test.dart` (or add focused save tests) asserting empty word boundaries → save succeeds with null timeline / no estimator

### Implementation for User Story 2

- [X] T012 [US2] Change `importCraftedFromText` in `lib/features/library/data/library_repository.dart` so `primaryTimelineJson == null` means **omit** transcript insert (remove `{text, start:0, duration:0}` fallback) per `contracts/craft-save-blank-transcript.md`
- [X] T013 [US2] Change `updateCraftedFromText` in `lib/features/library/data/library_repository.dart` so blank timeline deletes transcript rows for the media target while updating audio
- [X] T014 [US2] Remove `encodeTimelineJson` / `estimateTimeline` / WAV-duration fallback from save in `lib/features/craft/application/craft_controller.dart`; pass `null` when `buildCraftPrimaryTimelineJson` returns null
- [X] T015 [US2] Delete or stop shipping unused Craft estimator if only Craft save used it: remove dead code from `lib/features/craft/domain/transcript_timestamp_estimator.dart` and `test/features/craft/domain/transcript_timestamp_estimator_test.dart` **or** keep file with a short deprecation comment if retention preferred—prefer delete when unused

**Checkpoint**: US1 + US2 — solid clean cues; blank otherwise. Estimator gone from Craft save.

---

## Phase 5: User Story 3 — Replace imperfect cues with STT (Priority: P2)

**Goal**: Craft items (solid or blank) can run existing local ASR generate/replace; failures preserve prior state.

**Independent Test**: Manual quickstart C; confirm `TranscriptPanel` / picker still expose Generate for `provider == craft` local audio. Fix only if Craft media incorrectly disables generate.

### Tests for User Story 3

- [X] T016 [P] [US3] Add or extend a focused test (widget or provider) proving local Craft media keeps `showGenerateButton` / generate path available—e.g. in `test/features/transcript/` or document manual-only with a small unit guard if no existing harness fits

### Implementation for User Story 3

- [X] T017 [US3] Audit `lib/features/transcript/presentation/transcript_panel.dart` and subtitle picker: Craft local audio must use same `launchAsrGeneration` path as other local audio (`lib/features/asr/presentation/asr_generation_launcher.dart`); fix any `provider == craft` exclusion if found
- [X] T018 [US3] Confirm ASR failure leaves prior solid transcript / blank unchanged (no Craft-specific wipe)—spot-check `upsertAsrGeneratedTrack` behavior; add regression note or tiny test only if a bug is found

**Checkpoint**: STT escape hatch works for Craft without re-TTS.

---

## Phase 6: User Story 4 — Discover STT generate / replace (Priority: P2)

**Goal**: Blank items rely on empty-state Generate; solid saves may show a once-per-session localized hint pointing to regenerate via STT (no auto-ASR).

**Independent Test**: Blank Craft → empty state Generate visible; solid save → hint at most once per session; dismissible / non-spammy.

### Tests for User Story 4

- [X] T019 [P] [US4] Widget or unit test for hint session gate (e.g. flag resets per app session) in `test/features/craft/` covering “show once then suppress”

### Implementation for User Story 4

- [X] T020 [P] [US4] Add ARB keys for solid-cue STT hint in `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`, `lib/l10n/app_zh_CN.arb`; run `flutter gen-l10n`
- [X] T021 [US4] Show once-per-session snackbar/banner after successful Craft save that wrote a solid transcript (Express Practice now / Advanced save) in `lib/features/craft/presentation/` (audio stage or save completion path)—copy per `contracts/stt-discoverability.md`; never auto-start ASR
- [X] T022 [US4] Verify blank-transcript items need no extra Craft CTA beyond existing `TranscriptEmptyState` generate in `lib/features/transcript/presentation/transcript_empty_state.dart`

**Checkpoint**: Discoverability complete for blank + solid paths.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Docs, ADR, quality gates.

- [X] T023 [P] Add `docs/decisions/0063-craft-blank-transcript-without-solid-timings.md` and index row in `docs/decisions/README.md`
- [X] T024 [P] Update `docs/features/craft.md` word-segmented / save transcript section: solid segmenter rules, blank when not solid, STT generate in player; remove estimator-as-fallback claims; align `source: 'ai'` with code
- [X] T025 Run `flutter analyze` and `flutter test` for craft/library/transcript touched tests
- [X] T026 Run `bash .github/scripts/validate_ci_gates.sh --fix` and fix format/codegen drift
- [X] T027 Walk `specs/030-craft-tts-transcript/quickstart.md` Manual A–D (or note platform limits in PR)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Start immediately
- **Foundational (Phase 2)**: After Setup — **blocks** US1–US4
- **US1 (Phase 3)**: After Foundational — MVP segmenter quality
- **US2 (Phase 4)**: After US1 preferred (same `craft_controller.dart` / save path); can start repo blank tests [P] earlier but controller must drop estimator after US1 helper wiring
- **US3 (Phase 5)**: After US2 (blank items must exist to validate empty→Generate)
- **US4 (Phase 6)**: After US2 (needs solid vs blank save outcomes); can parallelize ARB with US3
- **Polish (Phase 7)**: After desired stories complete

### User Story Dependencies

| Story | Depends on | Notes |
|-------|------------|-------|
| US1 | Phase 2 | Segmenter + solid helper |
| US2 | US1 (same save file) | Blank policy + repo null semantics |
| US3 | US2 | Validate STT on blank/solid Craft |
| US4 | US2 | Hint only on solid; empty state for blank |

### Parallel Opportunities

- T002 ‖ T001 (setup)
- T004 ‖ after T003
- T005 ‖ can be written alongside T006–T007
- T009 ‖ T010 ‖ T011 (US2 tests) before/during T012–T014
- T016 ‖ T017 (US3)
- T019 ‖ T020 (US4)
- T023 ‖ T024 (docs)

### Parallel Example: User Story 2

```bash
# After US1 lands, in parallel:
Task: "Extend library_repository_craft_test import null timeline"
Task: "Extend library_repository_craft_test update blank deletes transcripts"
Task: "Extend craft_controller_test empty boundaries → null timeline"

# Then sequential wiring:
Task: "importCraftedFromText null = omit transcript"
Task: "updateCraftedFromText blank deletes transcripts"
Task: "Remove estimator from craft_controller save"
```

---

## Implementation Strategy

### MVP First (US1 only)

1. Phase 1–2  
2. Phase 3 US1 (clean solid cues; estimator may remain briefly)  
3. **STOP** — validate segmenter tests + Android/Windows Craft sample  

### Incremental Delivery

1. US1 → clean solid cues  
2. US2 → blank when not solid (ships the product rule)  
3. US3 → confirm STT escape hatch  
4. US4 → hint polish  
5. Phase 7 docs/ADR/gates  

### Suggested MVP scope

**US1 + US2** together are the real product MVP (clean cues **and** blank-not-estimate). US1 alone still leaves Apple/OpenAI on bad estimates until US2.

---

## Notes

- Do not add forced alignment, Deepgram TTS, or auto-STT on save  
- `null` `primaryTimelineJson` semantics change is a breaking contract for repository callers—grep all call sites when implementing T012  
- Retro-fixing old estimated Craft transcripts on dedupe is out of scope  
- Format: every task has checkbox, ID, optional [P]/[USx], and file path  
