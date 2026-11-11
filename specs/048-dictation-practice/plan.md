# Implementation Plan: Dictation Practice (Voice Retelling & Text Input)

**Branch**: `048-dictation-practice` | **Date**: 2026-11-11 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/048-dictation-practice/spec.md`

## Summary

Complete the **Dictate** practice mode in Enjoy Player so it operates as a loop-bound lens on the transcript (reusing Echo mode's single- and multi-line loop region controls), masks reference words behind karaoke-animated word blocks (`DictationBand`) while unchecked, and supports both **Voice Retelling (录音复述)** (default: capturing a shared shadow-reading `RecordingRow` via `ShadowTakeStore`, transcribing via `AsrService`, and computing word-level diff) and **Text Input (文字输入)** (mirroring `~/Projects/enjoy` web `DictationPanel`). Recordings captured in Dictate mode are stored as standard shadow-reading takes—playable (`G`), assessable (`Score` / `V`), and visible across both Dictate and Echo modes—while completed dictation checks are persisted to `dictations` (`DictationDao`) and surfaced in a `Previous Dictations` history section and per-line practiced indicators.

## Technical Context

**Language/Version**: Dart 3.11+ / Flutter 3.41+

**Primary Dependencies**: `flutter_riverpod` / `riverpod_annotation` (state orchestration), `drift` (`AppDatabase` DAOs: `DictationDao`, `RecordingDao`, `EchoSessionDao`), `record` (via existing `ShadowTakeStore`), `AsrService` (`lib/features/ai/application/ai_services.dart`)

**Storage**: Local SQLite via Drift (`dictations`, `recordings`, `echo_sessions` tables — no schema migration needed) + local WAV files in `{applicationSupport}/recordings/`

**Testing**: `flutter test` (unit tests for word diff, band word windows, DAO queries, lens transitions, and controller state; widget tests for `DictationBand`, `DictationPanel`, `DictationList`, and `EchoRegionMergedCard`)

**Target Platform**: Android, iOS, macOS, Windows, Linux (native desktop & mobile; no web target per ADR-0048)

**Project Type**: Cross-platform Flutter mobile/desktop application

**Performance Goals**:
- Word-level LCS diff + tokenization (`dictationChanges`, `dictationStatsFromChanges`): `< 1 ms` on the UI isolate for typical 1–5 line loops (5–100 words).
- WAV byte loading before ASR transcription: async file read off the frame build path so UI animations stay at 60/120 fps.
- Karaoke highlight in `DictationBand`: leaf-scoped position watching so playback ticks only repaint/rebuild the band blocks, never the full transcript list.
- Zero explanatory `//` comments in `lib/` and `test/` (enforced by project conventions).

**Constraints**:
- Single `MicRecorder` ownership per loop via `ShadowReadingPanel` / `ShadowTakeStore` (prevents Windows Media Foundation stale recorder issues).
- Zero raw SQL in presentation widgets; all persistence flows through `DictationDao` and `RecordingDao` (ADR-0002).
- All user-visible strings localized in `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`.

**Scale/Scope**: 1 new feature module (`lib/features/dictation/{domain,application,presentation}`), targeted updates to `player` lens transitions, `transcript` echo loop card / edge rows / practiced counts, `shadow_reading` take-persisted callback, `DictationDao`, and feature docs (`docs/features/echo-mode.md`, `docs/features/shadow-reading.md`).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Pre-Research Status | Post-Design Status | Notes |
|---|---|---|---|
| **I. Architecture and Code Quality** | ✅ PASS | ✅ PASS | Feature-first layout under `lib/features/dictation/{domain,application,presentation}`; pure domain diff/window logic free of Flutter; persistence strictly through `DictationDao` and `RecordingDao`; Riverpod providers for state. |
| **II. Testing Defines the Contract** | ✅ PASS | ✅ PASS | Unit tests cover `dictation_diff.dart`, `dictation_band_words.dart`, `DictationDao.watchByEchoRegion`, `DictationController`, `playerLensFrom`, and `PlayerInteractions`; widget tests cover `DictationBand`, `DictationPanel`, `DictationList`, and loop integration. |
| **III. User Experience Consistency** | ✅ PASS | ✅ PASS | Reuses Duet design tokens (`EnjoyThemeTokens`), `EnjoyButton`, `EnjoyPressable`, `Haptics`, existing `ShadowTakeSummaryRow` / `ShadowTakesListPanel`, and ARB localizations (`app_en.arb`, `app_zh.arb`). |
| **IV. Performance Is a Requirement** | ✅ PASS | ✅ PASS | O(N×M) word diff on short loop text (< 1 ms); O(D log D + L log D) binary-search window overlap for practised line counts; leaf consumer for `DictationBand` karaoke ticks. |
| **V. Documentation and Traceability** | ✅ PASS | ✅ PASS | Updates `docs/features/echo-mode.md` and `docs/features/shadow-reading.md` alongside code changes. |
| **Flutter Quality Gates** | ✅ PASS | ✅ PASS | Verification runs `bash .github/scripts/check_codegen_drift.sh --fix`, `bash .github/scripts/check_dart_format.sh --fix`, `flutter analyze`, and `flutter test`. |

## Project Structure

### Documentation (this feature)

```text
specs/048-dictation-practice/
├── spec.md              # Feature specification
├── plan.md              # This implementation plan
├── research.md          # Phase 0 research & architecture decisions
├── data-model.md        # Phase 1 data model & state transitions
├── quickstart.md        # Phase 1 verification & run guide
├── contracts/
│   └── dictation-ui-and-data-contract.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
lib/
├── data/
│   └── db/
│       └── daos/
│           └── dictation_dao.dart                          # Add watchByEchoRegion & listByEchoRegion
├── features/
│   ├── dictation/                                          # NEW feature module
│   │   ├── domain/
│   │   │   ├── dictation_diff.dart                         # Pure word tokenizer, LCS diff, accuracy stats
│   │   │   ├── dictation_band_words.dart                   # Word block widths & karaoke time windows
│   │   │   └── dictation_models.dart                       # DictationInputMode, DictationCheckResult, DictationFailure
│   │   ├── application/
│   │   │   ├── dictation_providers.dart                    # echoRegionDictationsProvider, dictationsForTargetProvider
│   │   │   └── dictation_controller.dart                   # Per-loop dictation state, text check, ASR transcription & retry, DB save
│   │   └── presentation/
│   │       ├── dictation_band.dart                         # Hidden karaoke word blocks (unchecked) & inline word diff + legend (checked)
│   │       ├── dictation_panel.dart                        # Voice Retelling / Text Input switcher, input/recording controls, score card
│   │       └── dictation_list.dart                         # Previous Dictations history selector & detail card for the loop region
│   ├── player/
│   │   ├── domain/
│   │   │   └── player_lens.dart                            # playerLensFrom: hideText -> dictate, echoActive -> echo, else listen
│   │   └── application/
│   │       ├── player_interactions.dart                    # Loop-preserving Listen <-> Echo <-> Dictate transitions
│   │       └── player_open_coordinator.dart                # Restore both echoMode and blurMode when session was saved in Dictate
│   ├── shadow_reading/
│   │   └── presentation/
│   │       ├── shadow_reading_panel.dart                   # Add optional onTakePersisted callback for Dictate ASR trigger
│   │       └── shadow_reading_panel_recording.dart         # Invoke onTakePersisted after stopAndPersist succeeds
│   └── transcript/
│       ├── domain/
│       │   └── transcript_recording_counts.dart            # Include dictation windows in practiced line counts
│       ├── application/
│       │   └── transcript_line_recording_counts_provider.dart
│       └── presentation/
│           ├── transcript_echo_region_merged_card.dart     # Render DictationBand in loop & DictationPanel + ShadowReadingPanel below
│           ├── transcript_echo_loop_edge_row.dart          # Mask edge row line text with TranscriptBlurText when Dictate is active
│           └── transcript_panel.dart                       # Show DictateHintPill only when needed or let loop card own Dictate UX
├── l10n/
│   ├── app_en.arb                                          # English dictation strings
│   └── app_zh.arb                                          # Chinese dictation strings

test/
├── features/
│   ├── dictation/
│   │   ├── domain/
│   │   │   ├── dictation_diff_test.dart
│   │   │   └── dictation_band_words_test.dart
│   │   ├── application/
│   │   │   └── dictation_controller_test.dart
│   │   └── presentation/
│   │       ├── dictation_band_test.dart
│   │       ├── dictation_panel_test.dart
│   │       └── dictation_list_test.dart
│   ├── player/
│   │   ├── domain/
│   │   │   └── player_lens_test.dart
│   │   └── player_interactions_class_test.dart
│   └── transcript/
│       └── transcript_echo_region_merged_card_test.dart
```

**Structure Decision**: Create a dedicated `lib/features/dictation/{domain,application,presentation}` module for dictation-specific domain logic (word diff, band word timing windows), state management (`DictationController`, region queries), and UI widgets (`DictationBand`, `DictationPanel`, `DictationList`), while integrating cleanly into the existing `EchoRegionMergedCard` and `ShadowReadingPanel` seams so loop controls and shadow-reading recordings are 100% shared.

## Complexity Tracking

No Constitution Check violations.
