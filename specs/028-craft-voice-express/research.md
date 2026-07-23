# Research: Craft Voice-Express Redesign

**Date**: 2026-07-23 | **Feature**: 028-craft-voice-express

---

## Research Task 1: How to add ASR voice capture to the Craft controller

### Question

The Craft controller currently has no voice capture. Shadow reading uses `AudioRecorder` from the `record` package in a `ConsumerStatefulWidget`. How should the Craft controller (a Riverpod `Notifier`, stateless) manage recording lifecycle?

### Decision

Keep the `AudioRecorder` instance in the **presentation layer** (`CaptureStage` widget as `ConsumerStatefulWidget`), not in the controller. The controller exposes `startCapture()` / `stopCapture()` that manage state flags (`isCapturing`, `capturedAudioBytes`), while the widget owns the `AudioRecorder`, timer, and waveform animation — mirroring the proven pattern from `ShadowReadingPanel`.

### Rationale

- `AudioRecorder` is stateful and platform-coupled (must be recreated after `stop()` per shadow-reading comment: "recorder on Windows can keep stale Media Foundation state"). A Riverpod `Notifier` has no `dispose` lifecycle hook that fires before widget disposal.
- The shadow reading panel already solved this: `_ShadowReadingPanelState` owns `_recorder`, creates `RecordConfig`, handles permission, writes WAV to a temp path, then passes the bytes to the persistence layer.
- The Craft controller receives the WAV path after `stop()` and orchestrates ASR → rewrite → TTS → save, staying purely in the async orchestration domain.

### Alternatives Considered

1. **AudioRecorder inside the controller via a Riverpod-managed wrapper** — rejected: `Notifier.build()` has no access to platform resources at construction; lifecycle management would require a `KeepAlive` provider with explicit `dispose()`, adding complexity without benefit.
2. **A separate `CraftRecordingService` provider** — rejected: over-abstraction. The recording is inherently tied to the `CaptureStage` widget lifecycle and the session state.

---

## Research Task 2: How to wire ASR into the Craft data layer

### Question

`AsrService.transcribe()` accepts an `AsrRequest` with `audioBytes`, `filename`, `language` hint, etc. How should the Craft data layer wrap this?

### Decision

Create `CraftTranscriber` interface (in `domain/craft_transcriber.dart`) and `CraftAsrServiceTranscriber` implementation (in `data/craft_asr_service_transcriber.dart`), mirroring the existing `CraftTranslator` / `CraftSynthesizer` pattern.

```dart
// domain/craft_transcriber.dart
abstract interface class CraftTranscriber {
  Future<String> transcribe({
    required Uint8List audioBytes,
    String? language,
  });
}
```

The implementation wraps `AsrService.transcribe()`, mapping the `AsrResult.text` field.

### Rationale

- Consistent with the existing `CraftTranslator` / `CraftSynthesizer` adapter pattern — each AI capability gets a domain interface + data-layer adapter, enabling easy test faking.
- The existing test harness (`_FakeTranslator`, `_FakeSynthesizer`) extends naturally with `_FakeTranscriber`.

### Alternatives Considered

1. **Call `AsrService` directly from the controller** — rejected: breaks the adapter pattern, harder to test (need to mock `AsrService` instead of a simple interface).

---

## Research Task 3: How to implement the "Auto" translation style

### Question

The existing `TranslationStyle` enum has a `promptSuffix` getter. "Auto" is fundamentally different — it's not a suffix but a different system prompt. How to integrate?

### Decision

Add `TranslationStyle.auto` as the first enum value. In `CraftTranslationServiceTranslator.translate()`, handle `auto` with a special system prompt (from the design spec) that is not a `promptSuffix` but a complete instruction block.

```dart
// In CraftTranslationServiceTranslator.translate():
if (style == TranslationStyle.auto) {
  systemPrompt = _autoStylePrompt(sourceBase, targetBase);
} else if (style == TranslationStyle.custom && ...) {
  // existing custom path
} else {
  // existing suffix path
}
```

The auto-style prompt from the design spec:
> "You are a language partner. The user recorded themselves thinking out loud in [native]. Read what they said, understand their real meaning and the way they naturally express themselves (their personal style, register, tone). Then rewrite it in [target] the way they would actually say it if they were a fluent [target] speaker — idiomatic, natural spoken form. Preserve their intent and personality. Do NOT translate literally or robotically."

### Rationale

- `auto` as the default enum value means the existing `default` case in `CraftJobState` constructor changes from `TranslationStyle.natural` to `TranslationStyle.auto`.
- The prompt suffix getter returns empty string for `auto` (same as `custom`) — the actual prompt is built in the adapter.
- The ARB l10n key `craftStyleAuto` is added.

### Alternatives Considered

1. **A separate boolean `isAutoStyle` flag** — rejected: pollutes the state class. The enum is the right abstraction for style selection.

---

## Research Task 4: How to extend CraftJobState for Express mode

### Question

The current `CraftJobState` is a flat immutable class with translate + synthesize fields. Express mode needs: `screenMode`, `stage`, `capturedAudioBytes`, `rawTranscript`, `isCapturing`, `isTranscribing`. How to add these without breaking existing tests?

### Decision

Extend `CraftJobState` with new optional fields. All new fields have defaults so the existing `const CraftJobState()` constructor remains compatible.

New fields:
- `CraftScreenMode screenMode = CraftScreenMode.express`
- `CraftStage stage = CraftStage.capture`
- `Uint8List? capturedAudioBytes`
- `String? rawTranscript`
- `bool isCapturing = false`
- `bool isTranscribing = false`

New `copyWith` parameters follow the existing nullable-with-clear pattern. The existing `isBusy` getter extends to include `isCapturing || isTranscribing`.

### Rationale

- Adding fields to the existing class is less disruptive than creating a union/Freezed sealed hierarchy. Both modes share the same controller state, and the existing tests check specific fields — those assertions remain valid.
- The `screenMode` field defaults to `express` so the Craft screen opens in Express mode per the design.

### Alternatives Considered

1. **A separate `CraftExpressState` Freezed class** — rejected: both modes share state (switching preserves work), so a single state object is correct.

---

## Research Task 5: How to handle the rapid-capture loop reset

### Question

"Say something else" saves the current item then resets to Stage 1 (capture). What state survives the reset and what gets cleared?

### Decision

Add a `resetForNextCapture()` method to `CraftController` that clears Express-specific working state but preserves:
- `screenMode` (stays express)
- `sourceLanguage` / `targetLanguage` (stays the same — same language pair)
- `style` (stays auto or whatever the user chose)
- `selectedVoice` (stays the same voice)

Clears:
- `capturedAudioBytes`, `rawTranscript`
- `translatedText`
- `previewAudioBytes`, `previewFormat`, `previewWordBoundaries`
- `synthText`, `sourceText`
- `stage` → back to `CraftStage.capture`
- `resultMediaId`, `dedupedExistingId`, `failure`

### Rationale

- Language pair, style, and voice are session preferences — resetting them every loop adds friction and contradicts the "rapid-capture" goal.
- The working data (transcript, rewrite, audio) must be cleared to avoid confusion.

---

## Research Task 6: Responsive layout strategy for the Craft screen

### Question

Express uses a centered column at all breakpoints. Advanced switches from stacked to side-by-side at 600px. How to implement with the existing `EnjoyPage` system?

### Decision

Use `EnjoyPageKind.form` for Express mode (centered form column with `formMaxWidth` token — gives a single centered column that scales with breakpoint). For Advanced mode, use `EnjoyPageKind.browse` (full content-pane width) with an internal `LayoutBuilder` that switches between `Row` (≥600px) and `Column` (<600px).

The Craft screen wraps both in a `Scaffold` with an app bar containing a `SegmentedButton` using `enjoySegmentedButtonStyle`. The body uses `LayoutBuilder` → `EnjoyPageMetrics.of()` for gutter/max-width.

### Rationale

- `EnjoyPageKind.form` already provides the centered column behavior Express needs (max-width formMaxWidth, gutter scaling).
- `EnjoyPageKind.browse` gives full-bleed width for the side-by-side Advanced layout.
- This follows ADR-0055 (adaptive page layout system) and avoids inventing per-screen max widths.

---

## Research Task 7: How sourceFlag maps for Express vs Advanced saves

### Question

`importCraftedFromText` receives a `sourceFlag` string. Express flow has a different provenance than Advanced translate-then-synthesize or direct synthesize. What flag should Express use?

### Decision

Add `'craft-express'` as a new `sourceFlag` value for items created via the Express flow. The existing `CraftMode` enum (translateThenSpeak → `'craft-translate'`, speakDirectly → `'craft-direct'`) stays for Advanced mode.

In `CraftController.saveToLibrary()`, check `state.screenMode`:
- `CraftScreenMode.express` → `sourceFlag = 'craft-express'`
- `CraftScreenMode.advanced` → existing logic (craft-translate / craft-direct)

No schema change needed — `Audios.source` already accepts any string.

### Rationale

- Differentiating Express items in analytics/dedupe without a schema migration.
- Dedupe hash already includes `sourceFlag`, so Express items are deduped independently.

---

## Research Task 8: How to handle empty/short transcript from ASR

### Question

ASR might return empty text for a very short or silent recording. The spec says "ASR returns empty or near-empty transcript: the learner is asked to re-record; no rewrite call is made." How to implement?

### Decision

Add `CraftEmptyTranscriptFailure` to the `CraftFailure` sealed hierarchy. In `transcribeAndRewrite()`, after ASR returns, check if `result.text.trim().length < craftMinTextLength` (10 chars). If so, set failure to `CraftEmptyTranscriptFailure` with `CraftFailureAction.retry` and do NOT proceed to the LLM call.

```dart
if (transcript.trim().length < craftMinTextLength) {
  state = state.copyWith(
    isTranscribing: false,
    failure: const CraftEmptyTranscriptFailure(),
  );
  return;
}
```

### Rationale

- Consistent with the existing `craftMinTextLength` guard for translate/synthesize.
- The failure surfaces a calm message with Retry action (re-record).

---

## Summary: No NEEDS CLARIFICATION remaining

All unknowns resolved. Key decisions:
1. AudioRecorder in widget, not controller
2. `CraftTranscriber` interface + `CraftAsrServiceTranscriber` adapter
3. `TranslationStyle.auto` with special system prompt in the adapter
4. Extend `CraftJobState` with new fields (defaults preserve compatibility)
5. `resetForNextCapture()` preserves language pair / style / voice
6. `EnjoyPageKind.form` for Express, `EnjoyPageKind.browse` for Advanced
7. `'craft-express'` sourceFlag for Express items
8. `CraftEmptyTranscriptFailure` for empty ASR results
