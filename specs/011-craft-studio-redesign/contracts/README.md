# Contracts: Craft Studio (Redesigned)

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

> Spec 010 infrastructure is reused. This document covers the **new and changed** contracts only.

---

## C1. GoRouter route: `/craft` (NEW)

**Module**: `lib/core/routing/app_router.dart`

The import chooser's "Craft from text" `onTap` changes from `showCraftSheet(context, ref)` to `context.push('/craft')`. The route renders `CraftScreen`.

---

## C2. `CraftController` — two-tool state (CHANGED)

**Module**: `lib/features/craft/application/craft_controller.dart`

Rewritten from the spec 010 single-pipeline controller to a two-tool controller:

```dart
// Translate actions
void setSourceText(String text);
void setSourceLanguage(String? lang);
void setTargetLanguage(String lang);
void setStyle(TranslationStyle style);
void setCustomPrompt(String? prompt);
void setTranslatedText(String text); // for inline editing
Future<void> translate();      // calls ChatService (/chat/completions) with style prompt
void useTranslatedText();      // copies translatedText → synthText

// Synthesize actions
void setSynthText(String text);
void setSynthLanguage(String lang);
void setSelectedVoice(String? voice);
Future<void> synthesize();     // calls TtsService with selected voice
Future<String?> saveToLibrary(); // persists audio + timestamped transcript
```

---

## C3. `TranslationStyle` enum + prompt mapping (NEW)

**Module**: `lib/features/craft/domain/translation_style.dart`

```dart
enum TranslationStyle {
  literal, natural, casual, formal, simplified, detailed, custom;

  String get promptSuffix => switch (this) {
    literal => 'Translate the text as literally as possible...',
    natural => 'Translate the text naturally...',
    casual => 'Translate in a casual, conversational tone...',
    formal => 'Translate in a formal, professional register...',
    simplified => 'Translate using simple vocabulary and short sentences...',
    detailed => 'Translate with additional context and nuance...',
    custom => '', // custom prompt replaces this entirely
  };
}
```

---

## C4. `AzureVoice` catalog + filter (NEW)

**Module**: `lib/features/craft/domain/azure_voice.dart`

Static list of ~40 Azure Neural voices ported from the web app. `List<AzureVoice> voicesForLanguage(String baseLang)` filters by base language code.

---

## C5. `TranscriptTimestampEstimator` (NEW)

**Module**: `lib/features/craft/domain/transcript_timestamp_estimator.dart`

```dart
List<Map<String, dynamic>> estimateTimeline({
  required String text,
  required int totalDurationMs,
});
```

Returns sentence-split timeline entries with proportional offsets.

---

## C6. `MediaLibraryRepository.importCraftedFromText` (EXTENDED)

**Module**: `lib/features/library/data/library_repository.dart`

Added parameter `String? primaryTimelineJson` — when provided (by the controller after timestamp estimation), replaces the default single-line timeline. Also added `String? voice` parameter for storing the selected voice and including it in the dedupe hash.

---

## C7. Preview audio player (NEW)

Uses `audioplayers` package (`AudioPlayer`) for in-session preview playback. Does NOT instantiate `media_kit` `Player` — avoids the single-player constitution constraint. The preview plays from in-memory bytes via `audioPlayer.play(BytesSource(...))`.
