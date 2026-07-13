# Craft from Text

## Summary

**Craft from Text** generates AI-synthesized audio from pasted text, surfaced as a single import entry alongside "From file" and "From YouTube URL". Learners can translate text into their learning language or synthesize audio directly.

Generated audio items are regular library media (`provider = 'craft'`) — they support echo mode, transcripts, library browsing, and cloud sync without special wiring.

## Navigation

- Import chooser → **Craft from text…** → `/craft`
- Flows as a full-screen route; back returns to the import chooser.

## Modes

| Mode | What it does | When to use |
|------|-------------|-------------|
| **Translate then speak** | Translate source text → learning language, then synthesize TTS audio | You have text in another language (e.g. a news article) |
| **Speak directly** | Synthesize TTS audio directly from learning-language text | You already have text in your learning language |

`CraftMode` (`lib/features/craft/domain/craft_mode.dart`):
- `translateThenSpeak` — requires source-language picker; produces a secondary source-text transcript.
- `speakDirectly` — no translation step; single transcript track.

Both modes share one `CraftSheet` screen with a segmented mode toggle.

## Screen layout

### Translate tool

- **Source language** picker (from the lookup language catalog)
- **Target language** pre-filled from the learner's focus language
- **Style preset** selector (formal, casual, etc.) with an optional custom prompt
- **Edit / copy / re-translate** actions on the translated output
- **Same-language guard**: selecting the same source and target language surfaces a localized hint to switch to Speak directly

### Synthesize tool

- **Text** input (either the translated result or pasted learning-language text)
- **Target language** (pre-filled)
- **Voice picker** (Azure Neural voices per language)
- **Preview** button to hear a sample before saving
- **Save** generates the audio file and inserts the media row

### Voice picker (v1)

Azure Neural voices grouped by language. Supported languages map to the subset of the lookup catalog that Enjoy TTS supports:

| Code | Language | Voices |
|------|----------|--------|
| en-US | English (US) | 15+ neural voices |
| zh-CN | Chinese (Mandarin) | 8+ neural voices |
| ja-JP | Japanese | 5+ neural voices |
| ko-KR | Korean | 3+ neural voices |
| es-ES / es-MX | Spanish | 6+ neural voices |
| fr-FR / fr-CA | French | 6+ neural voices |
| de-DE | German | 5+ neural voices |
| pt-BR / pt-PT | Portuguese | 3+ neural voices |
| it-IT | Italian | 3+ neural voices |
| ru-RU | Russian | 2+ neural voices |

Per-call voice selection is v1 scope; the provider-default voice is used for initial creation. Voice names and gender labels come from `AzureVoice` (`lib/features/craft/domain/azure_voice.dart`).

## Provider / capability routing

| Action | Enjoy (default) | BYOK |
|--------|----------------|------|
| Translate | `chatServiceProvider` → Enjoy worker `POST /translations` | `chatServiceProvider` → BYOK LLM (OpenAI / Anthropic / Google-compatible) |
| Synthesize | `ttsServiceProvider` → `EnjoyTtsCapability` → Azure Speech SDK (worker token) | `ttsServiceProvider` → BYOK TTS (OpenAI `/audio/speech` or Azure Speech subscription key) |

**Azure Speech SDK wiring** (`lib/features/craft/data/craft_tts_service_synthesizer.dart`):
1. Fetch a short-lived Azure token via `AzureTokenCache.getToken(purpose: 'tts')` (worker endpoint `POST /azure/tokens`, 9-min TTL).
2. Call `AzureSpeech.instance.synthesize(text, voice, locale)` through the native plugin ([`packages/azure_speech`](../../packages/azure_speech/)).
3. The native SDK returns a WAV byte buffer; saved to the app's audio directory.

BYOK TTS follows the same `AzureSpeech.instance.synthesize` path when BYOK is configured with an Azure subscription key, or calls `TtsService` via the OpenAI-compatible HTTP path.

## Word-segmented transcript

After synthesis, `wordBoundary` events from the Azure Speech SDK produce time-aligned `startMs` / `durationMs` segments. The word segmenter (`lib/features/craft/domain/word_boundary_segmenter.dart`) groups words into ~6-word segments, using sentence-end punctuation as break points. The resulting `track.lines` list is a standard transcript track, so the transcript viewer and echo mode operate without craft-specific code.

## Output schema

| Field | Value |
|-------|-------|
| `Audios.provider` | `'craft'` |
| `Audios.source` | `'craft-translate'` (translate mode) or `'craft-direct'` (speak directly) |
| `Audios.sourceText` | Original text (retained for re-generation) |
| Audio file | WAV in app audio directory |
| Transcript | One track (`source = 'craft'`) with word-boundary-segmented lines; secondary source-text track in translate mode |

### Deduplication

`SHA-256(sourceFlag | learningLanguage | normalizedText)`. Re-pasting identical text returns the existing media id without making any AI calls. `normalizedText` strips whitespace differences and normalizes Unicode so copy-paste variation does not defeat dedup.

## Library surface

- **Craft badge**: Library tiles show a Craft indicator for items where `Audios.provider == 'craft'`.
- **Sync routing**: `provider = 'craft'` participates in the existing sync queue (metadata + recording uploads).
- **`deleteMedia` cleanup**: Deleting a Craft media item removes the audio file, transcript rows, and sync queue entry.

## Failure handling

All failures go through the `CraftFailure` sealed hierarchy (`lib/features/craft/domain/craft_failure.dart`):

| Failure | Trigger | Action |
|---------|---------|--------|
| `CraftTranslateFailure` | Translation API error | Retry |
| `CraftTtsFailure` | TTS synthesis error | Retry or open AI settings |
| `CraftSaveFailure` | File write or DB insert error | Retry |
| `CraftSignInRequiredFailure` | Auth session missing | Sign in |
| `CraftOfflineFailure` | No network | Retry when online |
| `CraftSameLanguageFailure` | Source and target language match | Switch to Speak directly |
| `CraftVendorUnsupportedLanguageFailure` | Vendor doesn't support the language | Retry (change language) |

**All-or-nothing write**: Translation, synthesis, and save run in a single try block. If any stage fails, no repository write happens — no orphan transcript rows or audio files.

## v1 limits and out-of-scope

| Constraint | Detail |
|------------|--------|
| Text length | 5 000 characters (truncated with ellipsis) |
| Voice picker | Azure Neural only; no local/offline TTS |
| Output format | Audio-only (no video generation) |
| Per-call voice | Provider-default voice used; picker is v1 |
| Offline | Requires network (Enjoy worker or BYOK endpoint) |

## Architecture map

| Layer | Key files |
|-------|-----------|
| **Domain** | `craft_mode.dart`, `craft_failure.dart`, `craft_request.dart`, `craft_job_state.dart`, `craft_job_status.dart`, `craft_translator.dart`, `craft_synthesizer.dart`, `azure_voice.dart`, `translation_style.dart`, `word_boundary_segmenter.dart`, `transcript_timestamp_estimator.dart`, `wav_duration.dart` |
| **Application** | `craft_controller.dart` |
| **Data** | `craft_translation_service_translator.dart`, `craft_tts_service_synthesizer.dart` |
| **Presentation** | `craft_screen.dart`, `translate_tool.dart`, `synthesize_tool.dart`, `voice_picker.dart`, `style_picker.dart` |
| **Integration** | `LibraryRepository.importCraftedFromText()` (library data layer) |
| **AI wiring** | `EnjoyTtsCapability` (`lib/features/ai/data/enjoy/`), `ChatService` / `TtsService` providers |
| **Native plugin** | [`packages/azure_speech`](../../packages/azure_speech/) (synthesize, word boundary events) |

## Test pointers

- Unit tests: `test/features/craft/` — covers `CraftFailure` messages, `WordBoundarySegmenter` grouping, dedup hashing, `TranscriptTimestampEstimator`.
- Widget tests: `test/features/craft/` — covers mode toggle, same-language guard, failure banners.
- Integration test surface: Craft import flow is exercised in the import-chooser integration test suite.

## Related

- [ADR-0043: Craft from Text Import](../decisions/0043-craft-from-text-import.md)
- [ADR-0014: AI Capabilities Layer](../decisions/0014-ai-capabilities-layer.md)
- [ADR-0033: BYOK AI Provider Settings](../decisions/0033-byok-ai-provider-settings.md)
- [AI capabilities](ai.md)
- [Library](library.md)
- [Transcript](transcript.md)
- [Settings](settings.md)
- [Spec 010: Craft from Text](../../specs/010-craft-from-text/)
- [Spec 011: Craft Studio Redesign](../../specs/011-craft-studio-redesign/)
