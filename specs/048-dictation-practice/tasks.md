# Tasks: Dictation Practice (听写 — 语音复述与文字输入)

**Input**: Design documents from `/specs/048-dictation-practice/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/dictation-ui-and-data-contract.md](contracts/dictation-ui-and-data-contract.md), [quickstart.md](quickstart.md)

**Tests**: Unit and widget tests are included per the Enjoy Player Constitution (`flutter analyze` and `flutter test` gates) and the verification plan in [plan.md](plan.md).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., `US1`, `US2`, `US3`, `US4`)
- Exact file paths are included in every task description.

---

## Phase 1: Setup (Shared Infrastructure & Localization)

**Purpose**: Add localization strings and initialize the `lib/features/dictation/` module structure required by all user stories.

- [X] T001 Add English dictation strings (`playerDictationVoiceMode`, `playerDictationTextMode`, `playerDictationVoiceHint`, `playerDictationTextPlaceholder`, `playerDictationWordCountProgress`, `playerDictationCheckAnswer`, `playerDictationCheckingVoice`, `playerDictationTryAgain`, `playerDictationNextLine`, `playerDictationRetryTranscription`, `playerDictationLegendCorrect`, `playerDictationLegendMissed`, `playerDictationLegendExtra`, `playerDictationStatsCorrect`, `playerDictationStatsMissed`, `playerDictationStatsExtra`, `playerDictationPreviousAttempts`, `playerDictationAttemptAccuracy`) in `lib/l10n/app_en.arb`
- [X] T002 Add Chinese dictation strings matching all new keys in `lib/l10n/app_zh.arb` and regenerate localization files via `flutter gen-l10n`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain models, word-level diff & band algorithms, `DictationDao` echo-region queries, and `PlayerLens` loop-coupled transitions (`dictation ⇒ loop`) that must be in place before user story UI and controllers.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 [P] Add `watchByEchoRegion` and `listByEchoRegion` queries (`targetType`, `targetId`, `referenceStartMs`, `referenceDurationMs` ordered by `createdAt DESC`) in `lib/data/db/daos/dictation_dao.dart`
- [X] T004 [P] Add unit tests for `DictationDao.watchByEchoRegion` and `DictationDao.listByEchoRegion` in `test/data/db/daos/dictation_dao_test.dart`
- [X] T005 [P] Create `DictationInputMode`, `DictationAttemptStatus`, `DictationWordDiffOp`, `DictationDiffResult`, `DictationBandWord`, and `DictationSessionState` models in `lib/features/dictation/domain/dictation_models.dart`
- [X] T006 [P] Implement `dictationWordOf`, `tokenizeDictationWords`, and DP-based `computeDictationDiff(String referenceText, String userInput)` (`accuracy = round((correctWords / (totalWords + insertions)) * 100)`) in `lib/features/dictation/domain/dictation_diff.dart`
- [X] T007 [P] Implement `buildDictationBandWords` (word block pixel width `round(max(3, letters.length) * 9.5).toDouble()`, active word index from `currentPlaybackMs` and `TranscriptSentence.timeline` or proportional character timing fallback) in `lib/features/dictation/domain/dictation_band_words.dart`
- [X] T008 [P] Add unit tests for `dictationWordOf`, punctuation/apostrophe normalization, and `computeDictationDiff` accuracy/diff operations in `test/features/dictation/domain/dictation_diff_test.dart`
- [X] T009 [P] Add unit tests for `buildDictationBandWords` width calculation, timeline karaoke highlight, and proportional fallback in `test/features/dictation/domain/dictation_band_words_test.dart`
- [X] T010 Update `PlayerLens` (`loopMode = this == echo || this == dictate`, `dictationMode = this == dictate`, `blurMode = this == dictate`) and `resolvePlayerLens` (`practiceModeOf(echoMode, dictationMode)`) in `lib/features/player/domain/player_lens.dart`
- [X] T011 Update `PlayerInteractions.selectLens`, `toggleEchoMode`, and `toggleBlurMode` so entering `PlayerLens.dictate` starts a single-line loop on the active sentence (or sentence `0`) if no loop is active, switching `echo ⇄ dictate` preserves the active `EchoRegion`, and selecting `listen` clears both in `lib/features/player/application/player_interactions.dart`
- [X] T012 Update initial session hydration so restoring `transcriptBlurModeProvider == true` ensures an active `EchoRegion` exists for the initial sentence in `lib/features/player/application/player_open_coordinator.dart`
- [X] T013 [P] Update and add unit tests for `PlayerLens` and `PlayerInteractions` loop-coupled transitions (`Listen ⇄ Dictate`, `Echo ⇄ Dictate`, `Dictate → Listen`) in `test/features/player/domain/player_lens_test.dart` and `test/features/player/player_interactions_class_test.dart`

**Checkpoint**: Foundation ready — `DictationDao`, diff/band domain logic, and `dictation ⇒ loop` lens transitions are verified and green.

---

## Phase 3: User Story 1 - Voice Retelling Dictation with Automatic Speech Recognition and Diff (Priority: P1) 🎯 MVP

**Goal**: Enable learners in Dictate mode to see masked word blocks (`DictationBand`) with karaoke highlight during playback, retell the sentence by voice (default mode), automatically transcribe the recording via `AsrService`, persist the attempt to `dictations`, and inspect the inline word-level diff and accuracy score card (with retry support on ASR failure).

**Independent Test**: Switch to Dictate (`D` or lens pill), verify the active line enters a loop with masked word blocks that highlight during audio playback, record a voice retelling, and verify ASR transcription produces an inline Correct / Missed / Extra diff and accuracy score card.

### Tests for User Story 1

- [X] T014 [P] [US1] Add unit tests for `DictationController` (voice take → `AsrService.transcribe` → `computeDictationDiff` → `DictationDao.upsert`, empty speech warning, and `retryVoiceTranscription` on ASR/credit errors) in `test/features/dictation/application/dictation_controller_test.dart`
- [X] T015 [P] [US1] Add widget tests for `DictationBand` (unchecked masked word blocks, active playback highlight, checked inline diff with `[missed]` and struck-through `extra` tokens, and 3-item legend) in `test/features/dictation/presentation/dictation_band_test.dart`
- [X] T016 [P] [US1] Add widget tests for `DictationPanel` in Voice Retelling mode (Record CTA, transcribing spinner, ASR error retry banner, checked accuracy percentage, Correct/Missed/Extra counts, `Try again`, and `Next line`) in `test/features/dictation/presentation/dictation_panel_test.dart`

### Implementation for User Story 1

- [X] T017 [US1] Create `DictationScope` value object (`targetType`, `targetId`, `referenceStartMs`, `referenceDurationMs`, `referenceText`, `language`) and Riverpod providers (`dictationEchoRegionHistoryProvider`, `dictationControllerProvider`) in `lib/features/dictation/application/dictation_providers.dart`
- [X] T018 [US1] Implement `DictationController` (`setInputMode`, `checkTextAnswer`, `onVoiceTakeRecorded`, `retryVoiceTranscription`, `tryAgain`, and `selectHistoricalAttempt`) integrating `AsrService`, `computeDictationDiff`, `DictationDao`, and `SyncOutboxDao` in `lib/features/dictation/application/dictation_controller.dart`
- [X] T019 [P] [US1] Implement `DictationBand` widget rendering unchecked word-length blocks (`youSoft` idle, `originalSoft`/`original` border when active) and checked inline diff tokens (`originalInk` correct, `[word]` on `dangerSoft`/`danger` missed, line-through on `youSoft`/`youInk` extra) with bottom legend in `lib/features/dictation/presentation/dictation_band.dart`
- [X] T020 [US1] Implement `DictationPanel` widget for Voice Retelling mode (mode toggle header, Record / Stop / Transcribing states, ASR failure retry action, and Checked summary card with accuracy, Correct/Missed/Extra metrics, `Try again`, and `Next line`) in `lib/features/dictation/presentation/dictation_panel.dart`
- [X] T021 [US1] Update `EchoRegionMergedCard` to branch between Echo header (`ORIGINAL — LOOPING` + sentence text) and Dictate header (`DICTATION — LISTEN & TYPE` / `DICTATION — CHECKED` + `DictationBand` + `DictationPanel`) based on `transcriptBlurModeProvider` in `lib/features/transcript/presentation/transcript_echo_region_merged_card.dart`
- [X] T022 [US1] Run `dart run build_runner build --delete-conflicting-outputs` to generate Riverpod codegen for `lib/features/dictation/application/`

**Checkpoint**: User Story 1 is functional and independently testable as the MVP voice-retelling dictation loop.

---

## Phase 4: User Story 2 - Unified Recordings Across Dictate and Echo Modes (Priority: P1)

**Goal**: Ensure every voice retelling recorded in Dictate mode is captured via `ShadowTakeStore` into `recordings`, appears immediately in the loop's takes list (`ShadowTakesInLoopRow`), supports replay (`G`) and pronunciation assessment (`Score` / `V`), and remains visible when switching between `Dictate` and `Echo` modes.

**Independent Test**: Record a voice retelling in Dictate mode, verify the take chip appears immediately with Play and Score actions, trigger pronunciation assessment, then switch to Echo mode (`E`) and confirm the exact same take and score are present.

### Tests for User Story 2

- [X] T023 [P] [US2] Add widget tests verifying `EchoRegionMergedCard` in Dictate mode mounts the shared recording pipeline, forwards newly persisted `RecordingRow` takes to `DictationController.onVoiceTakeRecorded`, displays `ShadowTakesInLoopRow` for replay/scoring, and preserves takes when toggling `Dictate ⇄ Echo` in `test/features/transcript/transcript_echo_region_merged_card_test.dart`

### Implementation for User Story 2

- [X] T024 [US2] Add optional `ValueChanged<RecordingRow>? onTakePersisted` callback to `ShadowReadingPanel` and invoke it immediately after `ShadowTakeStore.persistRecordedTake` succeeds in `lib/features/shadow_reading/presentation/shadow_reading_panel.dart` and `lib/features/shadow_reading/presentation/shadow_reading_panel_recording.dart`
- [X] T025 [US2] Wire `ShadowReadingPanel` inside `EchoRegionMergedCard` during Dictate mode so dock/hotkey (`R`) and `DictationPanel` record actions share the single `MicRecorder` + `ShadowTakeStore` pipeline, render `ShadowTakesInLoopRow` (`Play` / `G`, `Score` / `V`), and trigger `DictationController.onVoiceTakeRecorded` in `lib/features/transcript/presentation/transcript_echo_region_merged_card.dart`

**Checkpoint**: User Stories 1 and 2 work together — voice retelling recordings are first-class shadow-reading takes across both Dictate and Echo modes.

---

## Phase 5: User Story 3 - Multi-Line Loop Control in Dictate Mode (Priority: P2)

**Goal**: Allow learners in Dictate mode to expand or shrink the dictation loop across multiple lines (`+ line` / `−` edge rows and `[` `]` `{` `}` hotkeys) and click any masked context line to move the single-line dictation loop to that line while keeping non-checked text masked.

**Independent Test**: In Dictate mode, click `+ line` below the loop (or press `]`) to include the next sentence, verify `DictationBand` concatenates word blocks for both lines while `+ line` preview text stays masked, and click a context line outside the loop to jump the dictation loop to that line.

### Tests for User Story 3

- [X] T026 [P] [US3] Add widget tests verifying `EchoLoopEdgeRow` masks adjacent sentence preview text with `TranscriptBlurText` when `transcriptBlurModeProvider` is true and resets dictation state on loop expansion/shrink in `test/features/transcript/transcript_echo_region_merged_card_test.dart`

### Implementation for User Story 3

- [X] T027 [P] [US3] Update `EchoLoopEdgeRow` to mask the adjacent sentence preview with `TranscriptBlurText` when `transcriptBlurModeProvider` is active in `lib/features/transcript/presentation/transcript_echo_loop_edge_row.dart`
- [X] T028 [US3] Update `TranscriptPanel` and `PlayerInteractions` so clicking a masked context line outside the active loop while in Dictate mode moves the single-line loop (`selectSingleEchoSentence`) to the clicked sentence in `lib/features/transcript/presentation/transcript_panel.dart` and `lib/features/player/application/player_interactions.dart`

**Checkpoint**: Multi-line loop controls and context-line loop jumping work seamlessly in Dictate mode without leaking unmasked transcript text.

---

## Phase 6: User Story 4 - Switchable Text Input Dictation Mode and Attempt History (Priority: P2)

**Goal**: Allow learners to toggle from Voice Retelling mode to Text Input mode (`TextField` with live word count, `Enter` to check, `Shift+Enter` for newline), browse previous dictation attempts (`DictationList`) for the current loop region, and see practised-line checkmarks for lines with dictation or recording history.

**Independent Test**: Toggle to Text Input mode in `DictationPanel`, type a sentence and press `Enter` to check the diff, then open `Previous Dictations` (`DictationList`) to switch between prior voice and text attempts and verify the transcript line shows a practised indicator.

### Tests for User Story 4

- [X] T029 [P] [US4] Add widget tests for Text Input mode (`Enter` submits, `Shift+Enter` inserts newline, live word counter `typed of about total words`) in `test/features/dictation/presentation/dictation_panel_test.dart`
- [X] T030 [P] [US4] Add widget tests for `DictationList` (Previous Dictations dropdown selector, accuracy badge, Correct/Missed/Extra stats, and `userInput` preview) in `test/features/dictation/presentation/dictation_list_test.dart`
- [X] T031 [P] [US4] Add unit tests verifying transcript practised-line counts include both `recordings` and `dictations` in `test/features/transcript/domain/transcript_recording_counts_test.dart`

### Implementation for User Story 4

- [X] T032 [US4] Add Text Input mode subview (`TextField`, `Shift+Enter` / `Enter` key handler, live word counter, and `Check answer` button) to `DictationPanel` in `lib/features/dictation/presentation/dictation_panel.dart`
- [X] T033 [P] [US4] Implement `DictationList` widget displaying `Previous Dictations (N)` selector, attempt timestamp, `accuracy%` badge, Correct/Missed/Extra counts, and `userInput` box in `lib/features/dictation/presentation/dictation_list.dart`
- [X] T034 [US4] Integrate `DictationList` below `DictationPanel` inside `EchoRegionMergedCard` when historical attempts exist for the active loop region in `lib/features/transcript/presentation/transcript_echo_region_merged_card.dart`
- [X] T035 [US4] Update `transcriptLineRecordingCountsProvider` (and helper logic in `lib/features/transcript/domain/transcript_recording_counts.dart`) to combine `DictationDao.watchByTarget` with `RecordingDao.watchByTarget` so lines practised via text or voice dictation show the practised indicator in `lib/features/transcript/application/transcript_line_recording_counts_provider.dart`

**Checkpoint**: All 4 user stories (Voice Retelling + ASR Diff, Unified Takes across Dictate/Echo, Multi-Line Loop Control, Text Input Mode + History) are complete and independently tested.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation updates, zero-comment policy check, and full CI gate validation.

- [X] T036 [P] Update feature documentation for loop-bound Dictate mode (`dictation ⇒ loop`), `DictationBand`, Voice Retelling + ASR flow, Text Input mode, and shared takes in `docs/features/echo-mode.md` and `docs/features/shadow-reading.md`
- [X] T037 Run `bash .github/scripts/validate_ci_gates.sh --fix`, `flutter analyze`, and `flutter test` to verify zero errors, formatting, and codegen alignment across the repository

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — can start immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 — **BLOCKS all user stories**.
- **Phase 3 (US1 - Voice Retelling + ASR + Diff, P1 🎯 MVP)**: Depends on Phase 2.
- **Phase 4 (US2 - Unified Recordings Across Dictate & Echo, P1)**: Depends on Phase 3 (`DictationController.onVoiceTakeRecorded` and `EchoRegionMergedCard` Dictate branch).
- **Phase 5 (US3 - Multi-Line Loop Control in Dictate Mode, P2)**: Depends on Phase 2 and Phase 3 (`EchoRegionMergedCard` Dictate mode integration). Can proceed in parallel with Phase 4 or Phase 6.
- **Phase 6 (US4 - Text Input Mode & Attempt History, P2)**: Depends on Phase 3 (`DictationController` and `DictationPanel`). Can proceed in parallel with Phase 5.
- **Phase 7 (Polish)**: Depends on all user stories being complete.

### User Story Dependencies

- **User Story 1 (P1)**: Core MVP; depends only on Foundational (Phase 2).
- **User Story 2 (P1)**: Connects `ShadowReadingPanel` take persistence to `DictationController` and exposes `ShadowTakesInLoopRow` in Dictate mode; depends on US1.
- **User Story 3 (P2)**: Extends loop edge masking and context-line click behavior in Dictate mode; depends on Phase 2 and US1.
- **User Story 4 (P2)**: Adds Text Input subview, `DictationList` attempt history, and practised-line counts for dictations; depends on US1.

### Parallel Opportunities

- **Phase 2**: `T003`/`T004` (`DictationDao`), `T005`/`T006`/`T008` (`dictation_diff.dart`), and `T007`/`T009` (`dictation_band_words.dart`) touch independent files and can be developed in parallel before `T010`–`T013` (`PlayerLens` & `PlayerInteractions`).
- **Phase 3 (US1)**: Tests `T014`, `T015`, `T016` and widget `T019` (`DictationBand`) can be written in parallel while `T017`/`T018` (`DictationController`) are built.
- **Phase 5 (US3) & Phase 6 (US4)**: Once US1/US2 are wired in `EchoRegionMergedCard`, `T027` (`EchoLoopEdgeRow`), `T033` (`DictationList`), and `T035` (`transcript_line_recording_counts_provider.dart`) can be developed in parallel.

---

## Parallel Example: Foundational Phase (Phase 2)

```bash
# Launch independent domain and DAO tasks together:
Task: "T003 [P] Add watchByEchoRegion and listByEchoRegion queries in lib/data/db/daos/dictation_dao.dart"
Task: "T006 [P] Implement dictationWordOf, tokenizeDictationWords, and DP-based computeDictationDiff in lib/features/dictation/domain/dictation_diff.dart"
Task: "T007 [P] Implement buildDictationBandWords in lib/features/dictation/domain/dictation_band_words.dart"
```

## Parallel Example: User Story 1 (Phase 3)

```bash
# Launch US1 unit/widget test suites and DictationBand component in parallel:
Task: "T014 [P] [US1] Add unit tests for DictationController in test/features/dictation/application/dictation_controller_test.dart"
Task: "T015 [P] [US1] Add widget tests for DictationBand in test/features/dictation/presentation/dictation_band_test.dart"
Task: "T019 [P] [US1] Implement DictationBand widget in lib/features/dictation/presentation/dictation_band.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 — Core P1 Voice Retelling + Shared Takes)

1. Complete **Phase 1: Setup** (`T001`–`T002`).
2. Complete **Phase 2: Foundational** (`T003`–`T013`) and verify `flutter test` passes on all DAO, diff, band, and lens transition tests.
3. Complete **Phase 3: User Story 1** (`T014`–`T022`) and **Phase 4: User Story 2** (`T023`–`T025`).
4. **STOP and VALIDATE**: Test Voice Retelling dictation, ASR transcription, inline word diff, and shared recordings across Dictate and Echo modes.

### Incremental Delivery

1. **Foundation (`T001`–`T013`)**: DAO queries + word diff/band algorithms + `dictation ⇒ loop` lens transitions.
2. **MVP (`T014`–`T025`, US1 + US2)**: Voice Retelling mode, `DictationBand` karaoke blocks & diff, ASR auto-check, and unified shadow-reading recordings (`Play` / `Score` / Echo mode visibility).
3. **Multi-Line Loop Controls (`T026`–`T028`, US3)**: Masked `+ line` / `−` edge controls and click-to-move-loop on context lines.
4. **Text Input & History (`T029`–`T035`, US4)**: Text Input toggle (`Enter` to check), `DictationList` attempt selector, and practised line indicators.
5. **Polish & Gates (`T036`–`T037`)**: Docs update and `validate_ci_gates.sh --fix`.
