# ADR-0060: Craft Voice-Express dual-mode redesign

## Status

Accepted

## Context

The Craft feature ("self-made materials") originally had a two-tool layout: a Translate panel and a Synthesize panel, both working with prepared text. Users paste or type text, translate it, then synthesize audio for shadow-reading practice.

Through product discovery, we identified a core insight: **language learners can't speak fluently because they don't have enough to say** — they've never expressed their daily thoughts in the target language. The existing Craft flow assumed the user already had prepared text, which misses the most valuable use case: capturing spontaneous thoughts.

The redesign introduces a **voice-first Express mode** as the default, where the user speaks in their native language and AI rewrites it into the target language in a single step — no separate native-refine confirmation step. The existing two-tool layout is retained as "Advanced" mode for users who already have prepared text.

## Decision

### Dual-mode screen layout

Craft screen defaults to **Express mode** (voice-first linear flow) with a `SegmentedButton<CraftScreenMode>` toggle to switch to **Advanced mode** (existing Translate + Synthesize tools).

- **Express mode**: capture → rewrite → audio pipeline with a rapid-capture loop
- **Advanced mode**: two-tool layout (TranslateTool + SynthesizePanel) via `AdvancedTools` container with `LayoutBuilder` responsive breakpoints

### "Auto" translation style

A new `TranslationStyle.auto` is the default for Express mode. Instead of a literal translation, the system prompt instructs the LLM to act as a "language partner" — reading the user's spontaneous thought, understanding their intent and personal style, and rewriting it idiomatically in the target language as a fluent speaker would naturally say it.

The Auto-style system prompt is defined in `CraftTranslationServiceTranslator._autoStylePrompt()` and is distinct from all other style prompts (literal, natural, casual, etc.).

### Rapid-capture loop

After audio generation, the user can:
1. **"Say something else"** (`saveAndCaptureNext`) — saves the current item to the library, shows a brief snackbar confirmation, and resets to the capture stage while preserving session preferences (language pair, style, voice)
2. **"Practice now"** (`saveAndPractice`) — saves and navigates to the player route with the new media ID

This enables building a personal library of shadow-reading material in rapid succession.

### Express items tagged `craft-express`

Saved items from Express mode use `sourceFlag = 'craft-express'` (distinct from `craft-translate` and `craft-direct` in Advanced mode) for dedupe independence and analytics.

### Responsive layout

- Express mode uses `EnjoyPageKind.form` for centered column with adaptive gutters
- Advanced mode uses `pageGutterOf` for full-bleed with responsive gutters
- `AdvancedTools` uses `LayoutBuilder` with 600px breakpoint: Row (side-by-side) on wide screens, Column (stacked) on narrow screens

### AudioRecorder ownership

`CaptureStage` owns the `AudioRecorder` instance (not the controller), mirroring the proven pattern from `ShadowReadingPanel`. The recorder is recreated after each `stop()` to avoid stale Media Foundation state on Windows. `RecordConfig` matches the shadow-reading format: 16kHz mono WAV.

## Consequences

- **New domain types**: `CraftScreenMode`, `CraftStage`, `CraftTranscriber`, `TranslationStyle.auto`, `CraftAsrFailure`, `CraftEmptyTranscriptFailure`
- **Extended controller**: `CraftController` gains Express-mode methods (`setScreenMode`, `startCapture`, `stopCapture`, `useTextInput`, `transcribeAndRewrite`, `regenerate`, `generateAudio`, `saveAndPractice`, `saveAndCaptureNext`, `resetForNextCapture`)
- **New presentation widgets**: `CaptureStage`, `RewriteStage`, `AudioStage`, `ExpressFlow`, `AdvancedTools`
- **Existing tools retained**: `TranslateTool` and `SynthesizeTool` remain unchanged — `AdvancedTools` wraps them in a responsive container
- **No schema changes**: No new database tables or columns — Express items are persisted via the existing `importCraftedFromText()` path

## References

- [ADR-0004: Feature-first architecture](0004-feature-first-architecture.md)
- [ADR-0003: media_kit as the single player engine](0003-player-core-media-kit.md)
- [ADR-0042: Multi-language lookup catalog](0042-multi-language-lookup-catalog.md)
- [ADR-0055: Adaptive page layout system](0055-adaptive-page-layout-system.md)
- [Feature spec: Craft Voice-Express](../../specs/028-craft-voice-express/spec.md)
