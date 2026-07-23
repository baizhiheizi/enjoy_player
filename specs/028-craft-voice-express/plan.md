# Implementation Plan: Craft Voice-Express Redesign

**Branch**: `028-craft-voice-express` | **Date**: 2026-07-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/028-craft-voice-express/spec.md`

## Summary

Redesign the Craft screen into a dual-mode experience: **Express** (default, voice-first linear flow — capture → rewrite → audio) and **Advanced** (redesigned two-tool panel). The Express flow adds ASR voice capture (reusing the `record` package from shadow reading), a single LLM rewrite call with a new "Auto" style that infers the user's personal voice, automatic TTS generation, and a rapid-capture loop. Both modes share one `CraftController` state, the same AI infrastructure (AsrService, ChatService, TtsService), and the same persistence path (`importCraftedFromText`). No schema changes — only UI, domain, application, and data-layer extensions within `lib/features/craft/`.

## Technical Context

**Language/Version**: Dart ^3.12, Flutter (latest stable per `.github/flutter-version`)

**Primary Dependencies**: Flutter (Material 3), `flutter_riverpod` (^2.5 with `@riverpod` codegen), `record` (^7.0.0 — already in pubspec for shadow reading), `media_kit` (player engine, not used in Craft), Azure Speech SDK (`packages/azure_speech`), Drift (persistence)

**Storage**: Drift / SQLite via `AppDatabase` — `Audios` + `Transcripts` tables. No schema migration needed; `importCraftedFromText` already accepts a `sourceFlag` string.

**Testing**: `flutter test` — unit tests for controller/domain logic, widget tests for presentation. Existing test harness at `test/features/craft/` with `_FakeTranslator`, `_FakeSynthesizer`, `_FakeLibraryRepository` fakes.

**Target Platform**: Android, iOS, macOS, Windows, Linux (no web)

**Project Type**: mobile-app + desktop-app (Flutter cross-platform)

**Performance Goals**: Express flow (capture → rewrite → audio) for a ~30s recording completes in ≤45s on a normal connection (QR-005). UI stays responsive during ASR/LLM/TTS calls (heavy work off main isolate).

**Constraints**: Single `media_kit` Player (not applicable — Craft doesn't own a player). No `print()` — use `logNamed`. All persistence via Drift DAOs. No Flutter web. BYOK-aware AI resolution. Microphone permission already granted for shadow reading (no new permission flow).

**Scale/Scope**: ~20 new/modified Dart files within `lib/features/craft/`. 1 ADR. ~30 new l10n keys (en + zh). ~15 new/updated test cases.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Architecture and Code Quality** | PASS | All changes stay within `lib/features/craft/{application,data,domain,presentation}`. Domain models are plain Dart (Freezed/immutable). Persistence flows through Drift DAOs via `importCraftedFromText`. Riverpod `Notifier` + `NotifierProvider` orchestrate state. No feature-to-feature shortcuts — Craft accesses AI services through `ai_services.dart` providers. |
| **II. Testing Defines the Contract** | PASS | Controller logic (capture → transcribe → rewrite → synthesize → save loop) requires unit tests with fake ASR/translator/synthesizer/repo. Widget tests for the Express flow state transitions and the Advanced/Express mode toggle. Existing test harness extended with `_FakeTranscriber`. |
| **III. User Experience Consistency** | PASS | New UI reuses `EnjoyButton`, `EnjoyTappableSurface`, `enjoySegmentedButtonStyle`, `EnjoyPageKind.form` layout, `Haptics`, ARB localization. All new strings in `app_en.arb` + `app_zh.arb`. `docs/features/craft.md` updated. |
| **IV. Performance Is a Requirement** | PASS | ≤45s Express flow target stated. ASR audio file write and WAV duration decode run off main isolate (via `compute` or existing async patterns). LLM/TTS calls are async by nature. Generation counter prevents stale-result UI. |
| **V. Documentation and Traceability** | PASS | New ADR for voice-first dual-mode + "Auto" style decision. `docs/features/craft.md` updated. This plan references all file paths. |
| **Flutter Quality Gates** | PASS | `dart run build_runner build` after Riverpod annotation changes. `flutter analyze` + `flutter test` + `check_dart_format` + `check_codegen_drift` before push. No `media_kit` Player instantiation. No `print()`. No web targets. |

**Gate result**: All principles pass. No violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/028-craft-voice-express/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── craft-controller-contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks — NOT created here)
```

### Source Code (repository root)

```text
lib/features/craft/
├── domain/
│   ├── craft_job_state.dart        # EXTEND: add screenMode, stage, capturedAudioBytes, rawTranscript, isCapturing, isTranscribing
│   ├── translation_style.dart      # EXTEND: add TranslationStyle.auto as first/default
│   ├── craft_screen_mode.dart      # NEW: enum CraftScreenMode { express, advanced }
│   ├── craft_stage.dart            # NEW: enum CraftStage { capture, rewrite, audio, done }
│   ├── craft_transcriber.dart      # NEW: abstract interface for ASR transcription
│   ├── craft_failure.dart          # EXTEND: add CraftAsrFailure, CraftEmptyTranscriptFailure
│   ├── azure_voice.dart            # KEEP
│   ├── craft_mode.dart             # KEEP (existing CraftMode enum, used for sourceFlag)
│   ├── craft_request.dart          # KEEP
│   ├── craft_synthesizer.dart      # KEEP
│   ├── craft_translator.dart       # KEEP
│   ├── transcript_timestamp_estimator.dart  # KEEP
│   ├── wav_duration.dart           # KEEP
│   └── word_boundary_segmenter.dart # KEEP
├── application/
│   └── craft_controller.dart       # EXTEND: add Express methods (startCapture, stopCapture, transcribeAndRewrite, generateAudio, saveAndPractice, saveAndCaptureNext, setScreenMode)
├── data/
│   ├── craft_asr_service_transcriber.dart  # NEW: CraftTranscriber wrapping AsrService.transcribe()
│   ├── craft_translation_service_translator.dart  # KEEP (extend for auto style prompt)
│   └── craft_tts_service_synthesizer.dart  # KEEP
└── presentation/
    ├── craft_screen.dart           # REWRITE: app bar with segmented control, body switches Express/Advanced
    ├── express_flow.dart           # NEW: orchestrates the 3-stage evolving canvas
    ├── capture_stage.dart          # NEW: mic button, text fallback, waveform animation
    ├── rewrite_stage.dart          # NEW: raw transcript card + editable target + style chip + actions
    ├── audio_stage.dart            # NEW: preview player + voice chip + save/loop actions
    ├── advanced_tools.dart         # NEW: container for redesigned two-tool layout
    ├── translate_panel.dart        # NEW: redesigned Translate panel (replaces translate_tool.dart)
    ├── synthesize_panel.dart       # NEW: redesigned Synthesize panel (replaces synthesize_tool.dart)
    ├── style_picker.dart           # EXTEND: add "Auto" option
    ├── voice_picker.dart           # KEEP
    ├── translate_tool.dart         # DEPRECATE (remove after panels ship)
    └── synthesize_tool.dart        # DEPRECATE (remove after panels ship)

test/features/craft/
├── application/
│   └── craft_controller_test.dart  # EXTEND: add Express flow tests
├── domain/
│   ├── craft_screen_mode_test.dart # NEW: enum sanity
│   └── craft_stage_test.dart       # NEW: enum sanity
└── presentation/
    └── craft_tools_test.dart       # UPDATE: test Express/Advanced toggle

docs/decisions/
└── 0049-craft-voice-express-dual-mode.md  # NEW ADR

lib/l10n/
├── app_en.arb                      # EXTEND: ~30 new keys
└── app_zh.arb                      # EXTEND: ~30 new keys

docs/features/
└── craft.md                        # UPDATE: document new Express/Advanced behavior
```

**Structure Decision**: Single-project feature-first layout. All changes within `lib/features/craft/` and supporting `docs/` + `lib/l10n/`. No new packages, no cross-feature coupling.

## Complexity Tracking

> No Constitution Check violations — table intentionally empty.
# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command; its definition describes the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]

**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]

**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]

**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]

**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]

**Project Type**: [e.g., library/cli/web-service/mobile-app/compiler/desktop-app or NEEDS CLARIFICATION]

**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]

**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]

**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

[Gates determined based on constitution file]

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
