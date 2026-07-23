# Data Model: Craft Voice-Express Redesign

**Date**: 2026-07-23 | **Feature**: 028-craft-voice-express

---

## Entity: CraftJobState (extended)

The existing immutable state class, extended with Express mode fields.

### Fields

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `screenMode` | `CraftScreenMode` | `express` | Which UI layout is shown |
| `stage` | `CraftStage` | `capture` | Current Express flow position |
| `sourceText` | `String` | `''` | Source text (Advanced translate, or text fallback in Express) |
| `sourceLanguage` | `String?` | `null` | Native/source language tag |
| `targetLanguage` | `String` | `'en'` | Target/learning language tag |
| `style` | `TranslationStyle` | `auto` | **Changed default** from `natural` to `auto` |
| `customPrompt` | `String?` | `null` | Custom style prompt (when style = custom) |
| `translatedText` | `String?` | `null` | LLM rewrite result (also used in Express rewrite stage) |
| `isTranslating` | `bool` | `false` | LLM rewrite in progress |
| `synthText` | `String` | `''` | Text to synthesize (Advanced) |
| `synthLanguage` | `String` | `'en'` | Synthesis language |
| `selectedVoice` | `String?` | `null` | Azure voice ID |
| `previewAudioBytes` | `Uint8List?` | `null` | Generated audio bytes |
| `previewFormat` | `String?` | `null` | Audio format ('wav', 'mp3') |
| `previewWordBoundaries` | `List<CraftWordBoundary>` | `[]` | Azure word boundaries for transcript |
| `isSynthesizing` | `bool` | `false` | TTS in progress |
| `isSaving` | `bool` | `false` | Save in progress |
| `resultMediaId` | `String?` | `null` | Saved media ID |
| `dedupedExistingId` | `String?` | `null` | Existing media ID on dedupe |
| `failure` | `CraftFailure?` | `null` | Active failure |
| `generation` | `int` | `0` | Request generation counter (stale-result guard) |
| **`capturedAudioBytes`** | `Uint8List?` | `null` | **NEW**: Raw recording bytes (Express capture) |
| **`rawTranscript`** | `String?` | `null` | **NEW**: ASR output from captured audio |
| **`isCapturing`** | `bool` | `false` | **NEW**: Recording in progress |
| **`isTranscribing`** | `bool` | `false` | **NEW**: ASR transcription in progress |

### Derived Getters

| Getter | Logic |
|--------|-------|
| `isBusy` | `isCapturing || isTranscribing || isTranslating || isSynthesizing || isSaving` |
| `hasPreview` | `previewAudioBytes != null` |
| `hasTranslation` | `translatedText != null && translatedText!.isNotEmpty` |
| `hasCapturedAudio` | `capturedAudioBytes != null` |

### State Transitions (Express Mode)

```
[capture idle] --tap mic--> [capture recording] --tap stop--> [transcribing]
                                                                         |
                                                                     ASR result
                                                                         |
                                                                    [rewrite]
                                                        /----- edit/regenerate ----\
                                                        |                            |
                                                  [generating audio]           [re-record]
                                                        |
                                                  [audio preview]
                                                  /          \
                                        [say something]   [practice now]
                                              |                    |
                                        [save + reset]      [save + navigate]
```

---

## Entity: CraftScreenMode (new)

```dart
enum CraftScreenMode { express, advanced }
```

- `express` — voice-first linear flow (default)
- `advanced` — two-tool panel layout

---

## Entity: CraftStage (new)

```dart
enum CraftStage { capture, rewrite, audio, done }
```

- `capture` — mic button / text entry
- `rewrite` — raw transcript + editable target + style
- `audio` — preview player + save/loop
- `done` — transient state after save (before reset or navigate)

---

## Entity: TranslationStyle (extended)

```dart
enum TranslationStyle {
  auto,        // NEW — default, AI infers style
  literal,
  natural,
  casual,
  formal,
  simplified,
  detailed,
  custom;
}
```

| Style | `promptSuffix` | l10n Key |
|-------|---------------|----------|
| `auto` | `''` (special system prompt in adapter) | `craftStyleAuto` |
| `literal` | existing | `craftStyleLiteral` |
| ... | ... | ... |
| `custom` | `''` | `craftStyleCustom` |

---

## Entity: CraftTranscriber (new interface)

```dart
abstract interface class CraftTranscriber {
  Future<String> transcribe({
    required Uint8List audioBytes,
    String? language,
  });
}
```

Implementation: `CraftAsrServiceTranscriber` wraps `AsrService.transcribe(AsrRequest(...))` and returns `AsrResult.text`.

---

## Entity: CraftFailure (extended)

New failure types:

| Type | Action | Message Key |
|------|--------|-------------|
| `CraftAsrFailure` | `retry` | `craftFailureAsr` |
| `CraftEmptyTranscriptFailure` | `retry` | `craftFailureEmptyTranscript` |

Existing failures unchanged: `CraftTranslateFailure`, `CraftTtsFailure`, `CraftSaveFailure`, `CraftSignInRequiredFailure`, `CraftOfflineFailure`, `CraftSameLanguageFailure`, `CraftVendorUnsupportedLanguageFailure`.

---

## Persistence: No Schema Changes

### Existing Tables Used

| Table | Column | Usage |
|-------|-------|-------|
| `Audios` | `provider` | `'craft'` (unchanged) |
| `Audios` | `source` | `'craft-express'` (Express), `'craft-translate'` / `'craft-direct'` (Advanced) |
| `Audios` | `sourceText` | Raw native transcript (Express), or original text (Advanced) |
| `Audios` | `voice` | Azure voice ID |
| `Audios` | `language` | Target/learning language |
| `Transcripts` | `timelineJson` | Word-segmented timestamped timeline from Azure boundaries |

### Dedupe Key

```
'craft-express|$learningLanguage|$normalizedText|$voiceKey'
```

Independently deduped from `'craft-translate'` and `'craft-direct'` items.

---

## Validation Rules

| Rule | Implementation |
|------|---------------|
| Min text length: 10 chars (post-normalize) | `craftMinTextLength` constant (existing) |
| Max text length: 5000 chars (truncated) | `craftMaxTextLength` constant (existing) |
| Min recording: > 1 second | Widget-level guard in `CaptureStage` before calling `stopCapture()` |
| Same-language guard | `_sameBaseLanguage()` check in controller (existing) |
| Sign-in required for synthesize + save | `authCtrlProvider` check (existing) |
