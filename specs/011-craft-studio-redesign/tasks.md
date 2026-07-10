# Tasks: Craft Studio (Redesigned)

**Input**: Design documents from `/specs/011-craft-studio-redesign/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Automated tests required per spec QR-002 (Azure Speech SDK synthesis path is manual-verification only).

**Organization**: Tasks grouped by user story. Spec 010 infrastructure reused; this is a UI + domain redesign.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story (US1–US6)
- Include exact file paths

---

## Phase 1: Setup

- [ ] T001 Add `audioplayers` dependency to `pubspec.yaml` (for preview playback; avoids media_kit single-player constraint)
- [ ] T002 [P] Add new Craft ARB keys for the redesigned UI to `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`, `lib/l10n/app_zh_CN.arb` (screen title, tool labels, style names, voice labels, actions, save button, preview player labels, hints)
- [ ] T003 [P] Run `flutter gen-l10n` to regenerate localization files after ARB additions

---

## Phase 2: Foundational (Blocking Prerequisites)

- [ ] T004 [P] Create `TranslationStyle` enum with `promptSuffix` getter (literal, natural, casual, formal, simplified, detailed, custom) in `lib/features/craft/domain/translation_style.dart`
- [ ] T005 [P] Create `AzureVoice` model + static voice catalog (~40 voices ported from web `azure-voices.ts`) + `voicesForLanguage(String baseLang)` filter helper in `lib/features/craft/domain/azure_voice.dart`
- [ ] T006 [P] Create `TranscriptTimestampEstimator` utility (sentence split on `[.。！？!?\n]`, proportional duration distribution) in `lib/features/craft/domain/transcript_timestamp_estimator.dart`
- [ ] T007 [P] Unit test for `TranscriptTimestampEstimator` in `test/features/craft/domain/transcript_timestamp_estimator_test.dart` (single sentence, multi-sentence, empty, proportional sum equals total)
- [ ] T008 [P] Unit test for `AzureVoice.voicesForLanguage` in `test/features/craft/domain/azure_voice_test.dart` (en returns ≥4, zh returns ≥4, ja returns ≥2, unknown returns empty)
- [ ] T009 Rewrite `CraftJobState` to two-tool sub-state model (translate fields + synthesize fields + shared failure/generation) in `lib/features/craft/domain/craft_job_state.dart`
- [ ] T010 Extend `CraftFailure` hierarchy for new failure types (translate style validation, voice selection, preview playback) in `lib/features/craft/domain/craft_failure.dart`
- [ ] T011 Extend `MediaLibraryRepository.importCraftedFromText` with `String? primaryTimelineJson` and `String? voice` parameters (voice included in dedupe hash) in `lib/features/library/data/library_repository.dart`
- [ ] T012 Extend `CraftTranslationServiceTranslator` to accept `TranslationStyle` + optional custom prompt, appending the style `promptSuffix` to the translation call in `lib/features/craft/data/craft_translation_service_translator.dart`
- [ ] T013 Run `flutter analyze` on Foundational changes

**Checkpoint**: Domain types, voice catalog, timestamp estimator, repository extension, and translator style support all in place.

---

## Phase 3: User Story 1 - Open the Craft screen (Priority: P1) 🎯 MVP (screen)

**Goal**: Import chooser → full-screen Craft route opens with two-tool layout.

**Independent Test**: Tap Import → Craft from text; confirm full-screen route opens, back button works.

### Implementation

- [ ] T014 [US1] Add `/craft` GoRouter route in `lib/core/routing/app_router.dart` rendering `CraftScreen`
- [ ] T015 [US1] Create `CraftScreen` scaffold (AppBar with title, responsive two-section layout: side-by-side on desktop ≥900px, stacked on mobile) in `lib/features/craft/presentation/craft_screen.dart`
- [ ] T016 [US1] Change import chooser's "Craft from text" `onTap` from sheet to `context.push('/craft')` in `lib/features/library/presentation/library_actions.dart`; remove the old `craft.showCraftSheet` import
- [ ] T017 [US1] Delete the old `lib/features/craft/presentation/craft_sheet.dart` (superseded by `craft_screen.dart`)

**Checkpoint**: Full-screen Craft route opens from the import chooser and returns via back button.

---

## Phase 4: User Story 2 - Translate with style presets and edit (Priority: P1) 🎯 MVP (translate)

**Goal**: Paste text, pick style, translate, edit result, copy, re-translate, "Use translated text".

**Independent Test**: Paste text, select "Natural" style, translate, edit a word, copy, tap "Use translated text", confirm synthesize input is pre-filled.

### Implementation

- [ ] T018 [P] [US2] Create `StylePicker` dropdown widget (localized labels for 7 styles, reveals custom prompt input when "custom" selected) in `lib/features/craft/presentation/style_picker.dart`
- [ ] T019 [US2] Implement Translate actions in `CraftController` (`setSourceText`, `setSourceLanguage`, `setTargetLanguage`, `setStyle`, `setCustomPrompt`, `setTranslatedText`, `translate`, `useTranslatedText`) in `lib/features/craft/application/craft_controller.dart`
- [ ] T020 [US2] Create `TranslateTool` widget (source/target language pickers with swap button, style picker, source text input, Translate button, editable result TextField, Copy + Re-translate + "Use translated text" action row) in `lib/features/craft/presentation/translate_tool.dart`
- [ ] T021 [US2] Extend source-language picker to include learner's profile native language at top of the options list (use `appPreferencesProvider` to read native language tag)
- [ ] T022 [US2] Unit test for `CraftController` translate flow in `test/features/craft/application/craft_controller_translate_test.dart` (happy path with style, re-translate, edit, same-language hint, copy → synthText pre-fill)

**Checkpoint**: Translate tool fully functional with styles, edit, copy, re-translate, and "Use translated text" bridge.

---

## Phase 5: User Story 3 - Synthesize with voice selection and preview (Priority: P1) 🎯 MVP (synthesize)

**Goal**: Pick Azure voice, synthesize, preview audio, re-synthesize.

**Independent Test**: Enter text, open voice picker, pick voice, synthesize, preview plays, change voice, re-synthesize.

### Implementation

- [ ] T023 [P] [US3] Create `VoicePicker` dropdown widget (calls `AzureVoice.voicesForLanguage`, shows label + gender + locale) in `lib/features/craft/presentation/voice_picker.dart`
- [ ] T024 [US3] Implement Synthesize actions in `CraftController` (`setSynthText`, `setSynthLanguage`, `setSelectedVoice`, `synthesize`) in `lib/features/craft/application/craft_controller.dart`
- [ ] T025 [US3] Create `SynthesizeTool` widget (language picker, voice picker, text input pre-filled from translate, Synthesize button, inline audio preview player using `audioplayers`, Re-synthesize action) in `lib/features/craft/presentation/synthesize_tool.dart`
- [ ] T026 [US3] Implement preview audio playback via `audioplayers` `AudioPlayer` from in-memory `Uint8List` bytes; play/pause/seek controls inline
- [ ] T027 [US3] Unit test for `CraftController` synthesize flow in `test/features/craft/application/craft_controller_synthesize_test.dart` (happy path with voice selection, re-synthesize replaces preview, language filter updates voice list, unsupported language disables action)

**Checkpoint**: Synthesize tool functional with voice picker, preview, and re-synthesize.

---

## Phase 6: User Story 4 - Save to library with timestamped transcript (Priority: P1)

**Goal**: Save synthesized audio + timestamped transcript, open player, echo mode works.

**Independent Test**: Synthesize → preview → Save → player opens with sentence-split transcript → echo mode works.

### Implementation

- [ ] T028 [US4] Implement `saveToLibrary` in `CraftController`: compute sentence-split timeline via `TranscriptTimestampEstimator`, probe audio duration (or use Azure outcome duration if available), call `importCraftedFromText` with `primaryTimelineJson` + `voice`, navigate to player on success
- [ ] T029 [US4] Add **Save to library** button + saving progress state to `SynthesizeTool` in `lib/features/craft/presentation/synthesize_tool.dart`
- [ ] T030 [US4] Unit test for save flow in `test/features/craft/application/craft_controller_save_test.dart` (timestamped transcript is multi-entry, voice stored on audio row, dedupe includes voice in hash, save failure leaves zero rows)

**Checkpoint**: Save produces a timestamped transcript + opens the player with echo mode ready.

---

## Phase 7: User Story 5 - Craft badge and library parity (Priority: P2)

**Goal**: Badge renders, reopen is instant, delete cleans up.

**Independent Test**: Save a Craft item, confirm badge in library, reopen instantly, delete cleanly.

### Implementation

- [ ] T031 [US5] Confirm the existing library badge wiring (from spec 010) renders for `provider = 'craft'` — verify no regression after the screen redesign
- [ ] T032 [US5] Repository test for dedupe (same text + voice → same id) and delete cleanup (audio + transcripts removed) in `test/features/library/library_repository_craft_test.dart` — extend the existing test file with voice-in-hash cases

**Checkpoint**: Library parity verified.

---

## Phase 8: User Story 6 - Calm failure and recovery (Priority: P2)

**Goal**: Translate, synthesize, and save failures each surface calm, actionable messages.

**Independent Test**: Force each failure type, confirm calm message + correct action button.

### Implementation

- [ ] T033 [US6] Add failure display cards to `TranslateTool` (translate failure → Retry + style hint) and `SynthesizeTool` (TTS failure → Retry + Open AI settings; save failure → Retry) in their respective widget files
- [ ] T034 [US6] Unit test for failure mapping in `test/features/craft/application/craft_controller_failure_test.dart` (translate fail → `CraftTranslateFailure`; TTS fail → `CraftTtsFailure` with `openAiSettings` action when BYOK; save fail → `CraftSaveFailure`; same-language → `CraftSameLanguageFailure` hint)

**Checkpoint**: All failure paths covered with calm, actionable UX.

---

## Phase 9: Polish & Cross-Cutting

- [ ] T035 [P] Revise `docs/decisions/0030-craft-from-text-import.md` to document the full-screen + two-tool + voice-picker + style-preset + timestamped-transcript decision
- [ ] T036 [P] Update `docs/features/library.md` — Craft screen as full-screen route (not sheet)
- [ ] T037 [P] Update `docs/features/ai.md` — Craft consumer of translation styles + Azure voice catalog
- [ ] T038 [P] Update `docs/features/transcript.md` — Craft timestamped transcript convention (sentence-split proportional timestamps)
- [ ] T039 Run `dart format lib test`
- [ ] T040 Run `flutter analyze` — resolve all errors
- [ ] T041 Run `flutter test` — all tests pass
- [ ] T042 Run `bash .github/scripts/validate_ci_gates.sh`
- [ ] T043 Walk through `specs/011-craft-studio-redesign/quickstart.md` Scenarios 1–8 on at least one platform

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Foundational — provides the screen shell for all other stories
- **US2 (Phase 4)**: Depends on US1 (needs the screen)
- **US3 (Phase 5)**: Depends on US1 (needs the screen); can run in parallel with US2
- **US4 (Phase 6)**: Depends on US3 (needs synthesis preview to exist before saving)
- **US5 (Phase 7)**: Depends on US4 (needs at least one saved item)
- **US6 (Phase 8)**: Depends on US2 + US3 (failure paths cover both tools)
- **Polish (Phase 9)**: Depends on all stories

### Parallel Opportunities

- T002, T003 can run parallel in Setup
- T004, T005, T006 can run parallel in Foundational (different domain files)
- T007, T008 can run parallel (different test files)
- T018 (StylePicker) can run parallel with other US2 tasks
- T023 (VoicePicker) can run parallel with other US3 tasks
- US2 and US3 can run in parallel after US1 (different tool widgets, different controller methods — but share the controller file, so coordinate)

---

## Implementation Strategy

### MVP First (US1 + US3 + US4)

1. Setup + Foundational
2. US1 (screen shell)
3. US3 (synthesize tool — simplest working path: paste text, synthesize, preview, save)
4. US4 (save with timestamped transcript — completes the end-to-end MVP)
5. **STOP and VALIDATE**: full flow works — paste → synthesize → save → player

### Incremental Delivery

1. Setup + Foundational → domain types ready
2. US1 → screen opens
3. US3 → synthesize works
4. US4 → save works (MVP complete)
5. US2 → translate tool added
6. US5 → library parity verified
7. US6 → failure recovery
8. Polish → docs + gates
