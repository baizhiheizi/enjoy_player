# Craft Redesign — Voice-First Express Flow + Advanced Mode

**Date**: 2026-07-23
**Status**: Approved (mockups reviewed)
**Related issue**: [#439](https://github.com/baizhiheizi/enjoy_player/issues/439)
**Supersedes**: [011-craft-studio-redesign](../../../specs/011-craft-studio-redesign/spec.md)

---

## 1. Problem

Language learners often can't speak fluently **not because their skills are poor, but because they don't have enough to say** — they've never expressed their daily thoughts in the target language. The Craft feature's true job is to let learners capture authentic daily thoughts and turn them into idiomatic, rehearseable target-language audio — building a personal "things I can say" library.

The current Craft screen has four problems:

1. **Text-first input** — The default is a paste box. Thoughts come as speech; voice should be the hero entry point.
2. **Tool-oriented, not thought-oriented** — Two separate panels (Translate + Synthesize) force an operator mindset instead of a thinker mindset.
3. **Fixed style, no personalization** — Translation applies a fixed style suffix. The AI should understand the user's input, extract their personal style, and reflect it in the output.
4. **No continuity** — After saving one item the flow resets completely. The flow should encourage rapid multi-capture.

### Job-to-be-done

> "When I have something I want to say, help me capture it by speaking in my native language, understand my real meaning and personal style, rewrite it the way I'd actually say it in my target language (idiomatically, not robotically), and turn it into audio I can rehearse — so I gradually build a personal library of things I can genuinely say."

---

## 2. Solution: Two Modes

The Craft screen (`/craft`) offers two modes via a segmented control in the app bar:

- **Express** (default) — voice-first linear flow for the core use case.
- **Advanced** — redesigned two-tool panel for power users with prepared text.

Both modes share the same `CraftController` state, AI services, persistence, and save path. Switching modes mid-session preserves work.

---

## 3. Express Mode — Screen-by-Screen Design

A single evolving vertical canvas. Content builds top-to-bottom; each stage appears after the previous one is confirmed. Previous stages collapse to summaries so the full context stays visible without overwhelming.

### 3.1. Stage 1 — Capture (voice-first)

**Idle state:**
- Large microphone button centered (72px phone / 88px tablet+).
- Language pair displayed above the button: "中 → 日本語" (muted, 11-12px).
- Encouraging copy below: "把你想说的话说出来" (15-17px, semibold) + subtitle "点击录音，用母语自然地说出你的想法" (11-12px, muted).
- "或输入文字" fallback link below (underlined, muted, 11-12px).
- Source language defaults to profile native language; target defaults to profile learning language.

**Recording state:**
- Mic button morphs into a red stop button (60px phone / 72px tablet+) with white square icon inside.
- Live timer above: "0:05" in red, 13-14px.
- Animated waveform bars between timer and stop button (16 bars, purple/light-purple, 44-52px tall area).
- Copy below stop button: "点击停止" (12-13px, muted).

**Text fallback:**
- Tapping "或输入文字" replaces the mic area with a text input field.
- Text entry skips ASR and feeds directly into Stage 2 (rewrite).

**After stop:**
- Audio bytes stored in state.
- ASR runs (`AsrService.transcribe()`), raw transcript appears (muted/italic).
- Flow auto-advances to Stage 2.

### 3.2. Stage 2 — Rewrite (idiomatic target language)

**Layout:**
- Raw transcript card on top: muted background (#1e1e38), italic, grey text (#555), 12-13px. Label "你的原话" (10-11px, uppercase, dark grey).
- Target text card below: purple label "日本語で言うと…" (10-11px, uppercase, #6c5ce7), editable text field (background #252545, border #3a3a5a, 13-14px, line-height 1.6-1.8).
- Style chip below target card: rounded pill, "风格: Auto ✨ ▾" (11-12px). Collapsible to reveal: literal / natural / casual / formal / simplified / detailed / custom.
- Three action buttons in a row (flex):
  - "↺ 重录" (outline, flex 1) — back to Stage 1.
  - "🔄 重新生成" (outline, flex 1) — re-run LLM with current style.
  - "🔊 生成音频 →" (purple filled, flex 1.3) — proceed to Stage 3.

**AI behavior:**
- Single LLM call (`ChatService.complete()`) takes raw native transcript → target-language rewrite.
- Default style "Auto": AI infers user's personal style from input, produces idiomatic spoken-form output preserving intent and personality.
- The "Auto" system prompt:

```
You are a language partner. The user recorded themselves thinking out loud
in [native]. Read what they said, understand their real meaning and the way
they naturally express themselves (their personal style, register, tone).
Then rewrite it in [target] the way they would actually say it if they were
a fluent [target] speaker — idiomatic, natural spoken form. Preserve their
intent and personality. Do NOT translate literally or robotically.
```

### 3.3. Stage 3 — Audio (preview + save)

**Layout:**
- Previous stages collapse to a summary block: language pair + style chip + truncated target text (muted, left-border accent, 10-12px).
- Preview player card (#252545, rounded 12px, padding 12-14px):
  - Play/pause circle (36-44px, purple #6c5ce7).
  - Progress bar (3-4px, purple fill over #3a3a5a track).
  - Time labels "0:03 / 0:08" (10-11px, muted).
  - Voice chip on right: "Yunxi ▾" (10-11px, muted background, collapsible to full voice picker).
- Two action buttons in a row (flex):
  - "💬 再说一句" (outline, flex 1) — save + reset to Stage 1 (rapid-capture loop).
  - "▶️ 立即练习 →" (purple filled, flex 1.2) — save + open player for shadow reading.

**After "再说一句":**
- Current item saved to library.
- Brief toast: "已保存到资料库".
- Stage 1 resets (mic re-activates).

**After "立即练习":**
- Current item saved to library.
- Navigate to player route with the new media item.

### 3.4. Responsive layout (Express)

All Express stages use a single centered column at every breakpoint:

| Breakpoint | Width | Content max-width | Gutter padding |
|------------|-------|-------------------|----------------|
| Phone (<600px) | 375px | full width | 14px |
| Tablet (600-899px) | 768px | 400-420px centered | 20px |
| Desktop (≥900px) | 1200px | 420-480px centered | 28px |

No side-by-side layout in Express — the flow is inherently vertical. Only max-width, font sizes, and whitespace scale up.

---

## 4. Advanced Mode — Redesigned Two-Tool Panel

For power users who have prepared target-language text, want manual control over each step, or want to synthesize directly.

### 4.1. Translate panel

- Source-language picker + target-language picker with swap button (⇄).
- Style dropdown (now includes "Auto ✨" as default option).
- Source text input (paste/type).
- Translate button (purple filled).
- After translation: editable result field, Copy button, Re-translate button, "Send to synthesis" button.

### 4.2. Synthesize panel

- Language picker (defaults to target from Translate).
- Full voice picker (Azure Neural voices filtered by language, as chips: "Nanami ♀", "Keita ♂", etc.).
- Text input (pre-filled from Translate via "Send to synthesis").
- Synthesize button.
- After synthesis: inline preview player (play/pause/seek), Re-synthesize button, Save to library button.

### 4.3. Responsive layout (Advanced)

| Breakpoint | Layout |
|------------|--------|
| Phone (<600px) | Stacked vertically: Translate card → ⬇ arrow → Synthesize card |
| Tablet (600-899px) | Side-by-side: Translate (left) \| Synthesize (right) |
| Desktop (≥900px) | Side-by-side, wider cards, max-width 560px centered |

---

## 5. Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Two modes | Express (default) + Advanced | Express serves voice-first thought-capture; Advanced serves power users with prepared text. Same controller, same save path. |
| Default input (Express) | Voice (mic), text as fallback | Thoughts come as speech. |
| Flow structure (Express) | Linear evolving canvas | Guided progression + full context; previous stages collapse to summaries. |
| AI pipeline (Express) | Single LLM call: raw native → idiomatic target | No separate native-refine step — faster, less friction. |
| Default style | "Auto" — AI infers user's personal style | Output mirrors the learner's own voice in the target language. |
| Other styles | literal, natural, casual, formal, simplified, detailed, custom | Power-user override. |
| Voice picker | Collapsed chip in Express; full chips in Advanced | Most users accept the default. |
| After-save | "再说一句" (loop) / "立即练习" (player) | Encourages library-building. |
| Naming | Keep "Craft" — route `/craft`, badge, storage key `craft` | Backward compatible. |
| Mode toggle | Segmented control in app bar | Lightweight, no extra route. |
| Breakpoints | <600px phone, 600-899px tablet, ≥900px desktop | Matches existing app responsive patterns (ADR-0055). |

---

## 6. Implementation Overview

### 6.1. Domain layer (`lib/features/craft/domain/`)

**New**: `craft_stage.dart`
```dart
enum CraftStage { capture, rewrite, audio, done }
```

**New/extend**: `craft_mode.dart`
```dart
enum CraftScreenMode { express, advanced }
```

**Modify**: `translation_style.dart` — add `auto` as first/default:
```dart
enum TranslationStyle {
  auto,        // AI infers user's style
  literal, natural, casual, formal, simplified, detailed, custom;
}
```

**Modify**: `craft_job_state.dart` — add:
- `CraftScreenMode screenMode`
- `CraftStage stage`
- `Uint8List? capturedAudioBytes`
- `String? rawTranscript`
- `bool isCapturing`, `bool isTranscribing`

**Keep unchanged**: `azure_voice.dart`, `word_boundary_segmenter.dart`, `transcript_timestamp_estimator.dart`, `wav_duration.dart`, `craft_request.dart`, `craft_failure.dart`.

### 6.2. Application layer (`lib/features/craft/application/craft_controller.dart`)

New methods for Express:
- `setScreenMode(CraftScreenMode mode)`
- `startCapture()` / `stopCapture()` — manages `AudioRecorder` (16kHz mono WAV, reusing shadow-reading's `RecordConfig`).
- `transcribeAndRewrite()` — ASR → ChatService (Auto style) → target text.
- `generateAudio()` — TTS auto-invoked after rewrite confirm.
- `saveAndPractice()` / `saveAndCaptureNext()` — save then navigate or reset.

Keep existing for Advanced: `translate()`, `synthesize()`, `useTranslatedText()`, `setSourceText()`, `setStyle()`, etc.

New provider: `craftAsrProvider` → wraps `AsrService`.

### 6.3. Data layer (`lib/features/craft/data/`)

**New**: `craft_asr_service_transcriber.dart` — `CraftTranscriber` wrapping `AsrService.transcribe()`.

**Keep**: `craft_tts_service_synthesizer.dart`, `craft_translation_service_translator.dart`.

### 6.4. Presentation layer (`lib/features/craft/presentation/`)

**Rewrite**: `craft_screen.dart` — app bar with segmented control, body switches Express/Advanced.

**New (Express)**: `express_flow.dart`, `capture_stage.dart`, `rewrite_stage.dart`, `audio_stage.dart`.

**New (Advanced)**: `advanced_tools.dart`, `translate_panel.dart`, `synthesize_panel.dart`.

**Keep/refactor**: `voice_picker.dart`, `style_picker.dart` (add "Auto" option).

**Remove/deprecate**: `translate_tool.dart`, `synthesize_tool.dart`.

### 6.5. Persistence — no schema change

`MediaLibraryRepository.importCraftedFromText()` unchanged. Express flow stores:
- `sourceText` = raw native transcript.
- `sourceLanguage` = native language.
- learning language + transcript = target rewrite + word-boundary timeline.
- `sourceFlag` = `'craft-express'`.

### 6.6. Localization (`lib/l10n/app_en.arb`, `app_zh.arb`)

New keys: mode labels, stage labels, capture/record copy, rewrite confirm, generate audio, practice now, say something else, Auto style label, type-instead fallback, recording permission/errors.

---

## 7. What Stays the Same

- Entry point: Import chooser → "Craft from text" → `/craft` route.
- Feature name: "Craft" (route, badge, storage key).
- AI infrastructure: `AsrService`, `ChatService`, `TtsService`, BYOK resolution, sign-in/credits.
- Persistence: `importCraftedFromText`, dedupe, delete, library badge.
- Word-boundary transcript generation, echo/shadow-reading integration.
- `record` package + microphone permission (already used in shadow reading).
- Failure UX patterns (calm, actionable, no raw exceptions).
- Breakpoints: <600px / 600-899px / ≥900px (ADR-0055).

---

## 8. Out of Scope

- Local / on-device AI for ASR, translation, or TTS.
- Background music, video compositing — audio only.
- Cloud sync of BYOK secrets.
- Translation/TTS history as separate tabs.
- Chunked synthesis for very long inputs (v1 truncates at 5,000 characters).
- Draft persistence when navigating back before saving.
