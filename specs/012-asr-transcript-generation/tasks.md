# Tasks: ASR Transcript Generation

**Input**: Design documents from `/specs/012-asr-transcript-generation/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are required for every changed behavior (Constitution Principle II; QR-002). Tests are written FIRST and confirmed failing before the implementation in the same phase.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US6)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `lib/features/asr/{application,data,domain}/`
- **Touched shared code**: `lib/features/transcript/{application,data,presentation}/`
- **Existing reused code**: `lib/features/ai/`, `lib/data/`, `lib/core/`
- **Tests**: `test/features/asr/`, `test/features/transcript/`
- **Feature docs**: `docs/features/asr.md`, `docs/features/transcript.md`
- **ADR**: `docs/decisions/NNNN-asr-transcript-generation.md`
- **Localization**: `lib/l10n/app_en.arb`, `lib/l10n/app_zh_CN.arb`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Lay down the new feature folder skeleton and capture the decision in an ADR per Constitution Principle V.

- [X] T001 Create `lib/features/asr/{application,data,domain}/` empty folders with `.gitkeep` files
- [X] T002 [P] Create `test/features/asr/{application,data,domain}/` empty folders with `.gitkeep` files
- [X] T003 [P] Add ADR `docs/decisions/NNNN-asr-transcript-generation.md` recording the **reuse** of existing `AsrCapability` / `TranscriptRepository` / `FfmpegMediaProbe` / `azure_assessment_wav_normalizer` instead of new vendor-specific code, per Constitution Principle V
- [X] T004 [P] Add fixture paths to `test_assets/fixtures/asr/` README (`en_5min.m4a`, `en_5min.mp4`) and stub them for unit tests (no real audio needed for most tests)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Foundation that MUST be complete before any user story can be implemented. Tests for the foundation are written first and confirmed failing.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T005 [P] Add `lib/features/asr/domain/asr_audio_extraction_failure.dart` with `AsrAudioExtractionException`, `AsrAudioExtractionFailureReason { ffmpegUnavailable, noAudioTrack, ffmpegFailed, fileTooLarge, unsupportedSource }`, and a `toString()` per `data-model.md` § 2.4
- [X] T006 [P] Add `lib/features/asr/application/asr_generation_job.dart` with `AsrGenerationJob` value type and `AsrGenerationPhase { idle, extracting, recognizing, persisting, success, error, cancelled }` per `data-model.md` § 2.1
- [X] T007 [P] [US4] Write failing unit tests for `AsrTimelineBuilder` in `test/features/asr/domain/asr_timeline_builder_test.dart` covering: word-level grouping (with punctuation + pause boundaries + maxLineDuration cap), segment-level fallback, plain-text duration-distributed fallback, empty-input → `[]`, deterministic output for identical input (per `data-model.md` § 2.3 / `contracts/asr-capability.md`)
- [ ] T008 [P] [US5] Write failing unit tests for `AsrAudioExtractor` in `test/features/asr/data/asr_audio_extractor_test.dart` covering: audio-only skip path, video audio extract via mocked FFmpeg, missing-FFmpeg `ffmpegUnavailable` reason, no-audio-track `noAudioTrack` reason, oversized file `fileTooLarge` reason (per `data-model.md` § 2.4 / `contracts/asr-capability.md`)
- [X] T009 [P] [US4] Implement `AsrTimelineBuilder.buildAsrTranscriptLines` in `lib/features/asr/domain/asr_timeline_builder.dart` — pure function, word→segment→plain-text paths, deterministic output, `minLineDurationMs=800`, `maxLineDurationMs=6000`, `maxLineChars=140`, sentence terminators `. ? ! 。 ？ ！`, pause threshold `>350ms` (per `data-model.md` § 2.3). Tests T007 should pass.
- [X] T010 [P] [US5] Implement `AsrAudioExtractor` in `lib/features/asr/data/asr_audio_extractor.dart` — `extractAudio({mediaSourceUri, kind, onProgress, maxBytes})` using `ffmpeg_kit_flutter_new` on mobile/macOS and `Process.run` via `Isolate.run` on Windows, reusing `FfmpegMediaProbe.resolveFfmpegExecutable()` / `mediaInputForFfmpeg` / `parseDurationSeconds`, deleting temp files in `finally`. Tests T008 should pass.
- [ ] T011 [US1] Write failing unit tests for `AsrGenerationController` in `test/features/asr/application/asr_generation_controller_test.dart` covering: idle → extracting → recognizing → persisting → success state machine, in-flight guard (only one job per `mediaId`), cancel-on-restart (new request cancels prior `Future` cleanly, no overlapping writes), deterministic upsert (3 re-generations → exactly 1 `source: ai` row), error → idle (per `contracts/asr-capability.md` § "AsrGenerationController")
- [X] T012 [US1] Add `TranscriptRepository.upsertAsrGeneratedTrack` in `lib/features/transcript/data/transcript_repository.dart` per `contracts/asr-capability.md` § "TranscriptRepository.upsertAsrGeneratedTrack" — deterministic `enjoyTranscriptId(...source: 'ai')`, Drift `transcriptDao.upsert`, preserves `createdAt` + `label` across re-generation, calls `ensurePrimaryTranscript` when `activateAsPrimary == true`, returns `String?`
- [X] T013 [P] [US1] Write failing repository tests for `upsertAsrGeneratedTrack` in `test/features/transcript/transcript_repository_generate_asr_test.dart` covering: insert on empty target, upsert preserves `createdAt` and `label`, two upserts for the same `(mediaId, language)` produce exactly 1 row (SC-004), `activateAsPrimary=true` makes the new track the session primary
- [X] T014 [US1] Implement `AsrGenerationController` in `lib/features/asr/application/asr_generation_controller.dart` annotated `@riverpod`, exposing `AsyncValue<AsrGenerationJob?>` per `(mediaId)` family, methods `generateTranscript`, `cancel`, `clear`. Pipeline: validate `mediaId` and `language` → extract audio (video only) → `AsrService.transcribe` → `AsrTimelineBuilder.buildAsrTranscriptLines` → `TranscriptRepository.upsertAsrGeneratedTrack(activateAsPrimary: true)` → update media row language when `AsrResult.language` differs. Cancellation via per-`mediaId` `Completer<void>` (FR-015). All non-empty logging via `logNamed('asr...')`, never `print()` (QR-006). Tests T011 should pass.
- [X] T015 [P] [US1] Generate Riverpod code: run `dart run build_runner build --delete-conflicting-outputs` and commit `lib/features/asr/application/asr_generation_controller.g.dart`
- [X] T016 [P] Add new ARB localization keys to `lib/l10n/app_en.arb` and `lib/l10n/app_zh_CN.arb`: `transcriptEmptyGenerate`, `subtitlesGenerate`, `subtitlesRegenerate`, `asrStatusExtracting`, `asrStatusRecognizing`, `asrStatusSaving`, `asrStatusSuccess`, `asrLongMediaConfirmTitle`, `asrLongMediaConfirmBody`, `asrLongMediaConfirmContinue`, `asrLongMediaConfirmCancel`, `asrErrorFfmpegUnavailable`, `asrErrorFfmpegUnavailableHint`, `asrErrorNoAudioTrack`, `asrErrorExtractionFailed`, `asrErrorFileTooLarge`, `asrErrorUnsupportedSource`, `asrErrorByokMissing`, `asrErrorByokMissingHint`, `asrErrorCreditsExhausted`, `asrErrorCreditsExhaustedHint`, `asrErrorNetwork`, `asrErrorNoSpeech`. Then run `flutter gen-l10n`
- [X] T017 [P] Add `lib/features/asr/application/asr_failure_messages.dart` mapping `AsrAudioExtractionFailureReason` → ARB key + (optional) deep-link route, per `contracts/asr-capability.md` § 4

**Checkpoint**: Foundation ready — user story implementation can now begin in parallel

---

## Phase 3: User Story 1 — Generate a transcript when none exists (Priority: P1) 🎯 MVP

**Goal**: A learner with no transcript can trigger generation from the empty state; progress is shown; the resulting track is auto-selected as primary.

**Independent Test**: Open a media item with no transcript tracks; trigger **Generate transcript** from the empty state; confirm the resulting track is time-aligned, primary, and `source: ai`. (See `quickstart.md` Scenarios A + B.)

### Tests for User Story 1

- [X] T018 [P] [US1] Widget test: empty state shows the Generate CTA when local file is eligible, hides it otherwise, in `test/features/transcript/transcript_empty_state_generate_action_test.dart`
- [X] T019 [P] [US1] Widget test: Generate CTA enters busy state during `onGenerate` and restores after completion, in `test/features/transcript/transcript_empty_state_generate_action_test.dart`

### Implementation for User Story 1

- [X] T020 [P] [US1] Extend `TranscriptEmptyState` in `lib/features/transcript/presentation/transcript_empty_state.dart` with `onGenerate` and `showGenerateButton` per `contracts/asr-capability.md` § "Subtitles picker / empty-state integration"
- [X] T021 [P] [US1] Extend `SubtitleActionsSection` in `lib/features/transcript/presentation/subtitle_track_picker_actions.dart` with `onGenerate` and `showGenerate` per `contracts/asr-capability.md` § "Subtitles picker / empty-state integration"
- [X] T022 [US1] Wire the empty-state **Generate transcript** CTA in `lib/features/transcript/presentation/transcript_panel.dart` (and the call site that constructs `TranscriptEmptyState`) to invoke `AsrGenerationController.generateTranscript` via Riverpod, gated by `local-file-eligible` (FR-020) and `ffmpeg-present-or-audio-only` checks; on success reload via existing `transcriptLinesForMediaProvider` (per FR-001, FR-013, FR-021)
- [X] T023 [US1] Implement `AsrLongMediaConfirmDialog` in `lib/features/asr/application/asr_long_media_dialog.dart` showing `asrLongMediaConfirmTitle`/`Body` and returning `bool`. The controller calls it when `mediaDurationSeconds >= 1800` (FR-008 / QR-008)

**Checkpoint**: User Story 1 is fully functional and testable independently — empty state → Generate → time-aligned primary track on the local file

---

## Phase 4: User Story 2 — Re-generate a transcript at any time (Priority: P1)

**Goal**: The picker actions always offer Generate / Re-generate; re-generation upserts the existing `source: ai` track in place; the active primary session stays valid; concurrent starts cancel the prior run cleanly.

**Independent Test**: With any transcript present, open the subtitle picker and verify the Generate / Re-generate row is always visible; trigger re-generate and confirm exactly one `source: ai` row remains (SC-004 / Scenario C / Scenario J / Scenario K).

### Tests for User Story 2

- [X] T024 [P] [US2] Widget test: picker shows Generate / Re-generate action with `subtitlesGenerate` (or `subtitlesRegenerate` when an `ai` track exists) regardless of track count, in `test/features/transcript/subtitle_track_picker_generate_action_test.dart`
- [X] T025 [P] [US2] Widget test: re-generate keeps the previous track visible while busy; replaces in place on success; spinner state handled by `TranscriptBusyListTile`, in `test/features/transcript/subtitle_track_picker_generate_action_test.dart`
- [X] T026 [P] [US2] Widget test: starting a new generation while one is in-flight disables prior CTA (`enabled: !_busy`) and the controller cancels cleanly (no overlapping writes, single resulting row), in `test/features/transcript/subtitle_track_picker_generate_action_test.dart`

### Implementation for User Story 2

- [X] T027 [US2] Wire the picker's Generate / Re-generate action in `lib/features/transcript/presentation/subtitle_track_picker_sheet.dart` (or wherever `SubtitleActionsSection` is constructed) to invoke `AsrGenerationController.generateTranscript` and toggle label between `subtitlesGenerate` and `subtitlesRegenerate` based on `tracks.any((t) => t.source == 'ai')` (per FR-002 / FR-010)
- [X] T028 [US2] Ensure echo-session lookup returns the same row id after re-generation (deterministic id ensures this) by verifying `lib/features/transcript/data/transcript_repository.dart::ensurePrimaryTranscript` keeps `session.transcriptId` stable when the `ai` row id is unchanged — add a regression test in `test/features/transcript/transcript_repository_generate_asr_test.dart`

**Checkpoint**: User Stories 1 AND 2 are independently functional — empty-state generate and picker re-generate both work, deterministic id keeps session continuity

---

## Phase 5: User Story 3 — Azure ASR as default, with Enjoy API and BYOK paths (Priority: P1)

**Goal**: Azure Speech is the default. The Enjoy API path handles short + long audio; BYOK Azure Speech and BYOK OpenAI Whisper work; BYOK missing produces a friendly error pointing to AI Providers; credits-exhausted on the Enjoy path produces a friendly error pointing to Upgrade.

**Independent Test**: Configure Enjoy (signed in), then BYOK Azure, then BYOK OpenAI — generate each way and confirm equivalent tracks. (See `quickstart.md` Scenarios D + E.)

### Tests for User Story 3

- [ ] T029 [P] [US3] Unit test: BYOK missing throws `ByokNotConfiguredFailure(ModalityKind.asr)` which the controller maps to `asrErrorByokMissing` + deep-link to AI Providers, in `test/features/asr/application/asr_generation_controller_test.dart` (extend T011 suite)
- [ ] T030 [P] [US3] Unit test: BYOK Azure returns language-mapped locale via `mapTranscriptLanguageToAzure` and never rewrites media language on Azure BYOK (FR-012 path), in `test/features/asr/application/asr_generation_controller_test.dart`
- [ ] T031 [P] [US3] Unit test: BYOK OpenAI Whisper returns plain-text-only → `AsrTimelineBuilder` plain-text fallback path produces duration-distributed lines (FR-009), in `test/features/asr/application/asr_generation_controller_test.dart`
- [X] T032 [P] [US3] Unit test: empty ASR result (no segments, no text) → controller returns `AsrGenerationPhase.error` with `asrErrorNoSpeech` key and does NOT persist a row (FR / US4.3), in `test/features/asr/application/asr_generation_controller_test.dart`

### Implementation for User Story 3

- [ ] T033 [P] [US3] Map `ByokNotConfiguredFailure(ModalityKind.asr)` in `lib/features/asr/application/asr_failure_messages.dart` → `asrErrorByokMissing` + deep-link `AIProvidersScreen.routeName` (per `contracts/asr-capability.md` § 4 / FR-018)
- [ ] T034 [P] [US3] Map Enjoy `ApiException` with credits-exhausted marker (re-use the existing detection pattern from `lib/features/ai/application/ai_byok_error_mapping.dart`) → `asrErrorCreditsExhausted` + deep-link to Upgrade (per FR-019)
- [ ] T035 [P] [US3] Map network / `SocketException` / generic timeout → `asrErrorNetwork` with a Retry affordance, reusing the existing friendly-error + Retry pattern from `transcript_error_friendly_*` (per FR-017)
- [X] T036 [US3] Add provider-routing unit coverage in `test/features/ai/application/ai_capability_providers_test.dart` to confirm `asrCapabilityProvider` selects `EnjoyAsrCapability`, `ByokAsrOpenAiCapability`, or `ByokAsrAzureCapability` based on `SpeechByokKind` (regression guard — no provider-routing change in this feature)

**Checkpoint**: User Stories 1, 2, AND 3 are independently functional — Enjoy, BYOK Azure, BYOK OpenAI all work; failure modes are friendly and link to the right surface

---

## Phase 6: User Story 4 — Transcript format consistency and quality (Priority: P2)

**Goal**: Generated lines are reasonably segmented, time-aligned, and behave identically to imported `.srt` / `.vtt` for every downstream feature (highlight, tap-to-seek, dictionary, echo, blur, auto-translate).

**Independent Test**: Generate from a 5-minute file; verify lines are roughly sentence-length, timestamps align, and all downstream features work without regression. (See `quickstart.md` Scenarios A + B + J.)

### Tests for User Story 4

- [X] T037 [P] [US4] Unit test: `AsrTimelineBuilder` word-level path groups words by punctuation + pause boundaries; lines are not one word and not one block; boundaries include `. ? ! 。 ？ ！` and pauses > 350ms; cap at `maxLineDurationMs=6000` and `maxLineChars=140`, in `test/features/asr/domain/asr_timeline_builder_test.dart` (extend T007)
- [X] T038 [P] [US4] Unit test: `AsrTimelineBuilder` plain-text path distributes evenly across `mediaDurationMs` and respects sentence terminators when present, in `test/features/asr/domain/asr_timeline_builder_test.dart`
- [X] T039 [P] [US4] Unit test: `upsertAsrGeneratedTrack` writes `TranscriptLine` JSON (`text`, `startMs`, `durationMs`) — round-trips through `TranscriptLine.fromJson` with millisecond precision, in `test/features/transcript/transcript_repository_generate_asr_test.dart`

### Implementation for User Story 4

- [ ] T040 [P] [US4] Add `mediaDurationMs` resolution helper in `lib/features/asr/application/asr_generation_controller.dart`: probe with `FfmpegMediaProbe.parseDurationSeconds` for video sources; fall back to `media_kit` duration for audio-only sources; fall back to `0` (which makes the plain-text fallback produce a single-line track) — covered by existing test T011's success path
- [X] T041 [P] [US4] Mark `source: 'ai'` row label as `'Generated (<lang>)'` on first write and preserve on re-generation, in `lib/features/transcript/data/transcript_repository.dart::upsertAsrGeneratedTrack` (per FR-022)
- [ ] T042 [US4] Add a regression run in `test/features/transcript/` that imports an ASR-generated track (built via `AsrTimelineBuilder` + `upsertAsrGeneratedTrack`) and verifies every downstream feature still resolves: `transcriptLinesForMediaProvider`, `transcriptPlaybackHighlightProvider`, `echoRegionBounds`, `transcriptBlurModeProvider`, `autoTranslateController`. This is the SC-005 / FR-016 contract test.

**Checkpoint**: User Story 4 is fully covered — generated tracks are first-class transcripts, every downstream feature is regression-tested

---

## Phase 7: User Story 5 — Audio extraction from video before recognition (Priority: P2)

**Goal**: Video files have their audio track extracted before ASR; audio-only files skip extraction; errors are friendly; UI shows extraction progress.

**Independent Test**: Open a video with no subtitles; trigger Generate; confirm extraction runs (with progress) before recognition and the transcript aligns with the video's audio. (See `quickstart.md` Scenarios B + I.)

### Tests for User Story 5

- [X] T043 [P] [US5] Unit test: `AsrAudioExtractor.extractAudio` for `MediaKind.audio` returns the source file bytes without invoking FFmpeg (FR-003), in `test/features/asr/data/asr_audio_extractor_test.dart` (extend T008)
- [ ] T044 [P] [US5] Unit test: missing FFmpeg on Windows (no bundled binary, no PATH) returns `AsrAudioExtractionException(ffmpegUnavailable)` which the controller maps to `asrErrorFfmpegUnavailable` + Settings deep-link (FR-004 / Edge Cases), in `test/features/asr/application/asr_generation_controller_test.dart`
- [X] T045 [P] [US5] Unit test: oversized file returns `AsrAudioExtractionException(fileTooLarge)` mapped to `asrErrorFileTooLarge` (FR-017 / Edge Cases), in `test/features/asr/data/asr_audio_extractor_test.dart`
- [ ] T046 [P] [US5] Unit test: extraction progress callback fires monotonically (best-effort) and the controller reports `AsrGenerationPhase.extracting` until `AsrService.transcribe` is called (FR-013), in `test/features/asr/application/asr_generation_controller_test.dart`

### Implementation for User Story 5

- [X] T047 [US5] Wire `AsrAudioExtractor.extractAudio` into `AsrGenerationController.generateTranscript`: `MediaKind.audio` → read source bytes directly; `MediaKind.video` → call extractor with `onProgress` updating `AsrGenerationJob.progress`. The extractor must delete the temp WAV in `finally` (per `contracts/asr-capability.md` § "AsrAudioExtractor")
- [ ] T048 [P] [US5] Disable the empty-state Generate CTA on platforms where FFmpeg is unavailable AND the source is video-only (audio-only files still work); show tooltip via existing `TranscriptBusyButton` busy/disabled path with `asrErrorFfmpegUnavailable` copy (FR-005 / Edge Cases). Update `transcript_empty_state_generate_action_test.dart` (extend T018).

**Checkpoint**: User Story 5 is fully functional — extraction works on all four platforms with friendly failure modes

---

## Phase 8: User Story 6 — Language selection and auto-detection (Priority: P2)

**Goal**: Learner can pick the spoken language before generating (default = media's stored language); when ASR auto-detects a different language, the resulting track and the media row are updated.

**Independent Test**: Generate with explicit language; generate with auto-detect on a media item whose stored language is wrong; confirm the track + media row reflect the detected language. (See `quickstart.md` Scenario F.)

### Tests for User Story 6

- [ ] T049 [P] [US6] Unit test: language propagation in `AsrGenerationController` — when `AsrResult.language` is set and differs from media row language, `media_videos` (or `media_audios`) row is updated; same-language → no-op; null detected language → no-op (FR-011 / FR-012), in `test/features/asr/application/asr_generation_controller_test.dart` (extend T011)
- [X] T050 [P] [US6] Unit test: explicit `language` argument bypasses auto-detect and is written to the track (FR-011), in `test/features/asr/application/asr_generation_controller_test.dart`
- [ ] T051 [P] [US6] Unit test: `mapTranscriptLanguageToAzure` is consulted only on the BYOK Azure path; null result → friendly `asrErrorByokMissing`-style unsupported-language message (Edge Cases), in `test/features/ai/azure_language_mapper_test.dart` (regression guard)

### Implementation for User Story 6

- [X] T052 [P] [US6] Add language picker step to the Generate CTA flow: reuse `lib/features/transcript/presentation/import_subtitle_language_dialog.dart` (already wired to the language catalog) with an extra "Auto-detect" option, returning either a BCP47 tag or `null` for auto-detect
- [X] T053 [US6] Update `AsrGenerationController.generateTranscript` to: (a) accept an optional `language` override, (b) read the media row's stored language when not provided, (c) pass `language` into `AsrRequest` for non-auto-detect paths, (d) when `AsrResult.language` differs after the call, update the media row via `VideoDao.updateLanguage` / `AudioDao.updateLanguage` (FR-011 / FR-012)
- [X] T054 [P] [US6] Extend `lib/core/application/app_language_catalog.dart` consumers' tests with at least one supported ASR language not previously used, to confirm Azure / Whisper mapping covers the new tag, in `test/core/application/app_language_catalog_test.dart` (regression guard)

**Checkpoint**: All six user stories are independently functional — every spec acceptance scenario has a corresponding automated test

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories.

- [X] T055 [P] Update `docs/features/transcript.md` with a "Generate / Re-generate transcript (ASR)" section, citing the picker action, the empty-state CTA, and the deterministic upsert semantics
- [X] T056 [P] Create `docs/features/asr.md` describing the controller, the `AsrTimelineBuilder`, the `AsrAudioExtractor`, the failure-reason map, and the platform matrix (per Constitution Principle V)
- [X] T057 [P] Add a CHANGELOG entry under `## Unreleased` summarising the ASR transcript generation feature (one bullet per user story)
- [ ] T058 Run `quickstart.md` Scenarios A through K end-to-end on at least one desktop target (macOS or Windows) and record evidence (screenshots / screen recordings) in the PR description per Constitution Principle IV (SC-002 / SC-003 evidence)
- [ ] T059 [P] Add `integration_test/asr_generate_transcript_test.dart` for the calmest platform (audio-only on desktop) covering: empty state → Generate → primary track visible → tap-to-seek → highlight on playback
- [X] T060 [P] Code cleanup: remove any `print()` accidentally introduced during implementation (none expected — verify with `grep -rn 'print(' lib/features/asr/` returning no matches; QR-006)
- [X] T061 Run `bash .github/scripts/validate_ci_gates.sh` and confirm zero failures before pushing (Constitution § Flutter Quality Gates)
- [X] T062 Run `flutter analyze` and confirm zero new lints
- [X] T063 Run `dart run build_runner build --delete-conflicting-outputs` and commit any regenerated `*.g.dart` files
- [X] T064 Run `flutter test` (full suite) and confirm zero regressions in `test/features/transcript/`, `test/features/ai/`, `test/core/`
- [X] T065 Run `flutter test test/features/asr` (new suite) and confirm every new test passes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — **BLOCKS all user stories**
- **User Stories (Phase 3–8)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2)
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Foundational — **no dependencies on other stories**. MVP.
- **User Story 2 (P1)**: Depends on Foundational — extends US1 wiring but is independently testable
- **User Story 3 (P1)**: Depends on Foundational — extends the controller with provider-routing failure modes; independently testable
- **User Story 4 (P2)**: Depends on Foundational — extends `AsrTimelineBuilder` and the repository helper; independently testable
- **User Story 5 (P2)**: Depends on Foundational — extends `AsrAudioExtractor` and the controller's extract step; independently testable
- **User Story 6 (P2)**: Depends on Foundational — extends the controller with language handling; independently testable

### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation
- Models → services → UI → integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel (T002 / T003 / T004)
- All Foundational tasks marked [P] within Phase 2 can run in parallel
  - T005 + T006 + T007 + T008 (independent domain/test scaffolding)
  - T009 + T010 (implementations independent of each other)
  - T013 + T016 + T017 (regression / ARB / failure-mapping scaffolding)
  - T015 (after T014)
- All tests for a user story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members after Phase 2

---

## Parallel Examples

### Phase 2 — Foundational scaffolding fan-out

```bash
# In parallel: domain entities + tests-first scaffolding
Task: "T005 Add asr_audio_extraction_failure.dart"
Task: "T006 Add asr_generation_job.dart"
Task: "T007 Write failing asr_timeline_builder_test.dart"
Task: "T008 Write failing asr_audio_extractor_test.dart"
```

### Phase 2 — Implementations fan-out

```bash
# In parallel: implementations that touch different files
Task: "T009 Implement AsrTimelineBuilder"
Task: "T010 Implement AsrAudioExtractor"
Task: "T016 Add ARB localization keys"
Task: "T017 Add asr_failure_messages.dart"
```

### Phase 3 — User Story 1 tests-first fan-out

```bash
# In parallel: empty-state widget tests + long-media dialog scaffolding
Task: "T018 Empty state shows Generate CTA when local file is eligible"
Task: "T019 Empty state CTA busy state"
```

### Phase 4 — User Story 2 tests-first fan-out

```bash
# In parallel: picker widget tests + repository regression
Task: "T024 Picker shows Generate/Regenerate action"
Task: "T025 Re-generate keeps previous track visible while busy"
Task: "T026 Concurrent starts cancel cleanly"
Task: "T28 Echo-session row id regression"
```

### Phase 5 — User Story 3 failure-mode mapping fan-out

```bash
# In parallel: error mapping for each provider / failure mode
Task: "T033 Map ByokNotConfiguredFailure"
Task: "T034 Map credits-exhausted"
Task: "T035 Map network errors"
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Run `quickstart.md` Scenarios A + B end-to-end on desktop
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → validate Scenarios A + B → Deploy/Demo (**MVP!**)
3. Add User Story 2 → validate Scenarios C + J + K → Deploy/Demo
4. Add User Story 3 → validate Scenarios D + E + H → Deploy/Demo
5. Add User Story 4 → validate Scenario B + J replay → Deploy/Demo
6. Add User Story 5 → validate Scenario I (platform smoke) → Deploy/Demo
7. Add User Story 6 → validate Scenario F → Deploy/Demo
8. Phase 9 polish: docs, integration test, CHANGELOG, full gate run

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 + 4 (UI wiring + segmentation regression)
   - Developer B: User Story 2 + 3 (picker wiring + provider failure-mode mapping)
   - Developer C: User Story 5 + 6 (extraction + language propagation)
3. Stories complete and integrate independently — final Phase 9 merges everything

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Tests are written FIRST and confirmed failing before implementation in the same phase
- Commit after each task or logical group
- Stop at any checkpoint to validate the story independently
- Constitution Flutter Quality Gates must pass before push (T061–T065)
- No `media_kit` `Player()` ownership change; no `print()`; no raw SQL in widgets; no Flutter web