# Implementation Plan: Craft from Text (AI-generated audio materials)

**Branch**: `010-craft-from-text` | **Date**: 2026-07-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/010-craft-from-text/spec.md`

## Summary

Add a third entry — **Craft from text** — to the existing import chooser sheet that already offers "From file" and "From YouTube URL". The Craft flow folds the two use cases the user described (translate + TTS, direct TTS) into a single entry with two mode choices, so there is no standalone "Smart Translation" or "Voice Synthesis" navigation in the player. The flow chains the existing `TranslationService` (LLM-backed, BYOK-aware per spec 003) with the existing `TtsService` (Azure Speech SDK + OpenAI-compatible / Azure BYOK per spec 003) and persists the result as a normal `AudioRow` (`provider = 'craft'`) with a primary transcript in the learning language and an optional source-text secondary transcript — so echo mode and the library grid work without any new wiring. Two implementation gaps are closed in this change: (1) wire the Enjoy AI TTS path (currently `UnimplementedError`) through the Azure Speech SDK using an Enjoy-fetched short-lived token (parallel to the existing Enjoy assessment path), and (2) promote the existing TTS BYOK settings card from P3 in spec 003 to a first-class surface (the capability layer is already implemented).

## Technical Context

**Language/Version**: Dart `^3.12.0`, Flutter stable (3.x), Drift `^2.31.0`, Riverpod `^3.3.1` (annotations via `riverpod_annotation ^4.0.2`), Freezed `^3.0.0`.

**Primary Dependencies**:

- `flutter_riverpod`, `riverpod_annotation` — provider state for the Craft flow.
- `drift`, `drift_flutter`, `sqlite3_flutter_libs` — persistence for the new media + transcript rows (reuses existing `Audios`, `Transcripts` tables; no schema migration).
- `azure_speech` (path package, `packages/azure_speech`) — synthesis for both BYOK Azure TTS and (new) Enjoy TTS via worker-fetched tokens.
- `ai_sdk_dart` 1.1.0 (+ `ai_sdk_openai`, `ai_sdk_anthropic`, `ai_sdk_google`) — used by LLM BYOK for translation.
- `flutter_secure_storage` — stores TTS BYOK secrets (already wired via `ByokSecretStore`).
- `media_kit` — only as the existing audio playback path; Craft stores a regular audio file and the player handles it without engine changes.
- `go_router ^17.2.3` — no new routes; Craft is reached exclusively from the existing import chooser.
- `intl`, `flutter_localizations` — ARB-based localization for the new Craft strings.

**Storage**:

- Reuses existing Drift `AudioRow` (`Audios` table) and `Transcripts` (`Transcripts` table) — no schema migration. New media rows store `provider = 'craft'`, `source = 'craft-translate' | 'craft-direct'`, and source text in the existing `sourceText` column. New transcript rows use `source = 'ai'` with `referenceId` pointing at the source row (consistent with spec 009 auto-translate).
- Audio bytes written through the existing `FileStorage` layer (same path as `importPickedFile`), so deletion and sync reuse the existing `deleteMedia` and `SyncEnqueueFn` plumbing.
- TTS BYOK secrets reuse `ByokSecretStore` (already in production for ASR + assessment). Non-secret config reused through `AiModalityConfigs` and `ai.modality_configs_v1` settings key.

**Testing**:

- Unit tests for the Craft controller (mode toggle, same-language detection, dedupe-by-content-hash, failure discard paths) using `flutter_test` with stub translation + stub TTS capabilities.
- Repository test for `MediaLibraryRepository.importCraftedFromText(...)`: writes `AudioRow`, primary transcript, optional secondary transcript; re-import of same content hash returns the existing row id; failure paths leave the database clean.
- Widget test for the Craft sheet (`CraftFlowSheet`) covering mode switch, language pickers, paste, submit, and the offline / BYOK-misconfigured banners.
- Widget test for the library badge rendering on `provider = 'craft'`.
- `dart run build_runner build` is required because the plan introduces new `@riverpod` providers in `lib/features/craft/application/`.

**Target Platform**: Android, iOS, macOS, Windows (per constitution; no Flutter web).

**Project Type**: Flutter native mobile/desktop app (existing project layout unchanged).

**Performance Goals**:

- Translate then speak on ~300 characters (Enjoy AI default) MUST produce a playable audio item in under **30 seconds** on a normal connection; Speak directly on ~200 characters in under **20 seconds**. These match SC-002 / SC-003 in the spec.
- Synthesis runs through `azure_speech` on the platform thread; HTTP requests (Enjoy token fetch, translation) run via the existing REST client. Bytes are streamed to local storage (no copy-into-memory of large audio before write). Long inputs are processed in a single chunk in v1 (length cap = 5 000 characters; truncation notice instead of chunked synthesis).
- Re-opening a Crafted item MUST be under **1 second** (no re-translate, no re-synthesize). Storage rows are immutable once written; playback reuses the existing audio media path.

**Constraints**:

- Local-first: Craft requires network for translate + synthesize. Offline at open is handled by a banner that disables the action (FR-024).
- No new top-level routes (per spec FR-002).
- No new `media_kit` `Player()` instances; audio bytes are written to disk and played through the existing `PlayerController`.
- No `print()`; logging via `logNamed` (per AGENTS.md).
- BYOK validation rules from spec 003 apply unchanged (HTTPS base URL, required fields per vendor, masked secrets in UI).
- The new `Enjoy TTS` implementation MUST use the Azure Speech SDK with a worker-issued token (parallel to assessment), not direct OpenAI/Azure calls on the worker's behalf. This keeps the credit accounting on the Enjoy side.
- TTS-stage failure MUST discard translation artifacts to avoid phantom transcripts with no audio (FR-013).
- Save-stage failure MUST discard audio bytes (FR-014). No orphan transcripts / files.
- Provider value `craft` is a new string in `AudioRow.provider`; no migration needed because the column is a free-form text column.

**Scale/Scope**:

- Library scale unchanged from current product (audio items live alongside videos).
- Typical Craft input size: ~200–3000 characters of learning / source text (target ≤ 5 000 characters in v1).
- Synthesized audio file size: ~50–500 KB per item at typical Azure Speech MP3 bitrates (16 kHz mono ≈ 1 KB/s; 5 000 chars ≈ 3–5 minutes of speech).
- Concurrent Craft operations: not supported (single in-flight import per session, same as the existing import-blocking dialog).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- ✅ Craft lives in a new feature module `lib/features/craft/{application,data,domain,presentation}` — feature-first architecture preserved.
- ✅ Domain models stay UI-free (`CraftMode`, `CraftRequest`, `CraftResult`, `CraftJob` are plain Dart; widgets in `presentation/` consume Riverpod providers only).
- ✅ Persistence goes through Drift DAOs — `MediaLibraryRepository.importCraftedFromText(...)` writes via `AudioDao` + `TranscriptDao` (or future split; whichever already exists). No raw SQL in widgets.
- ✅ Riverpod providers in `lib/features/craft/application/` orchestrate state; no new mutable global singleton.
- ✅ No new `Player()` instances; Craft writes an audio file and the existing audio media path plays it.
- ✅ No `print()`; new code logs through `logNamed('craft.flow')` (or similar).

### II. Testing Defines the Contract

- ✅ Unit tests for Craft controller, dedupe, failure discard.
- ✅ Repository test for `importCraftedFromText` happy + failure + dedupe paths.
- ✅ Widget tests for the Craft sheet and library badge.
- ✅ Stubs replace the live `TranslationService` + `TtsService` in tests (existing pattern from spec 003 / 009).
- ✅ `dart run build_runner build` is required for the new `@riverpod` providers.
- ✅ Manual verification for the Azure Speech SDK path on Windows + Android (synthesis calls are platform-channel hops that need smoke runs); documented in `quickstart.md`.

### III. User Experience Consistency

- ✅ All Craft strings added to `app_en.arb` and `app_zh_CN.arb` (English + Chinese baseline) — see "Localization keys" in the plan.
- ✅ Reuses existing primitives: `showEnjoySheet`, `showEnjoyAlertDialog`, `EnjoyTappableSurface`, `EnjoyButton`, `AppNotice`, `showContentLanguagePicker`, the existing import-blocking-dialog pattern, the library provider badge slot.
- ✅ Icon-only actions (paste-from-clipboard, mode toggle, delete-from-sheet) expose localized tooltips.
- ✅ Keyboard affordances: Enter / Cmd-Enter submits when input is valid (same convention as `importYoutubeFromDialog`).
- ✅ Haptics route through `Haptics` (no raw vibration calls).
- ✅ `docs/features/library.md`, `docs/features/ai.md`, `docs/features/transcript.md`, `docs/features/settings.md` are updated in the same change; new ADR `docs/decisions/0043-craft-from-text-import.md` captures the import-flow decision.
- ✅ No new top-level route — UX consistency with the user's "redesign the UX" requirement.

### IV. Performance Is a Requirement

- ✅ Performance budget stated for both Craft modes (30 s / 20 s for the headline flows).
- ✅ Synthesis runs through the Azure Speech SDK platform thread; translation runs through the existing REST client (which already isolates JSON parsing via `json_isolate.dart` for large responses).
- ✅ Audio bytes are streamed to local storage (no full byte copy before write) — implementation uses `IOSink` / `RandomAccessFile.writeFrom`.
- ✅ Re-opening a Crafted item is under 1 s (no AI call).
- ✅ No expensive work in `build` methods; Craft sheet builders only read providers.
- ✅ Failure paths surface calm inline error banners (not blocking modals); the import-blocking dialog is the only full-screen affordance and is dismissible through the same `_dismissBlockingImportDialogThen` helper.

### V. Documentation and Traceability

- ✅ New ADR `docs/decisions/0043-craft-from-text-import.md` (single Craft entry, two modes, BYOK parity for TTS, provider value `craft`).
- ✅ `docs/features/library.md` updated (third import entry + Craft badge).
- ✅ `docs/features/ai.md` updated (Enjoy TTS now wired; TTS BYOK card now first-class; Craft flow described as the consumer of both).
- ✅ `docs/features/transcript.md` updated (Craft primary + secondary transcript convention).
- ✅ `docs/features/settings.md` updated (TTS card prominence; Craft calls into TTS BYOK).
- ✅ `AGENTS.md` / `README.md` unchanged (no new developer workflow rules).

## Project Structure

### Documentation (this feature)

```text
specs/010-craft-from-text/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
├── checklists/
│   └── requirements.md  # Spec quality checklist (already created by /speckit.specify)
└── spec.md              # Already created by /speckit.specify
```

### Source Code (repository root)

```text
lib/
├── features/
│   ├── craft/                       # NEW — Craft feature module
│   │   ├── application/
│   │   │   ├── craft_controller.dart         # @riverpod — orchestrator (mode, dedupe, error)
│   │   │   ├── craft_controller.g.dart       # generated
│   │   │   ├── craft_import_service.dart     # thin façade over MediaLibraryRepository.importCraftedFromText
│   │   │   └── craft_language_history.dart   # @riverpod — remembers last source-language pick
│   │   ├── data/
│   │   │   └── (none initially — reuses existing services; add adapters only if needed)
│   │   ├── domain/
│   │   │   ├── craft_mode.dart               # enum CraftMode { translateThenSpeak, speakDirectly }
│   │   │   ├── craft_request.dart            # value object (mode, text, sourceLang, targetLang)
│   │   │   ├── craft_job.dart                # in-flight state (status, stage, error, generation)
│   │   │   └── craft_failure.dart            # typed failure hierarchy
│   │   └── presentation/
│   │       ├── craft_sheet.dart              # entry point shown from import chooser
│   │       ├── craft_mode_selector.dart      # segmented button: Translate then speak / Speak directly
│   │       ├── craft_text_input.dart         # text field + paste-from-clipboard + character counter
│   │       ├── craft_language_fields.dart    # source + target language pickers (target-only for Speak directly)
│   │       └── craft_progress_dialog.dart    # import-blocking dialog (same shell as library_actions)
│   ├── library/
│   │   ├── data/
│   │   │   └── library_repository.dart       # ADD: importCraftedFromText(...)
│   │   └── presentation/
│   │       ├── library_actions.dart          # ADD: showImportChooser — third ListTile "Craft from text"
│   │       └── widgets/
│   │           └── library_badge.dart        # ADD: render "Craft" badge for provider == 'craft'
│   └── ai/
│       ├── data/
│       │   ├── azure_speech_synth_runner.dart # NEW — wraps azure_speech.synthesize with token cache
│       │   └── enjoy/
│       │       ├── enjoy_tts_capability.dart  # REPLACE UnimplementedError with Azure Speech SDK call
│       │       └── (assessment already uses similar pattern; reuse azure_token_cache)
│       └── presentation/
│           └── settings/                     # TTS card already exists; ensure no P3 flag in copy
└── core/
    └── (no new files)

test/
├── features/
│   ├── craft/
│   │   ├── application/
│   │   │   └── craft_controller_test.dart    # mode toggle, dedupe, failure discard, sign-in gate
│   │   └── presentation/
│   │       └── craft_sheet_test.dart         # widget test for the entry surface
│   └── library/
│       └── data/
│           └── library_repository_craft_test.dart  # repository happy + failure + dedupe
└── widget_test.dart                          # unchanged

docs/
├── decisions/
│   └── 0043-craft-from-text-import.md        # NEW ADR
└── features/
    ├── ai.md                                # updated: Enjoy TTS wired, TTS BYOK first-class, Craft consumer
    ├── library.md                           # updated: third import entry, Craft badge
    ├── settings.md                          # updated: TTS card prominence
    └── transcript.md                        # updated: Craft primary + secondary transcript convention

lib/l10n/
├── app_en.arb                               # ADD Craft keys
└── app_zh_CN.arb                            # ADD Craft keys
```

**Structure Decision**: New feature module `lib/features/craft/` keeps the Craft logic isolated from `library/` (which remains the read model for browsing / searching media) and from `ai/` (which remains the capability layer). Cross-feature calls go through documented contracts: Craft → Library (`MediaLibraryRepository.importCraftedFromText`) and Craft → AI (`TranslationService` + `TtsService` + `azure_token_cache`). No shortcuts.

## Complexity Tracking

> No constitution violations. Complexity is contained within the feature module.

| Concern | Approach |
|---------|----------|
| New feature module `lib/features/craft/` | Required for feature-first architecture; isolated from `library/` and `ai/` per spec FR-001 and Constitution I. |
| Wire `EnjoyTtsCapability` (currently throws `UnimplementedError`) | Required by spec FR-009 (reuse TtsService) and FR-016 (per-modality routing). Implementation reuses `AzureSpeech.instance.synthesize` plus the existing `AzureTokenCache` with a new `purpose: 'tts'` token variant. |
| Promote TTS BYOK card from spec 003 P3 to first-class | Required by FR-010. The capability layer is already implemented; only the settings card copy and `quickstart.md` need to reflect first-class status. |
| Stream synthesized audio to local storage | Required by QR-005. Uses `IOSink` / `RandomAccessFile.writeFrom` to avoid copying the full byte buffer before write. |

## Localization keys (added to `lib/l10n/app_en.arb` and `app_zh_CN.arb`)

```text
importCraftFromText        — "Craft from text" / "从文本自制"
craftSheetTitle            — "Craft audio from text" / "从文本合成音频"
craftModeTranslateThenSpeak — "Translate then speak" / "先翻译再朗读"
craftModeSpeakDirectly     — "Speak directly" / "直接朗读"
craftSourceLanguageLabel   — "Source language" / "原文语言"
craftTargetLanguageLabel   — "Learning language" / "学习语言"
craftTextInputHint         — "Paste or type text…" / "粘贴或输入文本…"
craftPasteFromClipboard    — "Paste from clipboard" / "从剪贴板粘贴"
craftAction                — "Craft" / "合成"
craftCraftingProgress      — "Crafting your audio…" / "正在合成音频…"
craftEmptyTextHint         — "Enter at least a sentence to craft." / "请至少输入一句话以开始合成。"
craftSameLanguageHint      — "Looks like this is already in your learning language. Switch to Speak directly?" / "这段文字已经是学习语言了。切换到直接朗读？"
craftSameLanguageSwitch    — "Speak directly" / "直接朗读"
craftOfflineBanner         — "You're offline. Craft needs an internet connection." / "当前离线，合成需要联网。"
craftSignInRequired        — "Sign in to use Craft" / "请登录后使用合成"
craftFailureTts            — "We couldn't turn the text into audio. Check your TTS provider settings or try again." / "无法将文本转为语音。请检查 TTS 提供商设置或重试。"
craftFailureTranslate      — "We couldn't translate the text. Try again or switch to Speak directly." / "无法翻译文本。请重试或切换到直接朗读。"
craftFailureSave           — "The audio was generated but couldn't be saved. Free up space and try again." / "音频已生成但保存失败。请释放空间后重试。"
craftAlreadyInLibrary      — "Already in your library" / "已在你的资料库中"
craftOpenExisting          — "Open" / "打开"
craftRetry                 — "Retry" / "重试"
craftOpenAiSettings        — "Open AI settings" / "打开 AI 设置"
libraryProviderCraftBadge  — "Craft" / "自制"
craftTtsSettingsHint       — "Craft uses the TTS provider below." / "合成使用下方的 TTS 提供商。"
```

## Implementation Notes

1. **Enjoy TTS path** — Implement `EnjoyTtsCapability.synthesize` by:
   - Asking `AzureTokenCache.getToken(durationSeconds: estimatedDurationSec, usagePurpose: 'tts')` (extend the cache `usage` payload).
   - Calling `AzureSpeech.instance.synthesize(AzureSpeechSynthesisParams(text, language, subscriptionKey, region, voice))`.
   - Returning `TtsResult(audioBytes, format)`.
   The Azure token cache needs a small extension to support `purpose: 'tts'`; spec 002 / ADR-0017 already established the pattern for assessment tokens.

2. **`MediaLibraryRepository.importCraftedFromText(...)`** signature:

   ```text
   Future<String> importCraftedFromText({
     required String text,
     required String learningLanguage,
     String? sourceLanguage,
     required CraftMode mode,
     required Uint8List audioBytes,
     required String audioFormat,
     required String audioDurationMs,
     required String signedInUserId,
   })
   ```

   - Computes content hash from SHA-256 of `learningLanguage + mode + canonicalized text` (so re-importing the same text returns the existing row id).
   - Writes audio bytes via `FileStorage.importBytes(audioBytes, extension: 'mp3')` → `result.fileUri`.
   - Inserts `AudioRow` with `provider: 'craft'`, `source: mode == translateThenSpeak ? 'craft-translate' : 'craft-direct'`, `localUri: fileUri`, `sourceText: text`, `language: learningLanguage`, `translationKey: sourceLanguage ?? learningLanguage`, `voice: voiceId ?? null`.
   - Inserts primary transcript (`source = 'ai'`, `referenceId = sourceLanguage for translate mode or null for direct mode`, `label = "Learning language"` or localized equivalent).
   - For Translate then speak: also inserts a secondary transcript with `source = 'ai'`, `referenceId = primary.id`, `label = "Source"`.
   - Enqueues sync via existing `SyncEnqueueFn(SyncEntityType.audio, id, SyncAction.create)`.
   - Returns the media id.

3. **Craft controller (`CraftController`)** is a `Notifier<CraftJobState>` with:
   - `selectMode(CraftMode)` — flips the mode, preserves text.
   - `setText(String)`, `setSourceLanguage(String?)`, `setTargetLanguage(String)` — field setters with same-language detection (`text.length > 50 && sourceLanguage == targetLanguage` → suggest switch to Speak directly).
   - `submit()` — single async call that runs translate (if needed) → synthesize → repository import, surfacing typed `CraftFailure` values.
   - `reset()` — clears state on success or error.
   The controller holds the in-flight generation counter so a second `submit()` mid-flight is a no-op (single concurrent job per session).

4. **Same-language affordance** is purely UI-side: the controller compares `sourceLanguage == targetLanguage` after `setText` + `setSourceLanguage` and emits a one-tap suggestion to switch to Speak directly; the actual switch is a `selectMode` call. No AI call is made in Translate then speak mode when source == target.

5. **Dedupe** uses the same `Md5(UTF-8(...))` pattern as `importPickedFile` so the audio row's `md5` field stays meaningful for sync. The `library_repository.importCraftedFromText` returns the existing row id on collision (same as `importYoutubeVideo`).

6. **Failure discard paths**:
   - Translate succeeds, TTS fails → throw `CraftFailure.tts(...)` from the controller before any repository write happens.
   - Translate + TTS succeed, save fails → `FileStorage.importBytes` failure throws; the repository does not insert any rows. No retry is implicit (the user re-submits, regenerating audio).
   - BYOK misconfigured → `TtsService.synthesize` throws `ByokNotConfiguredFailure`; controller maps it to `CraftFailure.tts(...)` with a localized "open AI settings" affordance.

7. **Offline banner** uses `connectivity_plus` (already a transitive dep) — add a small provider `craftOnlineProvider` in `application/`.

8. **Library badge** — the existing `MediaCardTile` already accepts a `providerBadge` string. The library grid provider checks `media.provider == 'craft'` and passes `libraryProviderCraftBadge`. The Home grid does the same.

## Out of scope for this plan (called out for the implementer)

- Voice selection UI per Craft call (deferred; provider-level voice defaults only).
- Chunked synthesis for very long inputs (truncation notice instead).
- Standalone "Smart Translation" / "Voice Synthesis" routes (folded into Craft).
- Local / on-device TTS.
- Cloud sync of TTS BYOK secrets.
- Background music, video compositing.
- Sharing / exporting Crafted audio or transcripts beyond existing media-row capabilities.
- Cross-device handoff of Craft-in-progress jobs (single-session only).