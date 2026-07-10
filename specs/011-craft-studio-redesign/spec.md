# Feature Specification: Craft Studio (Redesigned)

**Feature Branch**: `011-craft-studio-redesign`

**Created**: 2026-07-10

**Status**: Draft

**Supersedes**: [010-craft-from-text](../010-craft-from-text/spec.md) (bottom sheet approach)

**Input**: User description: "You put everything in a bottom sheet, that's not what I want. We should design a separate screen for it. The entry still lives on the import option. The craft have two main tools: translation and synthesis. We should redesign the UI for both of them. As translation, the source language need to include user's native language. We need to provide different styles (prompts) as presets, to use LLM to translate. After translate, user could edit it, copy it, re-translate it. As synthesis, we should be able to choose language and voice etc. For v1, we support Azure TTS only, both from Enjoy AI and BYOK. The final artifacts of craft is an audio with its transcription (with timestamp), ready for shadow reading practice."

## Scope

### In scope

- **A dedicated Craft screen** (not a bottom sheet) reached from the existing import chooser's "Craft from text" entry as a pushed GoRouter route at `/craft`. The screen provides room for the two tools and the final synthesis + save step.
- **Translation tool**: a source-text input, source-language picker (MUST include the learner's native language alongside the content language catalog), target-language picker, a **translation style preset** selector (literal, natural, casual, formal, simplified, detailed, custom prompt), translate / re-translate / copy / **edit the result inline** before sending it to synthesis. Translation is implemented via the **LLM Chat API** (`/chat/completions`, the existing `ChatService`) with style-specific system prompts — NOT the `/translations` worker endpoint.
- **Synthesis tool**: a text input (pre-filled from the translation result when the learner taps "Use translated text"), target-language picker, **voice picker** (Azure Neural voices filtered by language, gender, and locale), synthesize / re-synthesize, audio preview player. Synthesis uses **Azure Speech SDK** with **real word-boundary events** captured during synthesis (not estimated timestamps).
- **Final artifact**: saving the synthesized audio + a **word-segmented transcript** (each segment has real start/duration from Azure word-boundary events) to the library as a `provider = 'craft'` audio media item, ready for echo / shadow-reading mode.
- **V1 TTS**: Azure Speech only for the **voice picker**. The voice picker lists Azure Neural voices (Jenny, Guy, Aria, Davis, Sonia, Ryan, Xiaoxiao, Yunxi, Xiaoyi, Yunjian, Nanami, Keita, Aoi, Sun-Hi, In-Joon, Elvira, Álvaro, Dalia, Jorge, Denise, Henri, Katja, Conrad, Elsa, Diego, Francisca, Antonio, Svetlana, Dmitry) filtered by language. **Both Enjoy AI (worker-issued token) and BYOK Azure (user subscription key + region) are supported.** OpenAI-compatible TTS BYOK remains configurable in AI settings → TTS card but is NOT surfaced in the Craft voice picker for v1 — Craft's synthesis uses the active TTS modality (Enjoy AI by default, or BYOK Azure/Azure Speech if configured).
- Reuse the spec 010 infrastructure, **extended** for v1:
  - `EnjoyTtsCapability` — wired via Azure Speech SDK + worker-issued auth token (the worker returns a JWT, not a subscription key; the Azure plugin now supports both auth modes)
  - `FileStorage.importBytes` — for synthesized audio persistence
  - `AzureTokenCache` with `purpose: 'tts'` — for worker token attribution
  - `MediaLibraryRepository.importCraftedFromText` — persists audio + timestamped transcript
  - **Azure Speech plugin extension**: `AzureSpeechSynthesisParams` supports both `token` and `subscriptionKey`; `AzureSpeechSynthesisOutcome` returns `wordBoundaries: List<AzureWordBoundary>` (text + audioOffsetMs + durationMs) captured from the native plugin's `wordBoundary` events.

### Out of scope

- **Local / on-device AI** for translation or TTS.
- **OpenAI-compatible TTS voice picker** in the Craft UI for v1 (BYOK OpenAI TTS still works via the AI settings → TTS card if configured, but the Craft voice picker only lists Azure Neural voices).
- **Background music, video compositing** — audio only.
- **Cloud sync of BYOK secrets**.
- **Sharing or exporting** Craft-generated audio / transcripts beyond existing media-row capabilities.
- **Translation history** as a separate tab (translations are stored in the DB via the existing `translations` table pattern, but a dedicated history list UI is deferred).
- **TTS history** as a separate tab (Craft results show in the library grid like any audio item).
- **Chunked synthesis** for very long inputs (v1 truncates at 5 000 characters with a clear notice).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open the Craft screen from the import chooser (Priority: P1)

A learner taps Import → Craft from text and a **full screen** opens (not a bottom sheet). The screen has two clearly labeled tools — **Translate** and **Synthesize** — reachable as tabs or stacked sections. The learner immediately sees where to paste text, how to pick languages, and what style or voice to use.

**Why this priority**: The screen is the foundation for both tools; without a usable full-screen layout, neither translation nor synthesis can work well.

**Independent Test**: Tap Import → Craft from text on each platform; confirm a full screen opens (pushed route, not a modal sheet) with two tool areas visible and labeled.

**Acceptance Scenarios**:

1. **Given** the import chooser, **When** the learner taps "Craft from text", **Then** the chooser closes and a new full-screen route opens (back button returns to the previous screen).
2. **Given** the Craft screen is open, **When** the learner looks at the layout, **Then** both **Translate** and **Synthesize** areas are visible without scrolling on desktop; on mobile, they are reachable by scrolling or tab switching.
3. **Given** the Craft screen is open, **When** the learner presses the hardware / toolbar back button, **Then** the screen closes and returns to the previous screen (Home or Library).
4. **Given** the learner's profile, **When** the Craft screen initializes, **Then** the source language defaults to the profile native language and the target language defaults to the profile learning language.

---

### User Story 2 - Translate with style presets and edit the result (Priority: P1)

A learner pastes a paragraph in their native language, picks a **translation style** (e.g. "natural", "literal", "simplified"), taps Translate, and gets the translated learning-language text. They can **edit** the translation inline (fix a word, adjust phrasing), **copy** it to the clipboard, or **re-translate** with a different style. When satisfied, they tap **Use translated text** to send it to the Synthesize area.

**Why this priority**: Translation is the first half of the headline flow. Without style presets and post-translation editing, the feature is just a plain MT call — not differentiated.

**Independent Test**: Paste text, select a style, translate, edit the result, copy it, re-translate with a different style, then tap "Use translated text" and confirm the Synthesize text input is pre-filled.

**Acceptance Scenarios**:

1. **Given** the Translate area is open, **When** the learner opens the source-language picker, **Then** the list includes the learner's **native language** alongside the standard content language catalog (en, zh, ja, ko, es, fr, de, etc.).
2. **Given** the Translate area, **When** the learner selects a style preset (literal / natural / casual / formal / simplified / detailed / custom), **Then** the style is applied on the next translate call; selecting "custom" reveals a prompt input.
3. **Given** text is entered and a style is selected, **When** the learner taps Translate, **Then** the translated text appears in an editable result area within a reasonable wait.
4. **Given** the translated result, **When** the learner taps into the result field, **Then** they can edit the text inline (fix words, adjust phrasing); the edited text is what gets passed to synthesis.
5. **Given** the translated result, **When** the learner taps Copy, **Then** the translated text is on the clipboard and a brief confirmation is shown.
6. **Given** a completed or edited translation, **When** the learner changes the style and taps Re-translate, **Then** a fresh translation replaces the current result; the previous result is not retained in the UI.
7. **Given** a completed or edited translation, **When** the learner taps "Use translated text", **Then** the Synthesize area's text input is pre-filled with the (edited) translation and the screen scrolls / switches focus to the Synthesize area.
8. **Given** the learner's source language equals the target language, **When** the learner taps Translate, **Then** the flow does not call the translation API; instead a calm hint suggests switching source or target.

---

### User Story 3 - Synthesize with voice selection and preview (Priority: P1)

A learner who has text (either from the Translate area or pasted directly into the Synthesize area) picks a **voice** from the Azure Neural voice catalog (filtered by the selected language), taps Synthesize, hears a **preview** of the audio, and can re-synthesize with a different voice. When satisfied, they tap **Save to library**.

**Why this priority**: Synthesis is the second half — without voice selection and audio preview, the learner cannot judge quality before committing.

**Independent Test**: Enter text in the Synthesize area, pick a voice from the voice picker (filtered by language), tap Synthesize, hear the preview, pick a different voice, re-synthesize, then tap Save.

**Acceptance Scenarios**:

1. **Given** the Synthesize area, **When** the learner opens the voice picker, **Then** they see Azure Neural voices filtered by the selected target language (e.g., for en: Jenny, Guy, Aria, Davis, Sonia, Ryan; for zh: Xiaoxiao, Yunxi, Xiaoyi, Yunjian; for ja: Nanami, Keita, Aoi).
2. **Given** text is entered and a voice is selected, **When** the learner taps Synthesize, **Then** audio is produced and a preview player appears inline.
3. **Given** a preview is playing, **When** the learner taps play / pause / seek on the inline player, **Then** the audio responds; no separate screen is needed for preview.
4. **Given** a preview exists, **When** the learner changes the voice or language and taps Re-synthesize, **Then** a new audio preview replaces the old one.
5. **Given** the learner is signed out, **When** they tap Synthesize, **Then** they are sent through the existing sign-in affordance.

---

### User Story 4 - Save to library with timestamped transcript (Priority: P1)

After previewing, the learner taps **Save to library**. The audio + a **word-segmented timestamped transcript** (built from real Azure `wordBoundary` events during synthesis) are saved as a `provider = 'craft'` audio media item. The learner is taken to the player where echo / shadow-reading mode works immediately against the timestamped transcript.

**Why this priority**: This is the final payoff — without saving with a timestamped transcript, the artifact is not usable for shadow reading.

**Independent Test**: Synthesize audio, tap Save, confirm the player opens with a word-segmented transcript (each segment with real start/duration from Azure) and echo mode works.

**Acceptance Scenarios**:

1. **Given** a synthesized audio preview exists, **When** the learner taps Save to library, **Then** the audio file + transcript rows are written and the player opens with the new audio item.
2. **Given** the saved item, **When** the learner views the transcript, **Then** it is **word-segmented with real Azure word-boundary timing** (not estimated) — each segment has `startMs` and `durationMs` derived from the `wordBoundary` events fired during synthesis. Segment size is ~6 words with sentence-end punctuation as break points.
3. **Given** the saved item in the player, **When** the learner starts echo / shadow-reading mode, **Then** it works immediately against the timestamped transcript — no extra setup.
4. **Given** a Craft item (Translate then synthesize or direct synthesis), **When** the item is saved, **Then** only the learning-language transcript exists. **No secondary source-language transcript is written** — the source text is preserved on the audio row's `sourceText` column for reference but never as a separate transcript row.
5. **Given** the learner saves the same content twice (same text, same voice, same language), **Then** the second save surfaces "Already in your library" with an **Open** action — no duplicate.

---

### User Story 5 - Craft badge and library parity (Priority: P2)

Craft-generated items show a **Craft** badge in the library grid and behave like any other audio item: play, edit language, delete, sync. Reopening is instant with no re-synthesis.

**Why this priority**: Discoverability and trust — learners need to distinguish Craft items from other audio at a glance.

**Independent Test**: Save a Craft item, open Library, confirm the badge renders, tap to play, delete, confirm cleanup.

**Acceptance Scenarios**:

1. **Given** a Craft-generated audio item, **When** it appears in the library grid, **Then** it shows a Craft provider badge (same position as YouTube badge).
2. **Given** a Craft-generated audio item, **When** the learner reopens it, **Then** the player opens instantly with audio + transcript already present (no AI calls).
3. **Given** a Craft-generated audio item, **When** the learner deletes it, **Then** the audio file and transcripts are removed; no orphan files remain.

---

### User Story 6 - Calm failure and recovery (Priority: P2)

Translation failures, synthesis failures, and save failures each surface a calm, localized message naming the stage that failed and offering Retry / Re-translate / Open AI settings. No raw exception text reaches the user. No phantom transcript or audio file is left behind.

**Why this priority**: Trust — Craft is the first AI authoring surface in the player; broken failure UX poisons the feature.

**Independent Test**: Force translation failure, TTS failure (misconfigured BYOK), and save failure; confirm each surfaces the right action without orphans.

**Acceptance Scenarios**:

1. **Given** a translation call fails, **When** the error surfaces, **Then** the Translate area shows a calm message with Retry and a suggestion to try a different style.
2. **Given** a synthesis call fails (TTS BYOK misconfigured, credits exhausted, network drop), **When** the error surfaces, **Then** the Synthesize area shows a calm message with Retry and, when BYOK is the cause, an "Open AI settings" action.
3. **Given** synthesis succeeds but the save step fails, **When** the error surfaces, **Then** a save-stage message appears with Retry; no orphan audio file or transcript is left in storage.
4. **Given** the learner is offline, **When** they try to translate or synthesize, **Then** a calm network error appears; the Craft screen stays usable for editing text and adjusting settings.

### Edge Cases

- Empty or very short text (< 10 chars): Translate / Synthesize action disabled with inline hint.
- Text > 5 000 characters: truncation notice shown; only the first 5 000 characters are sent to TTS.
- Language not supported by Azure TTS: voice picker shows "no voices for this language" and the synthesize action is disabled with guidance.
- Same source and target language in Translate: translate action shows a hint suggesting the learner pick a different source or use Synthesize directly.
- Rapid re-translate / re-synthesize: the latest request wins; stale results are discarded (generation counter).
- User signs out mid-Craft: in-flight work fails with the sign-in callout; no half-imported rows.
- User navigates back before saving: unsynthesized text is lost (no draft persistence in v1).
- Platform input: paste-from-clipboard works on all four targets; the Craft screen respects the responsive layout (side-by-side on desktop, stacked / tabbed on mobile).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The import chooser's "Craft from text" entry MUST open a **full-screen route** (not a bottom sheet or modal dialog).
- **FR-002**: The Craft screen MUST expose two tools: **Translate** and **Synthesize**. Both are visible by default; the learner is not forced through a linear wizard.
- **FR-003**: The Translate tool MUST include a source-language picker that lists the learner's **profile native language** alongside the content language catalog. Source defaults to native language; target defaults to learning language.
- **FR-004**: The Translate tool MUST include a **translation style preset** selector with at least: literal, natural, casual, formal, simplified, detailed, and custom (custom reveals a free-form prompt input).
- **FR-005**: The Translate tool MUST allow the learner to **edit the translated result inline** before passing it to synthesis.
- **FR-006**: The Translate tool MUST provide **Copy** (to clipboard) and **Re-translate** (with the currently selected style or a different one) actions on the result.
- **FR-007**: The Translate tool MUST include a **"Use translated text"** action that pre-fills the Synthesize tool's text input with the (possibly edited) translation and shifts focus to it.
- **FR-008**: The Synthesize tool MUST include a **voice picker** listing Azure Neural voices filtered by the selected target language. The list MUST show voice name, gender, and locale.
- **FR-009**: The Synthesize tool MUST include a language picker and a text input (pre-filled from Translate when the learner taps "Use translated text"; otherwise manual entry).
- **FR-010**: The Synthesize tool MUST produce an **audio preview** that the learner can play / pause inline before saving.
- **FR-011**: The Synthesize tool MUST allow **re-synthesizing** with a different voice or language; the previous preview is replaced.
- **FR-012**: The Synthesize tool MUST include a **Save to library** action that persists the audio + a timestamped transcript and opens the player.
- **FR-013**: The timestamped transcript MUST be **word-segmented with real Azure word-boundary data**: each segment groups ~6 words (with sentence-end punctuation as additional break points) and has its `startMs` and `durationMs` from the first/last word's Azure `wordBoundary` event. If Azure does not fire `wordBoundary` events (older SDK or unsupported voice), fall back to sentence-split estimation from WAV duration + character count.
- **FR-014**: For both Translate then synthesize and direct synthesis saves, only the **learning-language transcript** is saved. **No secondary source-language transcript is written.** A secondary transcript with fabricated timestamps (single line, 0 duration) would be misleading; the source text is preserved on the audio row's `sourceText` column for reference, but no separate transcript row is created.
- **FR-015**: Craft MUST dedupe by content hash `SHA-256(sourceFlag + learningLanguage + normalizedText + voice)`. Re-saving the same content returns the existing media id without making AI calls.
- **FR-016**: The Craft voice picker MUST list **Azure Neural voices only**, filtered by the selected target language's base code. Both Enjoy AI (worker-issued auth token via `AzureTokenCache`) and BYOK Azure (user subscription key + region) are supported as auth modes — the active TTS modality determines which mode is used. BYOK OpenAI-compatible TTS configured in AI settings is NOT surfaced in the voice picker; Craft synthesis uses the active TTS modality (Azure by default, OpenAI TTS only if explicitly configured).
- **FR-017**: Translation MUST use the **LLM Chat API** (`/chat/completions` via `ChatService`), NOT the `/translations` worker endpoint. Each style preset maps to a system-prompt suffix (literal, natural, casual, formal, simplified, detailed, custom) appended to the base translation instruction. The custom style lets the learner supply a free-form prompt that replaces the style suffix entirely.
- **FR-018**: All user-facing copy (screen title, tool labels, style names, voice names, action buttons, errors, hints) MUST be localized via ARB files (English + Chinese baseline).
- **FR-019**: All failure copy MUST be calm and actionable (Retry / Re-translate / Open AI settings / Sign in). Raw exception text MUST NOT be the primary message.
- **FR-020**: Empty, whitespace-only, or trivially short input MUST disable the corresponding action (Translate or Synthesize) with an inline hint.
- **FR-021**: Deleting a Craft-generated item MUST remove the audio file and all associated transcripts via the existing `deleteMedia` path.
- **FR-022**: The Craft screen MUST be reachable via the GoRouter route `/craft` (added to `app_router.dart`). The import chooser's "Craft from text" tile pushes this route instead of opening a modal sheet.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture; the Craft screen lives in `lib/features/craft/presentation/` and routes through Riverpod providers.
- **QR-002**: Every behavior change MUST ship with automated tests or a documented manual-verification reason.
- **QR-003**: User-facing controls MUST reuse shared primitives (`EnjoyButton`, `EnjoyTappableSurface`, `showContentLanguagePicker`, existing `MediaCardTile` badge slot) and follow localization / haptics / tooltip conventions.
- **QR-004**: The Craft screen MUST remain responsive while translation or synthesis runs. UI work MUST stay off the main isolate for heavy operations (file write, audio decode for duration).
- **QR-005**: Translated results and synthesized audio previews MUST be cached in-memory during the session so re-translate / re-synthesize does not lose the previous result until explicitly replaced.
- **QR-006**: Feature behavior changes MUST update `docs/features/` and the ADR (ADR-0030 is revised to document the full-screen + two-tool + voice-picker + style-preset decision).

### Key Entities

- **Translation style**: A named preset (literal, natural, casual, formal, simplified, detailed, custom) that maps to an LLM prompt template influencing translation tone and approach.
- **Craft translation**: The in-session result of a translate call — source text, source language, target language, style, translated text, and edit state. Not persisted as a standalone record in v1 (the edited text is what flows to synthesis).
- **Craft synthesis**: The in-session result of a synthesize call — text, language, voice id, audio bytes, and estimated duration.
- **Craft media item**: The persisted artifact (AudioRow, provider `craft`) with a word-segmented timestamped primary transcript (built from Azure word-boundary events). No secondary transcript. The source text is preserved on the audio row's `sourceText` column for reference but never as a separate transcript row.
- **Azure voice**: A named Azure Neural voice (e.g., `en-US-JennyNeural`) with a language, gender, and locale. The Craft voice picker lists voices filtered by the selected target language.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: At least **90%** of participants find and open the Craft screen from the import chooser within **15 seconds** on first try.
- **SC-002**: Translate with a style preset on a ~200-character sample completes within **15 seconds** on a normal connection (Enjoy AI default); the result appears in an editable field.
- **SC-003**: Synthesize with a selected voice on a ~200-character sample completes within **20 seconds** on a normal connection (Enjoy AI default); the preview player appears.
- **SC-004**: Save to library produces a word-segmented transcript where **≥ 99%** of segment boundaries fall within **±200ms** of the actual Azure word boundary (timestamps come directly from Azure's `wordBoundary` events — no estimation drift).
- **SC-005**: Reopening a saved Craft item shows audio + transcript in under **1 second** with no AI calls.
- **SC-006**: Craft items show the Craft badge in **100%** of regression checks.
- **SC-007**: **100%** of failure states surface a localized, actionable message — no raw exception text.
- **SC-008**: Same-content dedupe: saving the same text + voice + language twice does not create a duplicate in **100%** of regression checks.
- **SC-009**: The voice picker lists at least **2 voices** (male + female) for each supported learning language (en, zh, ja, ko, es, fr, de).
- **SC-010**: The source-language picker includes the learner's profile native language in **100%** of cases.

## Assumptions

- The Craft screen is a single full-screen route reached from the import chooser at the GoRouter path `/craft`. It is NOT a bottom sheet (user explicitly rejected the bottom sheet approach from spec 010).
- The two tools (Translate and Synthesize) are visible on the same screen, side-by-side on desktop (≥900px wide) and stacked on mobile. A "Use translated text" button bridges them.
- Translation style presets map to LLM **system-prompt suffixes** appended to the base translation instruction. The implementation uses `ChatService` (`/chat/completions`), NOT `TranslationService` (`/translations`). For BYOK LLM, the same system+user message pair is sent to the configured provider. For `custom`, the learner's free-form prompt replaces the style suffix entirely.
- The source-language picker reuses `showContentLanguagePicker` but is extended to include the learner's native language (read from `appPreferencesProvider`). The content language catalog (`kSupportedFocusLanguageTags` + native tag) is the source list.
- Azure Neural voices are cataloged as a static list in `lib/features/craft/domain/azure_voice.dart` (ported from the web app's `azure-voices.ts`). The list is filtered by the selected target language's base code at runtime.
- Timestamped transcripts use **real Azure word-boundary events** captured by the native plugin during synthesis (Android Kotlin, iOS Swift, macOS Swift, Windows C++ all subscribe to `wordBoundary`). If boundaries are unavailable (older SDK or unsupported voice), fall back to sentence-split estimation from WAV duration + character count. Word-level timestamps are a future enhancement if boundary events are not granular enough.
- **V1 voice picker is Azure Neural voices only.** OpenAI-compatible TTS BYOK remains configurable in AI settings → TTS card; if configured, Craft synthesis uses it (via `TtsService` capability resolution). The picker just doesn't list OpenAI voices.
- **No secondary transcript is written.** The source text is preserved on the audio row's `sourceText` column for reference, but a separate transcript row for the source language was dropped because without word-level alignment between source and synthesized target, the timestamps would be fabricated (single line, 0 duration) — worse than no transcript.
- Title for the new audio item is auto-generated from the first ~40 characters of the primary transcript text (the learning-language text), with an ellipsis if truncated.
- Echo / shadow-reading mode works out of the box because Craft creates a real audio media item with a real timestamped transcript.
- Text > 5 000 characters is truncated with a clear notice (no chunked synthesis in v1).
- Dedupe hash includes voice so the same text with different voices produces different items.
- The existing infrastructure from spec 010 is reused and **extended**: `AzureSpeechSynthesisParams` now supports `token` (for Enjoy AI's worker-issued JWT) in addition to `subscriptionKey` (for BYOK Azure); `AzureSpeechSynthesisOutcome` returns `wordBoundaries` alongside audio bytes; `CraftController` uses `ChatService` instead of `TranslationService` for style-driven translation.

## Dependencies

- Spec 010 infrastructure (extended for v1): `EnjoyTtsCapability` (Azure Speech SDK + worker token — token support added to `AzureSpeechSynthesisParams`), `FileStorage.importBytes`, `AzureTokenCache` (purpose: 'tts'), `MediaLibraryRepository.importCraftedFromText` + `findExistingCrafted`.
- `AzureSpeechSynthesisOutcome.wordBoundaries` — real word-level timing from Azure's `wordBoundary` events (captured on Android Kotlin, iOS Swift, macOS Swift, Windows C++).
- `ChatService` (LLM `/chat/completions`) — used for translation with style-specific system prompts. NOT `TranslationService` (`/translations`).
- Existing AI settings screen (TTS card, LLM card) — unchanged.
- Existing import chooser entry (modified to push the `/craft` route instead of opening a sheet).
- Existing ARB localization infrastructure.
- Azure Neural voice catalog (`lib/features/craft/domain/azure_voice.dart`, ported from `~/dev/enjoy/packages/ai/src/utils/azure/azure-voices.ts`).
- `connectivity_plus` is NOT used (per spec 010's reactive offline handling; the offline failure mapper produces a calm error instead of a proactive banner).

## Reference (Enjoy monorepo)

| Area | Enjoy reference | Player approach |
|------|-----------------|-----------------|
| Smart translation route | `apps/web/src/routes/smart-translation.tsx` | Adapted as the Translate tool on the Craft screen (not a separate route) |
| Translation styles | `apps/web/src/types/db/common.ts` (TranslationStyle type), `apps/web/src/components/smart-translation/translation-style-selector.tsx` | Ported as a style selector dropdown with the same 7 presets |
| Translation result | `apps/web/src/components/smart-translation/translation-result.tsx` | Adapted as an editable result field + Copy + Re-translate + "Use translated text" |
| Voice synthesis route | `apps/web/src/routes/voice-synthesis.tsx` | Adapted as the Synthesize tool on the Craft screen (not a separate route) |
| Voice selector | `apps/web/src/components/voice-synthesis/voice-selector.tsx`, `packages/ai/src/utils/azure/azure-voices.ts` | Ported as an Azure Neural voice picker filtered by language |
| Voice synthesis sheet (bridge) | `apps/web/src/components/smart-translation/voice-synthesis-sheet.tsx` | Replaced by "Use translated text" button on the same screen |
| TTS word-boundary transcript | `packages/ai/src/utils/azure/azure-tts-core.ts` (subscribes to `synthesizer.wordBoundary`) + `packages/ai/src/utils/transcript-segmentation/index.ts` (`convertToTranscriptFormat`) | Native plugin captures `wordBoundary` events; Dart-side `word_boundary_segmenter.dart` groups words into ~6-word segments with sentence-end break points (simplified port, no Compromise.js dependency) |
