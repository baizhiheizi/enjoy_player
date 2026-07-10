# Data Model: Craft Studio (Redesigned)

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

> **No Drift schema migration.** Reuses existing `Audios` and `Transcripts` tables. The timestamped transcript uses the existing `timelineJson` column with multiple entries (sentence-split) instead of a single line.

## Entities

### AudioRow — Craft-generated audio (`Audios`)

Same as spec 010. One durable row per Craft save.

| Field | Craft usage |
|-------|-------------|
| `provider` | `'craft'` |
| `source` | `'craft-translate'` (Translate then synthesize) or `'craft-direct'` (Synthesize only) |
| `language` | Learning language (canonical base tag) |
| `translationKey` | Source language (translate mode) or learning language (direct mode) |
| `sourceText` | Original source text (pre-translation for translate mode; equals synthesized text for direct mode) |
| `voice` | Selected Azure Neural voice id (e.g., `'en-US-JennyNeural'`) |
| `md5` | SHA-256 of `sourceFlag|learningLanguage|normalizedText|voice` (includes voice for dedupe) |
| Other fields | Same as spec 010 |

### TranscriptRow — Craft primary transcript (`Transcripts`)

**Key change from spec 010**: `timelineJson` contains **multiple entries** (sentence-split with estimated timestamps) instead of a single monolithic line.

| Field | Craft usage |
|-------|-------------|
| `source` | `'ai'` |
| `language` | Learning language |
| `timelineJson` | `[{text: sentence1, start: 0, duration: ms1}, {text: sentence2, start: ms1, duration: ms2}, ...]` — sentence-split with proportional timestamps |

### TranscriptRow — Craft secondary transcript (Translate then synthesize only)

Same as spec 010 — single-line timeline with the original source text.

### TranslationStyle (new domain enum)

```dart
enum TranslationStyle {
  literal,    // "Translate as literally as possible..."
  natural,    // "Translate naturally..."
  casual,     // "Translate in a casual, conversational tone..."
  formal,     // "Translate in a formal, professional register..."
  simplified, // "Translate using simple vocabulary..."
  detailed,   // "Translate with additional context..."
  custom;     // Free-form prompt replaces style instruction
}
```

Each style (except `custom`) maps to a prompt suffix in `TranslationStyle.promptSuffix`.

### AzureVoice (new domain model)

```dart
class AzureVoice {
  final String id;        // e.g., 'en-US-JennyNeural'
  final String label;     // e.g., 'Jenny (US, Female)'
  final String gender;    // 'male' | 'female'
  final String locale;    // e.g., 'en-US'
  final String baseLang;  // e.g., 'en'
}
```

Static catalog ported from `azure-voices.ts`. Filtered by `baseLang` at runtime.

### TranscriptTimestampEstimator (new domain utility)

Input: `text` (learning-language string), `totalDurationMs` (int).
Output: `List<({String text, int startMs, int durationMs})>` — sentence-split timeline.

Algorithm:
1. Split text on `[.。！？!?\n]` boundaries; trim empty segments.
2. Count characters per segment.
3. `totalChars = Σ segment lengths`.
4. For each segment: `startMs = (Σ prevChars / totalChars) * totalDurationMs`; `durationMs = (thisChars / totalChars) * totalDurationMs`.

### CraftJobState (extended from spec 010)

```dart
class CraftJobState {
  // Translate tool state
  final String sourceText;
  final String? sourceLanguage;
  final String targetLanguage;
  final TranslationStyle style;
  final String? customPrompt;
  final String? translatedText;
  final bool isTranslating;

  // Synthesize tool state
  final String synthText;           // Pre-filled from translatedText or manual entry
  final String synthLanguage;
  final String? selectedVoice;
  final Uint8List? previewAudio;
  final String? previewFormat;
  final int? previewDurationMs;
  final bool isSynthesizing;
  final bool isSaving;

  // Result
  final String? resultMediaId;
  final String? dedupedExistingId;
  final CraftFailure? failure;
  final int generation;
}
```

## Validation rules

1. `sourceText.trim().length >= 10` for Translate action.
2. `synthText.trim().length >= 10` for Synthesize action.
3. `synthText.trim().length <= 5000` (truncate with notice above this).
4. Same source + target language in Translate: show hint, don't call API.
5. Dedupe: `SHA-256(sourceFlag|learningLanguage|normalizedText|voice)` — includes voice in the hash so the same text with different voices produces different items.
6. Failure at any stage discards in-memory state; no orphan rows.
7. Sentence split must produce at least 1 entry even for single-sentence text.

## State transitions

```text
CRAFT SCREEN OPEN
    │
    ├─── TRANSLATE TOOL ──────────────────────────────┐
    │    idle → translating → result (editable)       │
    │    result → re-translating → new result         │
    │    result → "Use translated text" → fills synth │
    │                                                 │
    ├─── SYNTHESIZE TOOL ─────────────────────────────┤
    │    idle → synthesizing → preview (playable)     │
    │    preview → re-synthesizing → new preview      │
    │    preview → saving → completed (media id)      │
    │                                                 │
    └─── FAILURE at any stage → failed (retry action)─┘
```
