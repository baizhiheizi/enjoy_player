# Implementation Plan: Craft Studio (Redesigned)

**Branch**: `011-craft-studio-redesign` | **Date**: 2026-07-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/011-craft-studio-redesign/spec.md`

## Summary

Redesign the Craft from text feature as a **full-screen route** with two tools — **Translate** (style presets, edit, copy, re-translate, "Use translated text" bridge) and **Synthesize** (Azure Neural voice picker, preview player, save with timestamped transcript). The entry remains in the import chooser. The infrastructure from spec 010 (`EnjoyTtsCapability`, `FileStorage.importBytes`, `AzureTokenCache` purpose: tts, `MediaLibraryRepository.importCraftedFromText`) is reused. New additions: translation style presets, Azure voice catalog, sentence-split timestamp estimation, and the full-screen UI replacing the bottom sheet.

## Technical Context

**Language/Version**: Dart `^3.12.0`, Flutter stable, Drift `^2.31.0`, Riverpod `^3.3.1`, Freezed `^3.0.0`.

**Primary Dependencies**: `flutter_riverpod`, `drift`, `azure_speech` (path package), `ai_sdk_dart` (+ OpenAI / Anthropic / Google for LLM BYOK), `go_router ^17.2.3`, `flutter_localizations`, `media_kit` (existing audio playback path only).

**Storage**: Reuses Drift `Audios` + `Transcripts` tables (no schema migration). Craft items store `provider = 'craft'`, `source = 'craft-translate' | 'craft-direct'`. Timestamped transcript uses existing `timelineJson` column with multiple `{text, start, duration}` entries (sentence-split).

**Testing**: `flutter_test` unit tests for timestamp estimator, voice catalog filter, translation style → prompt mapping, and controller state. Widget tests for the Craft screen layout, translate tool, and synthesize tool. Manual verification for Azure Speech SDK synthesis on each platform (platform-channel hop).

**Target Platform**: Android, iOS, macOS, Windows (no Flutter web).

**Project Type**: Flutter native mobile/desktop app.

**Performance Goals**: Translate ~200 chars in < 15 s; synthesize ~200 chars in < 20 s; save + open player in < 3 s; reopen saved item in < 1 s.

**Constraints**: Local-first (requires network for AI); Azure TTS only for v1; no `print()`; no new `Player()` instances; reuse existing shared UI primitives.

**Scale/Scope**: Typical input 200–3000 chars; cap at 5000; audio file 50–500 KB; single concurrent operation per tool.

## Constitution Check

### I. Architecture and Code Quality

- ✅ Craft screen lives in `lib/features/craft/presentation/`; controller in `application/`; domain types in `domain/`. Feature-first preserved.
- ✅ Persistence through Drift DAOs (`AudioDao`, `TranscriptDao`) via `MediaLibraryRepository`.
- ✅ Riverpod `Notifier` for state; no mutable global singletons.
- ✅ No new `Player()`; audio bytes written to disk, existing path plays.
- ✅ No `print()`; logging via `logNamed`.

### II. Testing Defines the Contract

- ✅ Unit tests: timestamp estimator, voice catalog filter, translation style presets, controller (translate/synthesize/save/failure/dedupe).
- ✅ Widget tests: Craft screen layout, translate tool (style picker, edit, copy, re-translate, "Use translated text"), synthesize tool (voice picker, preview, save).
- ✅ Manual verification: Azure Speech SDK synthesis on each platform.

### III. User Experience Consistency

- ✅ ARB localization for all new strings (en + zh + zh_CN).
- ✅ Reuses `showContentLanguagePicker`, `EnjoyButton`, `AppNotice`, `MediaCardTile` badge slot.
- ✅ Responsive: side-by-side on desktop, stacked on mobile.
- ✅ Docs: update `docs/features/library.md`, `docs/features/ai.md`, `docs/features/transcript.md`; revise ADR-0030.

### IV. Performance Is a Requirement

- ✅ Budgets stated (15 s translate, 20 s synthesize).
- ✅ Heavy work (file write, audio duration probe) off main isolate.
- ✅ Reopening saved items: < 1 s (no AI calls).

### V. Documentation and Traceability

- ✅ ADR-0030 revised to document full-screen + two-tool + voice picker + style presets.
- ✅ Feature docs updated.

## Project Structure

### Documentation (this feature)

```text
specs/011-craft-studio-redesign/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── checklists/requirements.md
```

### Source Code

```text
lib/
├── features/craft/
│   ├── domain/
│   │   ├── craft_mode.dart              # EXISTING (010) — reused
│   │   ├── craft_failure.dart           # EXISTING — extended
│   │   ├── craft_request.dart           # EXISTING — reused
│   │   ├── craft_job_state.dart         # EXISTING — extended (voice, style, preview)
│   │   ├── craft_synthesizer.dart       # EXISTING — reused
│   │   ├── craft_translator.dart        # EXISTING — reused
│   │   ├── translation_style.dart       # NEW — enum + prompt presets
│   │   ├── azure_voice.dart             # NEW — voice catalog + filter helper
│   │   └── transcript_timestamp_estimator.dart # NEW — sentence-split + proportional offsets
│   ├── data/
│   │   ├── craft_tts_service_synthesizer.dart  # EXISTING — reused
│   │   └── craft_translation_service_translator.dart # EXISTING — extended (style param)
│   ├── application/
│   │   └── craft_controller.dart        # EXISTING — rewritten for two-tool state
│   └── presentation/
│       ├── craft_screen.dart            # NEW — full-screen route (replaces craft_sheet.dart)
│       ├── translate_tool.dart          # NEW — translate panel
│       ├── synthesize_tool.dart         # NEW — synthesize panel
│       ├── voice_picker.dart            # NEW — Azure voice dropdown
│       └── style_picker.dart            # NEW — translation style dropdown
├── features/library/
│   ├── data/library_repository.dart     # EXISTING — extend for timestamped transcript
│   └── presentation/library_actions.dart # EXISTING — change onTap to push route
├── core/routing/
│   └── app_router.dart                  # EXISTING — add /craft route
└── l10n/
    └── app_en.arb, app_zh.arb, app_zh_CN.arb # EXTEND with new keys
```

**Structure Decision**: Replace `craft_sheet.dart` with `craft_screen.dart` as a full-screen pushed route. Split the UI into `translate_tool.dart` and `synthesize_tool.dart` as separate `ConsumerWidget`s composed on the screen. New domain types for translation styles, Azure voice catalog, and timestamp estimation.

## Complexity Tracking

No constitution violations.

| Concern | Approach |
|---------|----------|
| Full-screen route vs bottom sheet | Push a new `GoRouter` route `/craft` instead of `showEnjoySheet`. The import chooser's `onTap` calls `context.push('/craft')`. |
| Translation style presets | Port the 7-style enum from the web app; each style maps to a prompt suffix appended to the existing translation prompt template. |
| Azure voice catalog | Port ~40 voices from `azure-voices.ts` as a static Dart list; filter by base language code at runtime. |
| Timestamped transcript | Split text into sentences (regex on `.` `。` `!` `?` `！` `？`), distribute total audio duration proportionally by character count. Store as multi-entry `timelineJson`. |
| Two-tool state | Single `CraftController` with sub-state for translate (source/target lang, style, input, result, editing) and synthesize (language, voice, text, audio bytes, preview state). |
| Preview audio playback | Use an in-memory `just_audio` or `audioplayers` instance for the preview player; or use `media_kit` Player — but constitution says no new Player(). Use `audioplayers` package or raw `AudioPlayer` from the SDK. Actually: use the existing `media_kit` `Player` — but only in `MediaKitPlayerEngine` / `PlayerController`. Alternative: use HTML5 audio element via a lightweight plugin. **Decision: use `just_audio` package** for the preview player (not media_kit) — this avoids the single-player constraint. | 
