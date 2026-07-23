# Contract: CraftController

**Date**: 2026-07-23 | **Feature**: 028-craft-voice-express

---

## Overview

The `CraftController` is a Riverpod `Notifier<CraftJobState>` that orchestrates both Express and Advanced Craft flows. This contract documents the public API surface (methods, providers) that the presentation layer depends on.

---

## Providers

### Existing (unchanged)

| Provider | Type | Purpose |
|----------|------|---------|
| `craftControllerProvider` | `NotifierProvider<CraftController, CraftJobState>` | Main state |
| `craftTranslatorProvider` | `Provider<CraftTranslator>` | LLM translation/rewrite adapter |
| `craftSynthesizerProvider` | `Provider<CraftSynthesizer>` | TTS adapter |

### New

| Provider | Type | Purpose |
|----------|------|---------|
| `craftTranscriberProvider` | `Provider<CraftTranscriber>` | ASR transcription adapter |

```dart
final craftTranscriberProvider = Provider<CraftTranscriber>((ref) {
  return CraftAsrServiceTranscriber(ref.read(asrServiceProvider));
});
```

---

## Controller Methods

### Mode & Stage Management

| Method | Parameters | Effect |
|--------|-----------|--------|
| `setScreenMode(CraftScreenMode mode)` | mode | Sets `screenMode`, preserves all other state |

### Express Capture

| Method | Parameters | Effect |
|--------|-----------|--------|
| `startCapture()` | none | Sets `isCapturing = true`, `stage = capture` |
| `stopCapture(Uint8List audioBytes)` | audioBytes | Sets `isCapturing = false`, `capturedAudioBytes`, triggers `transcribeAndRewrite()` |
| `useTextInput(String text)` | text | Sets `rawTranscript = text`, `stage = rewrite` (skips ASR), triggers rewrite |

### Express Transcribe + Rewrite

| Method | Parameters | Effect |
|--------|-----------|--------|
| `transcribeAndRewrite()` | none | Runs ASR on `capturedAudioBytes` → `rawTranscript` → LLM rewrite → `translatedText`, sets `stage = rewrite`. Guards: empty transcript → failure, no rewrite call. |
| `regenerate()` | none | Re-runs LLM rewrite with current style on `rawTranscript` |

### Express Audio

| Method | Parameters | Effect |
|--------|-----------|--------|
| `generateAudio()` | none | Sets `synthText = translatedText`, `synthLanguage = targetLanguage`, auto-selects default voice if none, runs TTS, sets `stage = audio` |
| `saveAndPractice()` | none | Saves to library, navigates to player route |
| `saveAndCaptureNext()` | none | Saves to library, calls `resetForNextCapture()`, shows toast |
| `resetForNextCapture()` | none | Clears working data, `stage = capture`, preserves language pair + style + voice |

### Advanced (existing methods, unchanged)

| Method | Parameters | Effect |
|--------|-----------|--------|
| `setSourceText(String)` | text | Sets source text |
| `setSourceLanguage(String?)` | lang | Sets source language |
| `setTargetLanguage(String)` | lang | Sets target language |
| `setStyle(TranslationStyle)` | style | Sets translation style |
| `setCustomPrompt(String?)` | prompt | Sets custom prompt |
| `setTranslatedText(String)` | text | Inline edit of result |
| `swapLanguages()` | none | Swaps source/target |
| `useTranslatedText()` | none | Copies translated text to synth tool |
| `translate()` | none | Runs LLM translation |
| `setSynthText(String)` | text | Sets synth text |
| `setSynthLanguage(String)` | lang | Sets synth language + auto-voice |
| `setSelectedVoice(String?)` | voice | Sets voice |
| `synthesize()` | none | Runs TTS |
| `saveToLibrary()` | none | Saves to library, returns mediaId |
| `clearResult()` | none | Clears result/failure |

---

## State Observability

The presentation layer reads `CraftJobState` via `ref.watch(craftControllerProvider)` and reacts to:

| Observable | When | UI Effect |
|-----------|------|-----------|
| `screenMode == express` | Always toggled | Show `ExpressFlow` widget tree |
| `screenMode == advanced` | Always toggled | Show `AdvancedTools` widget tree |
| `stage == capture && !isCapturing` | Initial / after reset | Show mic button + text fallback |
| `stage == capture && isCapturing` | Recording | Show stop button + waveform |
| `stage == rewrite && isTranscribing` | ASR/LLM running | Show loading indicator |
| `stage == rewrite && !isTranscribing` | Result ready | Show raw transcript + editable target |
| `stage == audio && isSynthesizing` | TTS running | Show loading indicator |
| `stage == audio && !isSynthesizing` | Audio ready | Show preview player + save buttons |
| `failure != null` | Any stage | Show failure message + action |

---

## Navigation Contract

| Trigger | Destination |
|----------|-------------|
| `saveAndPractice()` success | `Navigator.pushReplacementNamed('/player', arguments: mediaId)` |
| `saveAndCaptureNext()` success | Stay on `/craft`, reset to capture stage, show toast |
| App bar back button | `Navigator.pop()` or `pushNamed('/')` |
