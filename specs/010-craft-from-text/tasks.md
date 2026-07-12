---
description: "Task list for Craft from Text (AI-generated audio materials)"
---

# Tasks: Craft from Text (AI-generated audio materials)

**Input**: Design documents from `/specs/010-craft-from-text/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are required for changed behavior per spec QR-002 and Constitution II. The Azure Speech SDK path is the only manual-verification surface (platform-channel hop on each OS); it is documented in `quickstart.md` Scenario 15.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `lib/features/craft/{application,data,domain,presentation}/`
- **Shared code**: `lib/core/`, `lib/data/`, `lib/features/{library,ai}/`
- **Tests**: `test/features/craft/`, `test/features/library/`
- **Feature docs**: `docs/features/{library,ai,settings,transcript}.md`
- **ADRs**: `docs/decisions/0043-craft-from-text-import.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the Craft feature folder structure and confirm the target paths.

- [X] T001 Create Craft feature folder skeleton `lib/features/craft/{application,data,domain,presentation}` and matching test folders `test/features/craft/{application,presentation}` (no `data/` tests; no library data test for Craft — repository tests live under `test/features/library/library_repository_craft_test.dart`)
- [X] T002 [P] Add a placeholder `lib/features/craft/README.md` linking to `specs/010-craft-from-text/spec.md`, `plan.md`, and the new ADR (replaced by real content in the Polish phase)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented. Closes the Enjoy AI TTS gap, extends the repository, defines Craft domain types, and adds the localization strings.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 Add the Craft localization keys listed in `specs/010-craft-from-text/plan.md` § Localization keys to `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`, and `lib/l10n/app_zh_CN.arb` (each key, including the existing `youtubeBadge` slot used by `libraryProviderCraftBadge`)
- [X] T004 [P] Create `CraftMode` enum (`translateThenSpeak`, `speakDirectly`) in `lib/features/craft/domain/craft_mode.dart` with `name`, `requiresSourceLanguage`, `requiresSecondaryTranscript` getters
- [X] T005 [P] Create sealed `CraftFailure` hierarchy (`translate`, `tts`, `save`, `signInRequired`, `offline`, `sameLanguage`, `vendorUnsupportedLanguage`) in `lib/features/craft/domain/craft_failure.dart`; expose a localized `message(AppLocalizations)` and an optional `action` enum (`retry`, `openAiSettings`, `switchToSpeakDirectly`)
- [X] T006 [P] Create `CraftRequest` value object (mode, text, normalizedText, sourceLanguage?, targetLanguage, voice?) in `lib/features/craft/domain/craft_request.dart` with `CraftRequest.normalize(text)` helper (NFC + whitespace-collapse)
- [X] T007 [P] Create `CraftJobStatus` enum (`idle`, `validating`, `translating`, `synthesizing`, `saving`, `completed`, `failed`) in `lib/features/craft/domain/craft_job_status.dart`
- [X] T008 [P] Create `CraftJobState` (status, mode, text, normalizedText, sourceLanguage?, targetLanguage, failure?, generation, resultMediaId?, dedupedExistingId?) in `lib/features/craft/domain/craft_job_state.dart`
- [X] T009 Add `FileStorage.importBytes(Uint8List bytes, {required String extension})` method to `lib/data/files/file_storage.dart` (parallel to `importPickedFile`); returns `FileImportResult(fileUri, contentHashHex, fileSize)`; writes via `IOSink` to keep memory bounded per plan QR-005
- [X] T010 Unit test for `FileStorage.importBytes` in `test/data/files/file_storage_import_bytes_test.dart` covering happy path, content hash determinism, and extension-based file naming
- [X] T011 Extend `AzureTokenCache.getToken` in `lib/data/api/services/ai/azure_token_cache.dart` to accept `String purpose = 'assessment'` (default keeps back-compat); the `usage` payload sent to `POST /azure/tokens` now uses the requested purpose; `clear()` unchanged
- [X] T012 Unit test for `AzureTokenCache` purpose: 'tts' path in `test/features/ai/azure_token_cache_tts_test.dart` (parallels existing `azure_token_cache_dedup_test.dart`); assert the JSON payload sent to the worker contains `'purpose': 'tts'` and no `assessment` block
- [X] T013 Replace `EnjoyTtsCapability.synthesize` stub (`UnimplementedError`) with Azure Speech SDK call in `lib/features/ai/data/enjoy/enjoy_tts_capability.dart`: fetch a token via `AzureTokenCache.getToken(durationSeconds: estimatedSeconds, purpose: 'tts')`, call `AzureSpeech.instance.synthesize(AzureSpeechSynthesisParams(text, language, subscriptionKey, region, voice))`, return `TtsResult(audioBytes, format)`. Reuse `azure_language_mapper.dart` for locale mapping. Mirror `EnjoyAssessmentCapability`'s `on AzureSpeechException → ApiException` mapping.
- [X] T014 Unit test for `EnjoyTtsCapability` happy + token cache miss + Azure exception paths in `test/features/ai/enjoy_tts_capability_test.dart`
- [X] T015 Add `MediaLibraryRepository.importCraftedFromText({Uint8List audioBytes, required String audioFormat, required CraftMode mode, required String learningLanguage, String? sourceLanguage, required String text, required String normalizedText, required String signedInUserId})` to `lib/features/library/data/library_repository.dart`: dedupe by `SHA-256('${mode.name}|$learningLanguage|$normalizedText')`, write via `FileStorage.importBytes`, single Drift transaction wrapping `audioDao.insertRow` + `transcriptDao.upsert(primary)` + optional `transcriptDao.upsert(secondary)` for Translate then speak, `SyncEnqueueFn(SyncEntityType.audio, id, SyncAction.create)`, ffmpeg duration probe in a worker isolate (same path as `importMedia`)
- [X] T016 Repository tests for `importCraftedFromText` in `test/features/library/library_repository_craft_test.dart`: happy Speak directly, happy Translate then speak (asserts primary + secondary transcript rows), dedupe on re-import, save failure leaves zero rows, language tag canonicalization, ffmpeg duration probe populates `durationSeconds`
- [X] T017 Regenerate codegen via `dart run build_runner build --delete-conflicting-outputs` so future `@riverpod` providers in `lib/features/craft/application/` produce valid `*.g.dart` (existing files: regenerate `library_repository_provider.g.dart`, `ai_capability_providers.g.dart`, `ai_modality_config_controller.g.dart` if they touched annotations)
- [X] T018 Run `flutter analyze` and `flutter test --no-pub` on existing test suite to confirm Foundational changes do not regress anything before user-story work begins

**Checkpoint**: Foundation ready — `CraftMode`, `CraftFailure`, `CraftRequest`, `CraftJobState`, `CraftJobStatus`, `FileStorage.importBytes`, `AzureTokenCache` (purpose: tts), `EnjoyTtsCapability`, `MediaLibraryRepository.importCraftedFromText`, and Craft localization keys all in place. User story implementation can now begin.

---

## Phase 3: User Story 1 - Discover Craft from text in the import chooser (Priority: P1) 🎯 MVP (entry)

**Goal**: A learner who taps Import sees three entries — From file, From YouTube URL, Craft from text — in that order, with Craft clearly distinguished.

**Independent Test**: Open the import chooser on Android, iOS, macOS, and Windows; confirm exactly three entries in the expected order; confirm tapping Craft opens the Craft sheet (will be a stub until Phase 4 wires the real handler).

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T019 [P] [US1] Widget test for `showImportChooser` showing three entries with localized labels in `test/features/library/library_import_chooser_test.dart` (covers US1 acceptance scenarios 1–3)
- [X] T020 [P] [US1] Widget test for `MediaCardTile` rendering the Craft provider badge in `test/features/library/library_provider_badge_test.dart` (covers US5 acceptance scenario 1 — included early so the badge is ready when US3 produces the first item)

### Implementation for User Story 1

- [X] T021 [US1] Add the third `ListTile` (`Icons.auto_awesome_outlined` + `l10n.importCraftFromText`) to `showImportChooser` in `lib/features/library/presentation/library_actions.dart`, between the YouTube tile and the closing of the column. Stub `onTap` to `Navigator.pop(ctx); unawaited(showCraftSheet(context, ref))`; the sheet function is added in US3 (T032) — for this phase use a TODO comment and a no-op handler that calls `unawaited(_debugStubCraftSheet(context, ref))` defined locally.
- [X] T022 [P] [US1] Add the Craft provider badge wiring (`switch (media.provider) { 'youtube' => l10n.youtubeBadge, 'craft' => l10n.libraryProviderCraftBadge, _ => null }`) to the library grid builder in `lib/features/library/presentation/widgets/local_library_tab_view.dart` and to the home screen grid in `lib/features/library/presentation/home_screen.dart` (covers US5 acceptance scenarios 1–2)
- [X] T023 [US1] Verify the import chooser renders identically on Android, iOS, macOS, Windows (smoke check via `quickstart.md` Scenario 15 affordances); document any platform-specific deviations in the plan / spec follow-ups

**Checkpoint**: US1 fully functional. Tapping Import shows three entries; tapping Craft opens the debug stub (replaced by the real sheet in US3). Library badge renders for `provider = 'craft'`.

---

## Phase 4: User Story 3 - Speak directly (Priority: P1) 🎯 MVP (end-to-end)

**Goal**: A learner who pastes learning-language text, picks Speak directly, and taps Craft lands in the player with a playable audio item whose primary transcript equals the entered text.

**Independent Test**: Run `quickstart.md` Scenarios 2 (Speak directly) and 13 (offline banner) against an Enjoy AI default config; a `provider = 'craft'`, `source = 'craft-direct'` audio row appears; the player opens with the expected audio + transcript; re-opening the item does not re-synthesize.

### Tests for User Story 3

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T024 [P] [US3] Unit test for `CraftController` Speak directly mode in `test/features/craft/application/craft_controller_test.dart`: happy path (synthesize succeeds → repository write → `completed` with mediaId), dedupe (same content hash → `dedupedExistingId` set, no second synthesize), offline (offline at submit → `failed(offline)`, no synthesize), empty text (action disabled, no call), invalid language picker (no call). Inject stub `CraftSynthesizer` + stub `MediaLibraryRepository`.
- [X] T025 [P] [US3] Widget test for `CraftSheet` Speak directly mode in `test/features/craft/presentation/craft_sheet_test.dart`: mode toggle hides source-language picker, character counter updates on input, paste-from-clipboard prefills, Craft action disabled at <10 chars, dialog shown on submit, "Already in your library" callout when dedupe fires
- [X] T026 [P] [US3] Unit test for `craftOnlineProvider` in `test/features/craft/application/craft_online_provider_test.dart` (parity test — values match the underlying connectivity stream)

### Implementation for User Story 3

- [X] T027 [P] [US3] Create `CraftSynthesizer` abstract class (`Future<TtsResult> synthesize({required String text, required String language, String? voice})`) in `lib/features/craft/domain/craft_synthesizer.dart`; provide a `CraftTtsServiceSynthesizer` adapter that wraps `TtsService.synthesize` in `lib/features/craft/data/craft_tts_service_synthesizer.dart`
- [X] T028 [P] [US3] Create `craftOnlineProvider` (Riverpod `StreamProvider<bool>` wrapping `connectivity_plus`) in `lib/features/craft/application/craft_online_provider.dart`
- [X] T029 [P] [US3] Create `craftLanguageHistoryProvider` (Riverpod `NotifierProvider<CraftLanguageHistory>` remembering the last source-language pick) in `lib/features/craft/application/craft_language_history.dart`
- [X] T030 [US3] Create `CraftController` (`@riverpod` `Notifier<CraftJobState>`) in `lib/features/craft/application/craft_controller.dart`: state setters (`selectMode`, `setText`, `setSourceLanguage`, `setTargetLanguage`, `reset`), same-language detection (`text.length > 50 && sourceLanguage == targetLanguage → emit CraftFailure.sameLanguage in the validation stage`), `submit()` orchestrating translate (only in Translate then speak) → synthesize → repository write with discard-on-failure invariants from `data-model.md`. Inject `CraftSynthesizer`, `MediaLibraryRepository`, optional `TranslationService`.
- [X] T031 Run `dart run build_runner build --delete-conflicting-outputs` to generate `craft_controller.g.dart`, `craft_online_provider.g.dart`, `craft_language_history.g.dart`
- [X] T032 [US3] Create `CraftSheet` entry widget in `lib/features/craft/presentation/craft_sheet.dart` (`showCraftSheet(BuildContext, WidgetRef)` exported; uses `showEnjoySheet`, `showEnjoyAlertDialog` for the success / dedupe dialogs, `AppNotice` for failures). Replaces the `T021` debug stub via a single update of the `onTap` in `library_actions.dart`.
- [X] T033 [P] [US3] Create `CraftModeSelector` widget (segmented button: Translate then speak / Speak directly) in `lib/features/craft/presentation/craft_mode_selector.dart`
- [X] T034 [P] [US3] Create `CraftTextInput` widget (TextField + paste-from-clipboard + live character counter + length-cap truncation notice) in `lib/features/craft/presentation/craft_text_input.dart`
- [X] T035 [P] [US3] Create `CraftLanguageFields` widget (source + target language pickers; source hidden in Speak directly; reuses `showContentLanguagePicker`) in `lib/features/craft/presentation/craft_language_fields.dart`
- [X] T036 [P] [US3] Create `CraftProgressDialog` widget (import-blocking dialog with stage label) in `lib/features/craft/presentation/craft_progress_dialog.dart`. Mirrors `importYoutubeFromDialog`'s `_dismissBlockingImportDialogThen` pattern.
- [X] T037 [US3] Replace the T021 debug stub with `unawaited(showCraftSheet(context, ref))` in `lib/features/library/presentation/library_actions.dart`
- [X] T038 [US3] Verify performance budget per QR-004 / SC-003: Speak directly on a ~200-char sample completes in under 20 s on a normal connection (manual log + `quickstart.md` Scenario 2 evidence)

**Checkpoint**: US3 fully functional. Discover + Speak directly = MVP end-to-end. Tapping Import → Craft from text → Speak directly → paste text → Craft lands the learner in the player with a `provider = 'craft'`, `source = 'craft-direct'` audio item.

---

## Phase 5: User Story 2 - Translate then speak (Priority: P1)

**Goal**: A learner pastes text in any language, picks Translate then speak, picks source + target languages, taps Craft, and lands in the player with the translated learning-language audio + a bilingual transcript overlay.

**Independent Test**: Run `quickstart.md` Scenarios 3 (Translate then speak) and 4 (same-language affordance); confirm primary transcript in target language, secondary transcript in source language, no translation API call when source == target.

### Tests for User Story 2

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T039 [P] [US2] Extend `CraftController` tests in `test/features/craft/application/craft_controller_test.dart` for Translate then speak: translate succeeds → synthesize → primary + secondary transcript written; translate failure discards everything; same-language flag fires suggestion without calling `TranslationService`; secondary transcript `referenceId` matches primary id; `translationKey` on the audio row equals the source language
- [X] T040 [P] [US2] Extend `CraftSheet` widget test in `test/features/craft/presentation/craft_sheet_test.dart` to cover the source-language picker visibility (Translate then speak only), the same-language suggestion chip + one-tap switch affordance, and the secondary transcript badge after success

### Implementation for User Story 2

- [X] T041 [US2] Add `CraftTranslator` abstract (`Future<String> translate({required String text, required String sourceLanguage, required String targetLanguage})`) to `lib/features/craft/domain/craft_translator.dart`; provide a `CraftTranslationServiceTranslator` adapter in `lib/features/craft/data/craft_translation_service_translator.dart`
- [X] T042 [US2] Wire `CraftTranslator` into `CraftController` in `lib/features/craft/application/craft_controller.dart`; controller calls translate ONLY when `mode == CraftMode.translateThenSpeak && sourceLanguage != targetLanguage`; otherwise uses the entered text directly as the synthesis input. Same-language path emits a `CraftFailure.sameLanguage` in the validating stage and surfaces the suggestion chip via state, but does NOT block submit (the user can dismiss and proceed).
- [X] T043 [US2] Update `CraftLanguageFields` widget in `lib/features/craft/presentation/craft_language_fields.dart` to expose source-language picker only in Translate then speak mode (was hidden in Speak directly); add tooltip / placeholder localization for both pickers
- [X] T044 [US2] Add a secondary `TranscriptRow` write inside `MediaLibraryRepository.importCraftedFromText` for `mode == translateThenSpeak` (source language, `referenceId` = primary transcript id, `label = l10n.transcriptTrackSource`); include in the same Drift transaction as the primary row
- [X] T045 [US2] Extend `CraftProgressDialog` stages to include `translating` between `validating` and `synthesizing` in `lib/features/craft/presentation/craft_progress_dialog.dart`
- [X] T046 [US2] Verify performance budget per QR-004 / SC-002: Translate then speak on a ~300-char sample completes in under 30 s on a normal connection (manual log + `quickstart.md` Scenario 3 evidence)

**Checkpoint**: US2 fully functional. Translate then speak lands the learner in the player with a bilingual transcript overlay; same-language affordance works; secondary transcript row exists with the correct `referenceId`.

---

## Phase 6: User Story 5 - Library badges, replay, and parity with other providers (Priority: P2)

**Goal**: Craft-generated items behave like any other audio item — sync through the existing audio sync queue, delete cleanly with no orphan files, re-open instantly with no re-synthesize.

**Independent Test**: Run `quickstart.md` Scenarios 10 (dedupe on re-import), 11 (badge + delete parity), and the "re-open" assertions in Scenarios 2/3 (re-opening does not re-synthesize).

### Tests for User Story 5

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T047 [P] [US5] Repository test for `importCraftedFromText` sync enqueue in `test/features/library/library_repository_craft_test.dart`: Craft row triggers exactly one `SyncEnqueueFn(SyncEntityType.audio, id, SyncAction.create)`; Translate then speak triggers the same single enqueue
- [X] T048 [P] [US5] Repository test for delete cleanup in `test/features/library/library_repository_craft_test.dart`: calling `deleteMedia(craftId)` removes the audio row, primary transcript, secondary transcript (Translate then speak), and the audio file in app storage; nothing is left orphaned
- [X] T049 [P] [US5] Regression test confirming re-opening a Crafted item never calls `TtsService.synthesize` (verifiable by stubbed `CraftSynthesizer` spy) in `test/features/craft/application/craft_controller_test.dart`

### Implementation for User Story 5

- [X] T050 [US5] Add a debug affordance (dev-only menu item under Settings → Diagnostics, gated behind `kDebugMode`) to list Craft items and jump to the player; mirrors existing diagnostic affordances if present. Skip if no diagnostic surface exists yet — defer.
- [X] T051 [US5] Confirm `sync_status` starts at `'pending'` for Craft rows in `MediaLibraryRepository.importCraftedFromText` (matches `importMedia` / `importYoutubeVideo` behavior); verify the existing audio sync pipeline (per ADR-0010 / ADR-0013) picks up `provider = 'craft'` rows without code changes — log a debug audit before claiming parity

**Checkpoint**: US5 fully functional. Craft items sync through the existing audio queue, delete cleanly, and re-open instantly.

---

## Phase 7: User Story 6 - Calm, honest failure and recovery (Priority: P2)

**Goal**: Every failure mode (network drop, BYOK unconfigured, credits exhausted, vendor unsupported language, save failure) surfaces a calm, localized, actionable message — never raw exception text, never a phantom transcript.

**Independent Test**: Run `quickstart.md` Scenarios 7 (TTS BYOK misconfig), 8 (TTS-stage discard), 9 (save-stage discard), 12 (sign-in gate), 13 (offline banner), 14 (length cap).

### Tests for User Story 6

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T052 [P] [US6] Extend `CraftController` tests in `test/features/craft/application/craft_controller_test.dart` for failure discard paths: translate succeeds + synthesize fails → no repository write + `failed(tts)`; translate + synthesize succeed + `repository.importCraftedFromText` throws → no orphan rows + `failed(save)`; synthesize succeeds + `FileStorage.importBytes` throws → no row + `failed(save)`; `ByokNotConfiguredFailure` from `TtsService` → `failed(tts)` with action `openAiSettings`; `OfflineException` → `failed(offline)` and Craft action disabled in the UI
- [X] T053 [P] [US6] Widget test for failure banners in `test/features/craft/presentation/craft_sheet_test.dart`: tts-stage error shows Retry + Open AI settings; translate-stage error shows Retry + Switch to Speak directly; save-stage error shows Retry; offline banner disables the Craft action; sign-in callout replaces the action when the user is signed out

### Implementation for User Story 6

- [X] T054 [P] [US6] Add failure-mapping utility (`CraftFailureMapper.from(Object error, {required CraftMode mode, required String? sourceLanguage, required String targetLanguage})`) in `lib/features/craft/application/craft_failure_mapper.dart` mapping `ApiException`, `ByokNotConfiguredFailure`, `AuthFailure`, `ConnectivityException`, `FileFailure` to the sealed `CraftFailure` hierarchy
- [X] T055 [US6] Add offline banner + sign-in callout (consumes `craftOnlineProvider` + `authCtrlProvider`) to `CraftSheet` in `lib/features/craft/presentation/craft_sheet.dart`
- [X] T056 [US6] Add length-cap truncation notice to `CraftTextInput` in `lib/features/craft/presentation/craft_text_input.dart` when `text.length > 5000`; show `l10n.craftLengthCapNotice` and proceed with the truncated text on submit
- [X] T057 [US6] Add vendor-unsupported-language detection in `CraftSynthesizer` adapter (`CraftTtsServiceSynthesizer` in `lib/features/craft/data/craft_tts_service_synthesizer.dart`) — when the TTS API returns an unsupported-language error, map to `CraftFailure.vendorUnsupportedLanguage`

**Checkpoint**: US6 fully functional. Every failure path is covered by a calm, localized, actionable message; no raw exception text reaches the user; no orphan rows / files persist after a failed Craft.

---

## Phase 8: User Story 4 - BYOK TTS provider parity for Craft (Priority: P2)

**Goal**: A learner who configures TTS BYOK (OpenAI-compatible or Azure Speech) sees Craft synthesize audio via their vendor with no Enjoy worker TTS traffic.

**Independent Test**: Run `quickstart.md` Scenarios 5 (TTS BYOK OpenAI), 6 (TTS BYOK Azure), 7 (BYOK misconfig).

### Tests for User Story 4

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T058 [P] [US4] Integration test for BYOK routing in `test/features/craft/application/craft_controller_test.dart`: with `aiModalityConfigsProvider` set to `ModalityKind.tts` BYOK (OpenAI-compatible), Craft's `CraftSynthesizer.synthesize` is called with the user's request and `TtsService` is bypassed; flip back to Enjoy AI and assert `TtsService` is invoked instead
- [X] T059 [P] [US4] Manual verification checklist for TTS BYOK on Windows + Android + iOS + macOS (Azure Speech SDK is a platform-channel hop; one smoke run per target is required because the test harness cannot exercise the platform side without a device) — captured in `quickstart.md` Scenario 15

### Implementation for User Story 4

- [X] T060 [US4] Update `lib/l10n/app_en.arb` and `lib/l10n/app_zh_CN.arb` to remove any "P3" / "limited" feel from `settingsAiProvidersModalityTtsHint`; add `craftTtsSettingsHint` ("Craft uses the TTS provider below.")
- [X] T061 [US4] Verify the existing `ModalityProviderCard` for TTS in `lib/features/ai/presentation/settings/ai_providers_screen.dart` renders all required fields (vendor dropdown, base URL, API key, model, region for Azure) and validation; no code change expected — confirm in the implementation audit
- [X] T062 [US4] Confirm `ByokNotConfiguredFailure` from `TtsService` surfaces the localized "Open AI settings" affordance in `CraftSheet` (already covered by T053 / T055 — assert via `CraftFailureMapper.from` in T054)

**Checkpoint**: US4 fully functional. TTS BYOK parity is real (not just copy): `Craft` synthesizes via the configured vendor and never touches the Enjoy worker TTS path.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, regression, and quality-gate cleanup that affects multiple user stories.

- [X] T063 [P] Create ADR `docs/decisions/0043-craft-from-text-import.md` capturing the import-flow decision: single entry with two modes (no standalone routes); TTS BYOK promotion from P3 to first-class; provider value `craft`; dedupe-by-content-hash; length-cap 5000 with truncation notice; failure-discard-at-controller-boundary. Link to spec + plan + data-model.
- [X] T064 [P] Update `docs/features/library.md`: add the third import entry; document the Craft badge; document the dedupe behavior on re-import
- [X] T065 [P] Update `docs/features/ai.md`: document that `EnjoyTtsCapability` is now wired via Azure Speech SDK + worker-issued token (parallel to assessment); document TTS BYOK as first-class; add a "Craft consumer" callout linking to `library.md`
- [X] T066 [P] Update `docs/features/transcript.md`: document the Craft primary + optional secondary transcript convention; reference `data-model.md` § TranscriptRow — Craft secondary transcript
- [X] T067 [P] Update `docs/features/settings.md`: document the TTS card prominence (no longer P3); document the `craftTtsSettingsHint` line
- [X] T068 [P] Replace the T002 placeholder with the real `lib/features/craft/README.md` summarizing the module's purpose, key files, and the spec link
- [X] T069 [P] Add the new `Craft` strings to the documentation snapshot in `docs/i18n-keys.md` (if such a file exists — skip if not)
- [X] T070 Run `bash .github/scripts/check_dart_format.sh` and apply `--fix` if needed (covers `lib`, `test`, `packages/*/lib`, `packages/*/test`)
- [X] T071 Run `dart run build_runner build --delete-conflicting-outputs` to confirm all generated files (`craft_controller.g.dart`, `craft_online_provider.g.dart`, `craft_language_history.g.dart`, plus regenerated `ai_capability_providers.g.dart`, `library_repository_provider.g.dart` if annotations changed) are committed in the same change
- [X] T072 Run `flutter analyze` and resolve every reported error or warning (warnings allowed only when explicitly documented in the plan)
- [X] T073 Run `flutter test` and ensure all unit + widget tests pass; pay special attention to the new test files (Craft controller, Craft sheet, library repository Craft, BYOK routing, Azure TTS, Azure token cache TTS purpose)
- [X] T074 Run `bash .github/scripts/validate_ci_gates.sh` (or `--all` for the full local mirror) and ensure every gate passes
- [X] T075 Walk through `specs/010-craft-from-text/quickstart.md` Scenarios 0–17 on at least one platform; capture evidence (logs, screenshots) for the README / release notes
- [X] T076 Cross-platform smoke pass: run Scenarios 2 (Speak directly) and 3 (Translate then speak) on Android, iOS, macOS, Windows in sequence; document any platform-specific deviations in the PR description

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — **BLOCKS all user stories**
- **User Stories (Phase 3–8)**: All depend on Foundational phase completion
  - US1 (Discover) must precede US3 (Speak directly) and US5 (Library) because they need the entry point and badge in place
  - US3 (Speak directly) must precede US2 (Translate then speak) only as a matter of incremental value; the controller can be built for both modes at once if desired
  - US4, US5, US6 can run in parallel after US2 completes (they touch different files)
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2). No dependencies on other stories.
- **User Story 3 (P1)**: Can start after Foundational (Phase 2) **and** US1 (the entry point). Provides the first working end-to-end MVP increment.
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) **and** US3 (shares the controller / sheet). Adds translation mode + secondary transcript.
- **User Story 5 (P2)**: Can start after Foundational (Phase 2) **and** US3 (needs at least one Craft item to exist). Extends the library surface.
- **User Story 6 (P2)**: Can start after Foundational (Phase 2) **and** US3 + US2 (failure paths cover both modes). Cross-cutting.
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) — BYOK routing is wired through existing `TtsService`. No direct dependency on other user stories, but US6's failure mapping should land first to keep the failure UX consistent.

### Within Each User Story

- Tests MUST be written and FAIL before implementation (template rule)
- Domain models before services / adapters
- Adapters before controller
- Controller before sheet
- Sheet before wiring the entry point
- Entry-point wiring before performance verification

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (T003, T004–T008, T009–T010, T011–T012, T013–T014, T015–T016 can each be split across two contributors)
- Once Foundational phase completes, US1 can run in parallel with US3 / US4 preparation
- Within US3, T027–T029 can run in parallel (different files)
- Within US3, T033–T036 can run in parallel (different widget files)
- Within US5, T047–T049 can run in parallel (different test files)
- Within US6, T054–T057 can run in parallel (different files)
- All Polish tasks marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members once dependencies are satisfied

---

## Parallel Example: User Story 3 (Speak directly) MVP increment

```bash
# Launch all tests for User Story 3 together:
Task: "T024 Unit test for CraftController Speak directly mode in test/features/craft/application/craft_controller_test.dart"
Task: "T025 Widget test for CraftSheet Speak directly mode in test/features/craft/presentation/craft_sheet_test.dart"
Task: "T026 Unit test for craftOnlineProvider in test/features/craft/application/craft_online_provider_test.dart"

# Launch all parallelizable implementations:
Task: "T027 Create CraftSynthesizer + adapter in lib/features/craft/{domain,data}/"
Task: "T028 Create craftOnlineProvider in lib/features/craft/application/craft_online_provider.dart"
Task: "T029 Create craftLanguageHistoryProvider in lib/features/craft/application/craft_language_history.dart"

# Then sequentially (depends on T027 + T028 + T029):
Task: "T030 Create CraftController in lib/features/craft/application/craft_controller.dart"

# Then parallel widget implementations:
Task: "T033 Create CraftModeSelector in lib/features/craft/presentation/craft_mode_selector.dart"
Task: "T034 Create CraftTextInput in lib/features/craft/presentation/craft_text_input.dart"
Task: "T035 Create CraftLanguageFields in lib/features/craft/presentation/craft_language_fields.dart"
Task: "T036 Create CraftProgressDialog in lib/features/craft/presentation/craft_progress_dialog.dart"

# Then sequentially:
Task: "T032 Create CraftSheet entry widget (depends on T033-T036) in lib/features/craft/presentation/craft_sheet.dart"
Task: "T037 Wire showCraftSheet from import chooser (depends on T032) in lib/features/library/presentation/library_actions.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 3 — Discover + Speak directly)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories; closes the Enjoy TTS gap, extends the repository, defines domain types)
3. Complete Phase 3: User Story 1 (Discover — adds the import chooser entry + library badge)
4. Complete Phase 4: User Story 3 (Speak directly — adds the sheet, controller, and the simplest working mode)
5. **STOP and VALIDATE**: Run `quickstart.md` Scenarios 1, 2, 10, 12, 13 on at least one platform; deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add US1 → Discoverable entry point + library badge
3. Add US3 → Speak directly end-to-end (MVP!)
4. Add US2 → Translate then speak with bilingual transcript
5. Add US5 → Library sync + delete parity
6. Add US6 → Calm failure recovery
7. Add US4 → TTS BYOK parity
8. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: US1 → US3 (MVP entry + first mode)
   - Developer B: US2 (parallel after US3 — translation mode)
   - Developer C: US5 / US6 (library parity + failure recovery)
   - Developer D: US4 (BYOK parity, mostly audit + copy)
3. Stories complete and integrate independently; the controller / sheet are shared surfaces — coordinate via PR review

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group (especially after T018 Foundational checkpoint)
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- US4's manual verification (Azure Speech SDK platform-channel hop) is the only intentional manual-verification surface per spec QR-002; all other behavior is covered by automated tests
- The new `EnjoyTtsCapability` (T013) is the single riskiest change — it touches a path that is currently a stub. Run the Azure Speech SDK smoke verification on every supported platform before claiming the PR is ready for merge