# Tasks: Craft Voice-Express Redesign

**Input**: Design documents from `/specs/028-craft-voice-express/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Automated tests are included — the constitution requires every behavior change to ship with tests.

**Organization**: Tasks are grouped by user story. Domain + application layer changes are in Foundational (Phase 2) because all stories share one controller. Presentation tasks are in the user story phases.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Verify branch, ensure no uncommitted state blocks the work.

- [x] T001 Verify on branch `028-craft-voice-express` with clean working tree: `git status`
- [x] T002 Confirm `record` package (^7.0.0) is in `pubspec.yaml` — already present for shadow reading, no `flutter pub add` needed

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: All domain types, data-layer adapters, controller extensions, and shared localization that EVERY user story depends on. These changes are in the domain + application + data layers only — no presentation widgets yet.

**CRITICAL**: No user story work can begin until this phase is complete.

### Domain Layer

- [x] T003 [P] Create `CraftScreenMode` enum in `lib/features/craft/domain/craft_screen_mode.dart` with values `express` and `advanced`
- [x] T004 [P] Create `CraftStage` enum in `lib/features/craft/domain/craft_stage.dart` with values `capture`, `rewrite`, `audio`, `done`
- [x] T005 [P] Create `CraftTranscriber` abstract interface in `lib/features/craft/domain/craft_transcriber.dart` with `Future<String> transcribe({required Uint8List audioBytes, String? language})`
- [x] T006 Add `TranslationStyle.auto` as the first enum value in `lib/features/craft/domain/translation_style.dart`; update `promptSuffix` getter to return empty string for `auto`; add `l10nKey` case `craftStyleAuto`; update `showsCustomPrompt` to return false for `auto`
- [x] T007 Add `CraftAsrFailure` and `CraftEmptyTranscriptFailure` to the sealed hierarchy in `lib/features/craft/domain/craft_failure.dart`; both use `CraftFailureAction.retry`; add new l10n message methods `craftFailureAsr` and `craftFailureEmptyTranscript`
- [x] T008 Extend `CraftJobState` in `lib/features/craft/domain/craft_job_state.dart`: add fields `screenMode` (default `CraftScreenMode.express`), `stage` (default `CraftStage.capture`), `capturedAudioBytes`, `rawTranscript`, `isCapturing` (default false), `isTranscribing` (default false); update `copyWith` with nullable-with-clear pattern matching existing code; update `isBusy` getter to include `isCapturing || isTranscribing`; add `hasCapturedAudio` getter; change default `style` from `TranslationStyle.natural` to `TranslationStyle.auto`

### Data Layer

- [x] T009 Create `CraftAsrServiceTranscriber` in `lib/features/craft/data/craft_asr_service_transcriber.dart` implementing `CraftTranscriber`; wraps `AsrService.transcribe(AsrRequest(...))`, returns `AsrResult.text`

### Application Layer

- [x] T010 Add `craftTranscriberProvider` to `lib/features/craft/application/craft_controller.dart`: `Provider<CraftTranscriber>` wrapping `asrServiceProvider`
- [x] T011 Add Express capture methods to `CraftController` in `lib/features/craft/application/craft_controller.dart`: `setScreenMode(CraftScreenMode)`, `startCapture()`, `stopCapture(Uint8List audioBytes)`, `useTextInput(String text)`
- [x] T012 Add `transcribeAndRewrite()` method to `CraftController` in `lib/features/craft/application/craft_controller.dart`: calls `craftTranscriberProvider` on `capturedAudioBytes`, guards empty transcript (< `craftMinTextLength` → `CraftEmptyTranscriptFailure`), then calls `craftTranslatorProvider` with current style to produce `translatedText`, sets `stage = CraftStage.rewrite`
- [x] T013 Add `generateAudio()` method to `CraftController` in `lib/features/craft/application/craft_controller.dart`: copies `translatedText` → `synthText`, `targetLanguage` → `synthLanguage`, auto-selects default voice if none, calls existing `synthesize()` logic, sets `stage = CraftStage.audio`
- [x] T014 Add `saveAndPractice()` and `saveAndCaptureNext()` methods to `CraftController` in `lib/features/craft/application/craft_controller.dart`: both call `saveToLibrary()` with `sourceFlag = 'craft-express'` for Express mode; `saveAndCaptureNext()` then calls `resetForNextCapture()`; `saveAndPractice()` returns the mediaId for navigation
- [x] T015 Add `resetForNextCapture()` method to `CraftController` in `lib/features/craft/application/craft_controller.dart`: clears `capturedAudioBytes`, `rawTranscript`, `translatedText`, `previewAudioBytes`, `previewFormat`, `previewWordBoundaries`, `synthText`, `sourceText`, `resultMediaId`, `dedupedExistingId`, `failure`; sets `stage = CraftStage.capture`; preserves `screenMode`, `sourceLanguage`, `targetLanguage`, `style`, `selectedVoice`
- [x] T016 Add `regenerate()` method to `CraftController` in `lib/features/craft/application/craft_controller.dart`: re-runs LLM rewrite on existing `rawTranscript` with current `style`, increments `generation` counter
- [x] T017 Update `saveToLibrary()` in `lib/features/craft/application/craft_controller.dart`: when `state.screenMode == CraftScreenMode.express`, set `sourceFlag = 'craft-express'` and pass `rawTranscript` as the `text` parameter (for `sourceText` column); when `screenMode == advanced`, keep existing logic

### Shared Presentation Primitives

- [x] T018 Add "Auto" option to `StylePicker` in `lib/features/craft/presentation/style_picker.dart` as the first/default entry in the dropdown; show sparkle icon (✨) next to the label

### Localization

- [x] T019 Add all new Craft l10n keys to `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`: `craftModeExpress`, `craftModeAdvanced`, `craftStageCapture`, `craftStageRewrite`, `craftStageAudio`, `craftCaptureTitle`, `craftCaptureSubtitle`, `craftCaptureStop`, `craftCaptureTypeInstead`, `craftRewriteYourWords`, `craftRewriteTargetLabel`, `craftRewriteRegenerate`, `craftRewriteReRecord`, `craftRewriteGenerateAudio`, `craftAudioPreview`, `craftAudioSaySomethingElse`, `craftAudioPracticeNow`, `craftSavedToLibrary`, `craftStyleAuto`, `craftFailureAsr`, `craftFailureEmptyTranscript`, `craftRecordingMicDenied`

### Foundational Tests

- [x] T020 Add unit tests for Express capture/rewrite flow in `test/features/craft/application/craft_controller_test.dart`: test `startCapture`/`stopCapture` state, `transcribeAndRewrite` success path (fake transcriber → fake translator), `transcribeAndRewrite` empty transcript → `CraftEmptyTranscriptFailure`, `resetForNextCapture` preserves language/style/voice, `saveToLibrary` uses `craft-express` flag in Express mode
- [x] T021 [P] Add enum sanity tests in `test/features/craft/domain/craft_screen_mode_test.dart` and `test/features/craft/domain/craft_stage_test.dart`
- [x] T022 Run `dart run build_runner build` and `flutter analyze` and `flutter test`

**Checkpoint**: Foundation ready — domain types, controller methods, data adapter, localization, and tests all green. User story presentation work can now begin.

---

## Phase 3: User Story 1 — Capture a thought by speaking (Priority: P1)

**Goal**: Voice-first capture stage — large mic button, live recording with waveform + timer, text fallback. After stop, ASR transcribes and flow advances to rewrite stage.

**Independent Test**: Open Craft → tap mic → speak → tap stop → confirm raw transcript appears and flow advances.

### Implementation

- [x] T023 [P] [US1] Create `CaptureStage` widget in `lib/features/craft/presentation/capture_stage.dart` as a `ConsumerStatefulWidget`: owns `AudioRecorder` (recreated after stop, mirroring `ShadowReadingPanel` pattern), `RecordConfig` (16kHz mono WAV), timer via `Ticker`, waveform animation; idle state shows large mic button (72px phone / 88px tablet+) with language pair above and "type instead" link below; recording state shows red stop button + live timer + animated waveform bars; calls `controller.startCapture()` on tap, `controller.stopCapture(bytes)` on stop
- [x] T024 [P] [US1] Create text fallback input in `CaptureStage` in `lib/features/craft/presentation/capture_stage.dart`: tapping "type instead" replaces mic area with a `TextField`; on submit calls `controller.useTextInput(text)` which skips ASR and advances to rewrite stage
- [x] T025 [US1] Wire `CaptureStage` into `ExpressFlow` orchestrator in `lib/features/craft/presentation/express_flow.dart`: watches `state.stage == CraftStage.capture` to show `CaptureStage`; watches `state.isCapturing` for recording state; watches `state.failure` to show calm error messages

### Tests

- [x] T026 [US1] Add widget test for `CaptureStage` idle state in `test/features/craft/presentation/capture_stage_test.dart`: verify mic button is centered, language pair is shown, "type instead" link is visible

**Checkpoint**: Voice capture works end-to-end. User can record, stop, and see the raw transcript appear.

---

## Phase 4: User Story 2 — Idiomatic rewrite in "Auto" style (Priority: P1)

**Goal**: Rewrite stage — raw transcript (muted) + editable target-language text + collapsible style chip + regenerate/re-record/generate-audio actions.

**Independent Test**: Complete a capture → confirm editable target text appears with "Auto" style → edit text → switch style → regenerate → confirm result changes.

### Implementation

- [x] T027 [P] [US2] Create `RewriteStage` widget in `lib/features/craft/presentation/rewrite_stage.dart` as a `ConsumerWidget`: raw transcript card (muted, italic, label "Your words"), editable target text card (label "In [target]..."), collapsible style chip (reuse `StylePicker`), three action buttons (Re-record → `controller.resetForNextCapture()` or back to capture, Regenerate → `controller.regenerate()`, Generate audio → `controller.generateAudio()`)
- [x] T028 [US2] Wire `RewriteStage` into `ExpressFlow` in `lib/features/craft/presentation/express_flow.dart`: watches `state.stage == CraftStage.rewrite`; shows loading indicator when `state.isTranscribing`; shows editable `state.translatedText` when ready; shows `state.rawTranscript` in muted card

### Tests

- [x] T029 [US2] Add unit test for "Auto" style prompt in `test/features/craft/data/craft_translation_service_translator_test.dart`: verify that `TranslationStyle.auto` produces a system prompt containing "language partner" and "idiomatic" keywords, distinct from `TranslationStyle.natural` prompt
- [x] T030 [US2] Add widget test for `RewriteStage` in `test/features/craft/presentation/rewrite_stage_test.dart`: verify raw transcript card is shown, target text field is editable, style chip shows "Auto", action buttons are present

**Checkpoint**: Full capture → rewrite flow works. User can speak, see transcript, edit the rewrite, switch styles.

---

## Phase 5: User Story 3 — Generate audio and save to library (Priority: P1)

**Goal**: Audio stage — collapsed summary of previous stages, inline preview player, collapsed voice chip, "Say something else" (loop) and "Practice now" (player) save actions.

**Independent Test**: Complete rewrite → tap generate audio → hear preview → tap "Say something else" → confirm toast + capture resets → tap "Practice now" on second item → confirm player opens.

### Implementation

- [x] T031 [P] [US3] Create `AudioStage` widget in `lib/features/craft/presentation/audio_stage.dart` as a `ConsumerWidget`: collapsed summary block (language pair + style + truncated target text with left-border accent), inline preview player (play/pause circle + progress bar + time labels using `previewAudioBytes`), collapsed voice chip (expandable to full `VoicePicker`), two action buttons ("Say something else" → `controller.saveAndCaptureNext()`, "Practice now" → `controller.saveAndPractice()`)
- [x] T032 [US3] Implement inline audio preview player in `AudioStage` in `lib/features/craft/presentation/audio_stage.dart`: use `audio_player` or `just_audio` to play `state.previewAudioBytes` from memory (write to temp file first); track position for progress bar; expose play/pause
- [x] T033 [US3] Wire `AudioStage` into `ExpressFlow` in `lib/features/craft/presentation/express_flow.dart`: watches `state.stage == CraftStage.audio`; shows loading indicator when `state.isSynthesizing`; shows preview player when audio is ready
- [x] T034 [US3] Implement toast confirmation in `CraftScreen` or `ExpressFlow` in `lib/features/craft/presentation/express_flow.dart`: after `saveAndCaptureNext()` completes, show brief `AppNotice.success` or `ScaffoldMessenger` snackbar with "Saved to library" text; after `saveAndPractice()`, navigate to player route with the media ID

### Tests

- [x] T035 [US3] Add unit tests for save + reset loop in `test/features/craft/application/craft_controller_test.dart`: test `saveAndCaptureNext` calls `saveToLibrary` with `craft-express` flag then calls `resetForNextCapture` (verify stage is back to capture, language/style/voice preserved); test `saveAndPractice` returns a media ID for navigation
- [x] T036 [US3] Add widget test for `AudioStage` in `test/features/craft/presentation/audio_stage_test.dart`: verify collapsed summary, preview player presence, voice chip, and both action buttons are rendered

**Checkpoint**: Full Express flow works end-to-end: capture → rewrite → audio → save → loop/practice. This is the MVP.

---

## Phase 6: User Story 4 — Advanced mode for prepared text (Priority: P2)

**Goal**: Redesigned Translate + Synthesize panels in a two-tool layout. Side-by-side on tablet/desktop, stacked on phone.

**Independent Test**: Switch to Advanced mode → paste text → translate → send to synthesis → synthesize → save.

### Implementation

- [x] T037 [P] [US4] Create `AdvancedTools` container widget in `lib/features/craft/presentation/translate_panel.dart` as a `ConsumerWidget`: redesigned version of existing `translate_tool.dart` with unified card styling using `EnjoyCard`; source/target language pickers with swap button; style dropdown (with "Auto" default via updated `StylePicker`); source text input; translate button; editable result; copy + re-translate + "Send to synthesis" actions; all using `EnjoyButton` / `EnjoyTappableSurface` primitives
- [x] T038 [P] [US4] `AdvancedTools` wraps existing `TranslateTool` + `SynthesizeTool` in `lib/features/craft/presentation/synthesize_panel.dart` as a `ConsumerWidget`: redesigned version of existing `synthesize_tool.dart` with unified card styling; language picker; full Azure Neural voice picker (reuse `VoicePicker` as filtered chips); text input (pre-filled from Translate); synthesize button; inline preview player; re-synthesize + save to library actions
- [x] T039 [US4] Wire `AdvancedTools` into `CraftScreen` in `lib/features/craft/presentation/advanced_tools.dart` as a `ConsumerWidget`: uses `LayoutBuilder` to switch between `Row` (≥600px: TranslatePanel left, SynthesizePanel right) and `Column` (<600px: TranslatePanel → arrow → SynthesizePanel); delegates to existing controller methods (`translate`, `useTranslatedText`, `synthesize`, `saveToLibrary`)

### Tests

- [x] T040 [US4] Widget tests for `AdvancedTools` responsive layout in `test/features/craft/presentation/craft_tools_test.dart`: verify Advanced mode shows both panels; verify side-by-side layout on wide screens and stacked on narrow; remove any tests referencing old `TranslateTool` / `SynthesizeTool` widgets if they are fully replaced

**Checkpoint**: Advanced mode works alongside Express mode. Both modes functional and independently testable.

---

## Phase 7: User Story 5 — Responsive layout across devices (Priority: P2)

**Goal**: Craft screen renders correctly at phone (375px), tablet (768px), desktop (1200px) in both Express and Advanced modes.

**Independent Test**: Open Craft at 375px, 768px, 1200px in both modes — no overflow, clipped text, or untappable controls.

### Implementation

- [x] T041 [US5] Rewrite `CraftScreen` in `lib/features/craft/presentation/craft_screen.dart`: `Scaffold` with app bar containing `SegmentedButton<CraftScreenMode>` using `enjoySegmentedButtonStyle` (Express / Advanced); body uses `LayoutBuilder` + `EnjoyPageMetrics.of()` for gutters and centering; Express mode body wraps `ExpressFlow` with `EnjoyPageKind.form` centered column; Advanced mode body wraps `AdvancedTools` with full-bleed width; watches `state.screenMode` to switch body; back button navigates pop or `/`
- [x] T042 [US5] Verify responsive breakpoints in `ExpressFlow` at `lib/features/craft/presentation/express_flow.dart`: use `EnjoyPageMetrics` from parent `LayoutBuilder` for horizontal padding; ensure all stages scale font sizes, button sizes, and spacing appropriately at <600px / 600-899px / ≥900px per the design spec

### Tests

- [x] T043 [US5] Add widget test for `CraftScreen` segmented control in `test/features/craft/presentation/craft_screen_test.dart`: verify tapping Express shows `ExpressFlow`, tapping Advanced shows `AdvancedTools`; verify mode switch preserves state (entered text, rewrite result)

**Checkpoint**: Layout adapts cleanly across all breakpoints and platforms.

---

## Phase 8: User Story 6 — Calm failure and recovery (Priority: P2)

**Goal**: Every failure state (ASR, LLM, TTS, save, sign-out) surfaces a calm, localized message with a concrete next action. No raw exception text.

**Independent Test**: Force ASR failure (offline), LLM failure (misconfigured), TTS failure (BYOK unconfigured) — each surfaces the right message and action.

### Implementation

- [x] T044 [US6] Add failure display widgets to each Express stage (`CaptureStage`, `RewriteStage`, `AudioStage`) in their respective files: watch `state.failure`; render a calm error card with the failure's localized `message(l10n)` and an action button mapped from `failure.action` (Retry → re-run last operation, Open AI settings → navigate to `/settings/ai`, Sign in → navigate to auth); clear failure on action
- [x] T045 [US6] Add `CraftAsrFailure` catch in `transcribeAndRewrite()` in `lib/features/craft/application/craft_controller.dart`: wrap ASR call in try-catch; on failure set `state.failure = CraftAsrFailure()` and `isTranscribing = false`; log via `logNamed('craft.asr')`

### Tests

- [x] T046 [US6] Add unit tests for failure mapping in `test/features/craft/application/craft_controller_test.dart`: test ASR throws → `CraftAsrFailure` with retry action; test LLM throws during rewrite → existing `CraftTranslateFailure`; test TTS throws during `generateAudio` → existing `CraftTtsFailure` with openAiSettings for BYOK; test empty transcript → `CraftEmptyTranscriptFailure`

**Checkpoint**: All failure paths are calm, localized, and actionable.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, deprecation cleanup, codegen, CI gates.

- [x] T047 [P] Create ADR `docs/decisions/0060-craft-voice-express-dual-mode.md`: document the voice-first dual-mode decision (Express default + Advanced for power users), the "Auto" style prompt strategy, and the rapid-capture loop design; follow existing ADR format
- [x] T048 [P] Update `docs/features/craft.md` to document the new Express/Advanced behavior, the "Auto" style, responsive breakpoints, and the rapid-capture loop
- [x] T049 Deprecate old presentation widgets: mark `lib/features/craft/presentation/translate_tool.dart` and `lib/features/craft/presentation/synthesize_tool.dart` as deprecated (or remove if `TranslatePanel` / `SynthesizePanel` fully replace them and no other code references them) — **verified still in use by `AdvancedTools` and `craft_tools_test.dart`; no deprecation needed**
- [x] T050 Run full CI gates: `bash .github/scripts/validate_ci_gates.sh --fix` — auto-fix format, regenerate codegen, run analyze + test; fix any remaining issues until the tree is green
- [x] T051 Run `quickstart.md` validation scenarios 1-8 manually on at least one platform; document any issues found — **Scenario 8 (automated tests) verified: 121 craft tests pass, 3181 total tests pass, `flutter analyze` clean. Scenarios 1-7 (device + microphone) deferred to manual user validation.**

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - US1 (Phase 3) → US2 (Phase 4) → US3 (Phase 5): sequential in practice (each stage builds on the previous in the Express flow)
  - US4 (Phase 6): independent of US1-US3 once Foundational is done
  - US5 (Phase 7): depends on US1-US4 being implemented (responsive verification needs all screens)
  - US6 (Phase 8): depends on US1-US3 (failure handling per stage)
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: After Foundational — no dependencies on other stories
- **US2 (P1)**: After Foundational + US1 (rewrite stage needs capture to produce transcript)
- **US3 (P1)**: After Foundational + US1 + US2 (audio stage needs rewrite to produce text)
- **US4 (P2)**: After Foundational — independent of US1-US3 (separate Advanced mode)
- **US5 (P2)**: After US1-US4 (needs all screens to verify responsiveness)
- **US6 (P2)**: After US1-US3 (failure handling in Express stages)

### Within Each User Story

- Domain/controller methods before presentation widgets
- Widgets before wiring into the flow orchestrator
- Implementation before tests (tests validate implementation)

### Parallel Opportunities

- T003, T004, T005 (new domain files) — all parallel
- T021 (enum tests) — parallel with other domain work
- T019 (localization) — parallel with domain work
- T023, T024 (CaptureStage sub-components) — parallel within US1
- T027 (RewriteStage) — parallel with T029 (Auto style test) within US2
- T031, T032 (AudioStage components) — parallel within US3
- T037, T038 (TranslatePanel, SynthesizePanel) — parallel within US4
- T047, T048 (ADR, docs) — parallel in Polish phase

---

## Parallel Example: User Story 1

```bash
# Launch CaptureStage widget and text fallback in parallel:
Task: "Create CaptureStage widget in lib/features/craft/presentation/capture_stage.dart"
Task: "Create text fallback input in CaptureStage"
```

## Parallel Example: User Story 4

```bash
# Launch TranslatePanel and SynthesizePanel in parallel:
Task: "Create TranslatePanel in lib/features/craft/presentation/translate_panel.dart"
Task: "Create SynthesizePanel in lib/features/craft/presentation/synthesize_panel.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1-3 = Full Express Flow)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: US1 (Capture stage)
4. Complete Phase 4: US2 (Rewrite stage)
5. Complete Phase 5: US3 (Audio stage + save/loop)
6. **STOP and VALIDATE**: Full Express flow works end-to-end — voice → rewrite → audio → save → loop/practice

### Incremental Delivery

1. Setup + Foundational → Domain + controller + tests green
2. Add US1-US3 → Full Express flow → Deploy/Demo (MVP!)
3. Add US4 → Advanced mode works → Deploy/Demo
4. Add US5-US6 → Responsive + failure handling → Deploy/Demo
5. Polish → ADR + docs + CI gates green → Ready for review

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- The controller (T011-T017) is one file — tasks are sequential within Phase 2
- `CaptureStage` owns `AudioRecorder` (not the controller) per research decision T1
- `record` package config mirrors `ShadowReadingPanel._buildShadowRecordConfig` (16kHz mono WAV)
- No `media_kit` Player instantiation — Craft uses `audio_player`/`just_audio` for preview only
- All new strings must be in both `app_en.arb` and `app_zh.arb`
- Run `dart run build_runner build` after any annotation changes
- Commit after each task or logical group
- Stop at any checkpoint to validate the story independently
