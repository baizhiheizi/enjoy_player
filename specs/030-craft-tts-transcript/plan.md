# Implementation Plan: Craft TTS Transcript Quality

**Branch**: `030-craft-tts-transcript` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/030-craft-tts-transcript/spec.md`

## Summary

Improve Craft’s synthesis→transcript path so Azure (and other) word timings segment into clean practice cues (no leading punctuation; prefer sentence breaks). When word timings are missing or the segmenter emits no valid lines, **save audio with a blank transcript** and rely on the player’s existing STT generate flow—**stop writing proportional duration estimates**. Add light discoverability for generate/replace-via-STT. Forced alignment and TTS vendor switches are out of scope.

## Technical Context

**Language/Version**: Dart 3.x / Flutter (stable channel per repo)

**Primary Dependencies**: Flutter, Riverpod, Drift (`AppDatabase`), existing Craft (`CraftController`, `word_boundary_segmenter`), library repository (`importCraftedFromText` / `updateCraftedFromText`), transcript empty state + `launchAsrGeneration`, ARB l10n

**Storage**: Existing Drift `Audios` + `Transcripts`; no schema migration. Blank = **no primary transcript row** (or delete on update), not a fabricated `timelineJson`

**Testing**: `flutter test` (domain segmenter + controller/repo blank-vs-solid paths), `flutter analyze`, `bash .github/scripts/validate_ci_gates.sh --fix` before push; no codegen expected unless new `@Riverpod` annotations appear

**Target Platform**: Android, iOS, macOS, Windows, Linux (no web). Word timings today: Android/Windows Azure plugin; iOS/macOS/OpenAI BYOK typically blank→STT

**Project Type**: Cross-platform Flutter desktop/mobile app

**Performance Goals**: Segmenter on typical Craft paragraphs (&lt;500 chars / &lt;~200 tokens) &lt; 5ms; Craft save wall time regression ≤10% vs prior (SC-005); no heavy work in UI `build`

**Constraints**: Exact practice text when solid transcript saved; never call STT during Craft save; no forced alignment; single `media_kit` ownership unchanged; no `print()`; domain logic stays Flutter-free

**Scale/Scope**: Segmenter + Craft save policy + library import/update blank handling + optional dismissible hint + unit tests + `docs/features/craft.md` + ADR-0063

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Plan response |
|-----------|--------|---------------|
| I. Architecture | Pass | Segmenter/estimator policy in `lib/features/craft/domain`; save orchestration in `craft_controller`; persistence blank/solid in `library_repository`; STT via existing transcript/ASR presentation—no new cross-feature shortcuts |
| II. Testing | Pass | Unit tests for punctuation attachment, sentence preference, solid gate, blank when empty timings; repo/controller tests for omit/delete transcript; widget optional for hint if non-trivial |
| III. UX consistency | Pass | Reuse `TranscriptEmptyState` + `launchAsrGeneration`; ARB for any new hint; update `docs/features/craft.md` |
| IV. Performance | Pass | Pure CPU segmenter; budget above; no network on save for transcript fabrication |
| V. Documentation | Pass | ADR-0063 (blank when not solid; supersedes estimator-as-default behavior from Craft import era); feature doc update |
| Flutter Quality Gates | Pass | `validate_ci_gates.sh --fix`, analyze, test; no web; no new `Player()` |

**Post-design re-check**: Pass — contracts are domain/repo/UI affordance boundaries only; no unjustified new modules.

## Project Structure

### Documentation (this feature)

```text
specs/030-craft-tts-transcript/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── README.md
│   ├── craft-transcript-builder.md
│   ├── craft-save-blank-transcript.md
│   └── stt-discoverability.md
└── tasks.md             # /speckit-tasks (not this command)
```

### Source Code (repository root)

```text
lib/features/craft/
  domain/word_boundary_segmenter.dart      # punct merge + sentence-prefer breaks
  domain/transcript_timestamp_estimator.dart  # stop using on Craft save (may remain for tests/other or deprecate)
  application/craft_controller.dart        # solid→timeline / else null blank
  presentation/*                           # optional post-save / audio-stage hint

lib/features/library/data/library_repository.dart
  # importCraftedFromText / updateCraftedFromText: omit or delete transcript when blank

lib/features/transcript/presentation/
  transcript_empty_state.dart              # already owns generate CTA
  transcript_panel.dart                    # empty lines → empty state

lib/features/asr/presentation/asr_generation_launcher.dart  # unchanged API

lib/l10n/app_en.arb
lib/l10n/app_zh.arb
lib/l10n/app_zh_CN.arb

docs/features/craft.md
docs/decisions/0063-craft-blank-transcript-without-solid-timings.md
docs/decisions/README.md

test/features/craft/domain/word_boundary_segmenter_test.dart
test/features/craft/application/…          # save solid vs blank
test/features/library/…                    # import/update omit transcript
```

**Structure Decision**: Stay inside existing Craft + library + transcript features. No new top-level package. Estimator removed from Craft save path only (do not invent a second TTS stack).

## Complexity Tracking

> No constitution violations requiring justification.
