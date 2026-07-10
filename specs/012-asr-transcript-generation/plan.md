# Implementation Plan: ASR Transcript Generation

**Branch**: `012-asr-transcript-generation` | **Date**: 2026-07-10 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/012-asr-transcript-generation/spec.md`

## Summary

Wire the existing `AsrCapability` / `AsrService` abstraction into the
transcript panel and subtitle picker so learners can **generate** and
**re-generate** a `source: 'ai'` transcript track from a local audio or
video file. Azure Speech is the default backend (Enjoy API for signed-in
learners, BYOK for self-managed credentials); OpenAI-compatible Whisper
is supported through the existing BYOK flow. FFmpeg is reused for audio
extraction from video; the resulting `TranscriptLine[]` is persisted
through `TranscriptRepository.upsertAsrGeneratedTrack` with a
deterministic id so re-generation upserts in place.

Detailed technical decisions, alternatives, and reuse rationale:
[`research.md`](research.md). Entity shapes: [`data-model.md`](data-model.md).
Public contracts: [`contracts/`](contracts/). Validation scenarios:
[`quickstart.md`](quickstart.md).

## Technical Context

**Language/Version**: Dart ≥ 3.5 (matches Flutter stable channel pinned by
the repo).

**Primary Dependencies** (already in `pubspec.yaml`):
- `azure_speech` (path: `packages/azure_speech`) — Azure Speech SDK bridge
- `ffmpeg_kit_flutter_new` (path: `packages/ffmpeg_kit_flutter_new`) —
  audio / video probe + extraction on Android, iOS, macOS
- `http: ^1.4.0` — BYOK OpenAI Whisper
- `path: ^1.9.1`, `path_provider: ^2.1.5` — temp file handling for FFmpeg
  and Azure WAV
- `drift: ^2.31.0`, `drift_flutter: ^0.2.8`, `sqlite3_flutter_libs` —
  `transcripts` and `media_*` tables
- `flutter_riverpod: ^3.3.1`, `riverpod_annotation: ^4.0.2` — new
  `AsrGenerationController`
- `flutter_secure_storage: ^10.2.0` — BYOK key vault
- `crypto: ^3.0.6`, `uuid: ^4.5.1` — deterministic `enjoyTranscriptId`
- `flutter_localizations`, `intl` — ARB localization

**Storage**: Drift `AppDatabase` for the resulting `source: ai` row and
the media row language field; secure storage already used for BYOK keys;
temp files for FFmpeg output (deleted in `finally`).

**Testing**: `flutter test` (unit, widget), `dart run build_runner build`
when Riverpod / Drift annotations change.

**Target Platform**: Android, iOS, macOS, Windows. **Web is out of
scope** per product platform policy and constitution.

**Project Type**: Flutter native mobile/desktop app.

**Performance Goals**:
- SC-002: ≤ 60 s end-to-end for a 5-minute media file on desktop.
- SC-003: no sustained UI jank during extraction / recognition on
  supported desktop and mobile targets; playback + transcript panel
  remain responsive throughout the in-flight job (heavy work runs
  off the UI isolate via `Isolate.run` for the Windows FFmpeg path
  and `ffmpeg_kit_flutter_new` worker threads on mobile / macOS).
- QR-004: extraction / recognition must not block UI frames.

**Constraints**:
- QR-001: no vendor HTTP calls in UI / feature widgets; reuse
  `AsrCapability` only.
- QR-003: ARB localization for every user-visible string; reuse
  `EnjoyTappableSurface` / `TranscriptBusyButton`.
- QR-006: log via `logNamed` only; never `print()`.
- Constitution § Flutter Quality Gates: validate_ci_gates +
  build_runner before push.
- The `webapp` reference path `~/dev/enjoy/apps/web` is not present on
  this machine; the implementation pattern is documented in `research.md`
  § 9 and matches existing Flutter conventions. No decision is blocked
  on that reference.

**Scale/Scope**:
- One new feature folder: `lib/features/asr/{application,data,domain}`.
- One new repository helper on `TranscriptRepository`.
- Two widget parameter additions (`TranscriptEmptyState.onGenerate`,
  `SubtitleActionsSection.onGenerate`).
- Localised strings added to `lib/l10n/app_en.arb` and
  `lib/l10n/app_zh_CN.arb` (full list in `tasks.md`).
- One new transient in-memory entity (`AsrGenerationJob`) and one new
  pure-function entity (`AsrTimelineBuilder`).
- No Drift schema migration, no platform-channel additions.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1
design — both pre- and post-design evaluations below pass.*

### I. Architecture and Code Quality

- New code lives under `lib/features/asr/{application,data,domain}` and
  reuses `lib/features/ai/` (existing capability) and
  `lib/features/transcript/` (existing repository, picker, empty state).
  **Pass.**
- Domain models (`AsrGenerationJob`, `AsrTimelineBuilder`,
  `AsrGeneratedTrackInput`, `AsrAudioExtractionException`) are UI-free
  Flutter code that does not import `package:flutter/material.dart`.
  **Pass.**
- Persistence flows through `TranscriptDao.upsert`; no raw SQL in
  feature widgets. **Pass.**
- Riverpod is the orchestration mechanism
  (`AsrGenerationController`); no new mutable global singleton is
  introduced (in-flight jobs live in a controller-scoped `Map`). **Pass.**
- No `print()` calls; logs use `logNamed('asr...')` following the
  existing `ai.azure.asr.transcribe` style. **Pass.**
- No `media_kit` `Player()` instantiation; the controller never touches
  the player surface. **Pass.**

### II. Testing Defines the Contract

Required automated tests (test plan in `research.md` § 10):
- `asr_audio_extractor_test.dart` — happy path, missing FFmpeg, no
  audio track, oversized file.
- `asr_timeline_segmentation_test.dart` — word-level, segment-level,
  plain-text fallback, empty input.
- `asr_generation_controller_test.dart` — state machine, in-flight
  guard, cancel-on-restart, deterministic upsert (1 row after 3
  re-generations).
- `asr_language_propagation_test.dart` — auto-detected language
  overrides media row language; same-language no-op.
- `transcript_repository_generate_asr_test.dart` — repository helper.
- `transcript_empty_state_generate_action_test.dart` (widget).
- `subtitle_track_picker_generate_action_test.dart` (widget).

`dart run build_runner build` will run when the new
`AsrGenerationController` is annotated with `@riverpod`. **Pass.**

### III. User Experience Consistency

- All new strings land in `app_en.arb` and `app_zh_CN.arb`; friendly
  error keys per `contracts/asr-capability.md` § 4. **Pass.**
- Reuses `TranscriptBusyButton` (empty state CTA) and
  `TranscriptBusyListTile` (picker action). **Pass.**
- Icon-only / busy states follow the existing patterns. **Pass.**
- Feature behavior changes will update `docs/features/transcript.md`
  (and a new `docs/features/asr.md` if the docs layout warrants — to be
  decided in `tasks.md`). **Pass.**

### IV. Performance Is a Requirement

- Performance goals stated above (SC-002 / SC-003 / QR-004).
- Audio extraction:
  - Android / iOS / macOS: `ffmpeg_kit_flutter_new` (already runs off
    the UI isolate).
  - Windows: `Process.run` against bundled `ffmpeg.exe` wrapped in
    `Isolate.run` for the duration probe (mirrors
    `azure_assessment_wav_normalizer.dart`).
- Recognition: `AsrCapability.transcribe` is already async; no main
  isolate work.
- Persist: `TranscriptDao.upsert` is single-row, fast.
- Cancellation: `AsrGenerationController.generateTranscript` returns a
  `Future` that respects a per-`mediaId` cancellation token
  (`Completer<void>`); cancellation flips phase to `cancelled` and the
  temp file is deleted in `finally`. No overlapping writes.
- Verification: PR includes the SC-002 evidence (60 s 5-min target on
  desktop) or a documented manual verification path. **Pass.**

### V. Documentation and Traceability

- `docs/features/transcript.md` will be updated in the same change to
  describe the Generate / Re-generate CTA.
- New `docs/features/asr.md` page documents the controller, the
  segmentation builder, the audio extractor, and the failure-mode map.
- No new ADR is required (reuses existing capabilities, language
  catalog, repository, FFmpeg, and Azure Speech package). A short ADR
  note (`docs/decisions/NNNN-asr-transcript-generation.md`) will record
  the **decision to reuse** rather than re-implement — keeping the
  governance trail visible per Constitution Principle V. **Pass.**
- Agent guidance: `AGENTS.md` Hard Rules already cover supported
  platforms, no `print()`, Drift, `media_kit` ownership — no update
  needed. **Pass.**

## Project Structure

### Documentation (this feature)

```text
specs/012-asr-transcript-generation/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── asr-capability.md
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── features/
│   ├── ai/                 # unchanged — provides AsrCapability / AsrService
│   ├── transcript/         # touched: empty state + picker action callbacks,
│   │                         one new repository helper, language mapper reuse
│   └── asr/                # NEW
│       ├── application/
│       │   ├── asr_generation_controller.dart  (@riverpod)
│       │   ├── asr_generation_controller.g.dart (generated)
│       │   ├── asr_generation_job.dart          (AsrGenerationJob)
│       │   ├── asr_long_media_dialog.dart       (pre-flight confirm)
│       │   └── asr_failure_messages.dart        (l10n key → message)
│       ├── data/
│       │   └── asr_audio_extractor.dart         (FFmpeg + raw audio)
│       └── domain/
│           ├── asr_timeline_builder.dart         (pure: AsrResult → lines)
│           └── asr_audio_extraction_failure.dart (enum + exception)
├── core/
│   ├── application/        # language catalog — unchanged (reused)
│   ├── ids/                # enjoyTranscriptId — unchanged (reused)
│   └── ...
├── data/
│   ├── db/                 # Drift — no schema change
│   ├── files/              # FfmpegMediaProbe — unchanged (reused)
│   └── subtitle/           # TranscriptLine + parser — unchanged (reused)
└── l10n/
    ├── app_en.arb          # new keys: asr*, generateTranscript*
    └── app_zh_CN.arb       # mirror translations

test/
├── features/
│   ├── ai/                 # unchanged
│   ├── transcript/         # existing tests still pass; new generate-asr tests
│   └── asr/                # NEW: extractor, segmentation, controller, language
└── ...

docs/
├── features/
│   ├── transcript.md       # updated: Generate / Re-generate section
│   └── asr.md              # NEW
└── decisions/
    └── NNNN-asr-transcript-generation.md  # NEW: "reuse existing capabilities"
```

**Structure Decision**: Single new feature folder `lib/features/asr/`
for the orchestration, builder, and extractor; thin widget-parameter
additions in `lib/features/transcript/presentation/`; one new
repository method on `TranscriptRepository`. No new platform package,
no Drift migration, no `lib/core/` additions.

## Complexity Tracking

> *No Constitution Check violations. This section is intentionally empty.*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| — | — | — |