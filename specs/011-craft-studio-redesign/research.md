# Research: Craft Studio (Redesigned)

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

## Decisions

### D1. Full-screen route via GoRouter instead of bottom sheet

- **Decision**: Add a `/craft` route to `app_router.dart`; the import chooser's `onTap` calls `context.push('/craft')` instead of `showEnjoySheet`.
- **Rationale**: The user explicitly rejected the bottom sheet approach. A pushed route gives the screen full height for the two-tool layout, proper back-button semantics, and responsive space (side-by-side on desktop, stacked on mobile).
- **Alternatives**: `showEnjoyDialog` full-screen dialog — rejected (less idiomatic than a GoRouter push).

### D2. Translation style presets map to prompt suffixes

- **Decision**: Port the 7 styles from the web app (`literal`, `natural`, `casual`, `formal`, `simplified`, `detailed`, `custom`). Each style (except `custom`) maps to a short instruction suffix appended to the base translation prompt. `custom` exposes a free-form prompt input.
- **Prompt mapping** (ported from web app `packages/ai/src/services/smart-translation-service.ts`):
  - `literal`: "Translate the text as literally as possible, preserving the original sentence structure."
  - `natural`: "Translate the text naturally, as a fluent speaker would say it."
  - `casual`: "Translate the text in a casual, conversational tone."
  - `formal`: "Translate the text in a formal, professional register."
  - `simplified`: "Translate using simple vocabulary and short sentences suitable for beginners."
  - `detailed`: "Translate with additional context and nuance, explaining idioms if needed."
  - `custom`: the learner's free-form prompt replaces the style instruction entirely.
- **Rationale**: The existing `ChatService.complete` (LLM `/chat/completions`) sends system + user messages to the Enjoy worker or BYOK LLM. Adding a style suffix to the system prompt is the simplest way to implement presets without changing the service contract. For BYOK LLM, the system prompt is sent to the configured provider. `TranslationService` (`/translations`) is NOT used — it doesn't accept custom system prompts and doesn't support style-driven translation.
- **Alternatives**: Separate endpoint per style — rejected (over-engineering for v1).

### D3. Azure voice catalog ported as a static Dart constant

- **Decision**: Port the voice list from `packages/ai/src/utils/azure/azure-voices.ts` into `lib/features/craft/domain/azure_voice.dart` as a static list. Filter by base language code (e.g., `en`, `zh`, `ja`, `ko`, `es`, `fr`, `de`) at runtime.
- **Rationale**: The voice list is static metadata that rarely changes. Embedding it avoids a runtime network call to Azure's voice listing API and keeps the picker responsive.
- **Alternatives**: Fetch voices from Azure REST API at runtime — rejected (adds latency, requires another auth path, unnecessary for a known fixed set).

### D4. Timestamped transcript estimated from sentence split + proportional duration

- **Decision**: After synthesis completes:
  1. Split the text into sentences using a regex that handles `.`, `。`, `!`, `?`, `！`, `？`, `\n` as boundaries.
  2. Get the total audio duration from the Azure `SynthesisOutcome` or probe via `ffmpeg -i`.
  3. For each sentence, assign `start = (Σ previous sentence char counts / total char count) * totalDurationMs` and `duration = (this sentence char count / total char count) * totalDurationMs`.
  4. Store as multi-entry `timelineJson` array.
- **Rationale**: Azure Speech SDK word-boundary events are not exposed through the current Flutter plugin surface (`AzureSpeechSynthesisOutcome` only returns `audioBytes` + `format`). Estimating from proportional character count is a pragmatic v1 that gives ±2 s accuracy for most sentence lengths. Word-level timestamps are a future enhancement.
- **Alternatives**:
  - Extend the Flutter `azure_speech` plugin to surface boundary events — deferred (significant native-side work on 4 platforms).
  - Use Azure REST API (SSML `audio` + `metadata` flag) — rejected (different auth path, CORS issues on some platforms).

### D5. Preview audio playback via `audioplayers` package

- **Decision**: Add `audioplayers` as a dependency for the in-session preview player. The `media_kit` `Player` is constitutionally restricted to `MediaKitPlayerEngine` / `PlayerController` only (ADR-0003). `audioplayers` is a separate audio engine that does not conflict with media_kit's native context.
- **Rationale**: The constitution says "Only `MediaKitPlayerEngine` / `PlayerController` may own a `media_kit` `Player`." `audioplayers` uses a different native audio backend (ExoPlayer on Android, AVAudioPlayer on iOS, etc.) and does not create a media_kit `Player`. This avoids the constraint.
- **Alternatives**:
  - Write the preview to a temp file and play it via `media_kit` — rejected (violates single-player rule if a media_kit Player is instantiated outside the engine).
  - Use `just_audio` — equally valid; `audioplayers` and `just_audio` are both acceptable. Chose `audioplayers` for simpler API for byte-buffer playback.

### D6. Single controller with two-tool sub-state

- **Decision**: One `CraftController extends Notifier<CraftJobState>` manages both tools. State includes separate fields for translate (sourceText, sourceLang, targetLang, style, translatedText, isTranslating) and synthesize (synthText, synthLang, selectedVoice, audioBytes, isSynthesizing, isSaving). The "Use translated text" action copies `translatedText` into `synthText`.
- **Rationale**: Keeps the state model simple and avoids inter-provider coordination. Both tools are always visible on the same screen; a single state object is the natural model.
- **Alternatives**: Two separate controllers (`TranslateController`, `SynthesizeController`) with a bridge — rejected (unnecessary complexity for a single-screen feature).

### D7. Translate tool source language includes native language

- **Decision**: The source-language picker reuses `showContentLanguagePicker` (which shows the content language catalog) but is extended to include the learner's profile native language at the top of the list. This is a one-line addition to the picker's option list.
- **Rationale**: The user explicitly requires the native language to be selectable. The content language catalog already includes the 8 focus languages; adding the native language (2 options) is a small extension.
- **Alternatives**: A separate language picker for Craft — rejected (unnecessary divergence from the shared picker pattern).

### D8. Repository extension: timestamped transcript entries

- **Decision**: The existing `MediaLibraryRepository.importCraftedFromText` is extended to accept a `List<TranscriptLine>` (text + startMs + durationMs) for the primary transcript, instead of the current single-line timeline. The controller computes the sentence-split timeline via the timestamp estimator before calling the repository.
- **Rationale**: The repository should not know about sentence splitting — that's a presentation/domain concern. The repository just writes whatever timeline it receives.
- **Changes to existing method**: Add an optional `primaryTimelineJson` parameter (defaulting to the current single-line behavior). When provided, it replaces the auto-generated single-line timeline.

## Best-practice patterns from web app

- **Style selector**: dropdown/segmented control with localized labels — ported directly.
- **Voice selector**: dropdown with voice name + gender + locale — ported directly.
- **Language swap**: a swap button that exchanges source and target — ported from web app.
- **Editable result**: the translation result is a `TextField` (not read-only `Text`) so the learner can fix words before synthesis.
- **"Use translated text" bridge**: replaces the web app's `VoiceSynthesisSheet` — a button on the same screen rather than a separate sheet.

## References

- Web app translation route: `apps/web/src/routes/smart-translation.tsx`
- Web app translation styles: `apps/web/src/types/db/common.ts`, `apps/web/src/components/smart-translation/translation-style-selector.tsx`
- Web app voice synthesis route: `apps/web/src/routes/voice-synthesis.tsx`
- Web app voice selector: `apps/web/src/components/voice-synthesis/voice-selector.tsx`
- Azure voice catalog: `packages/ai/src/utils/azure/azure-voices.ts`
- Web app bridge sheet: `apps/web/src/components/smart-translation/voice-synthesis-sheet.tsx`
- Spec 010 infrastructure (reused): `lib/features/ai/data/enjoy/enjoy_tts_capability.dart`, `lib/data/files/file_storage.dart`, `lib/features/library/data/library_repository.dart`
