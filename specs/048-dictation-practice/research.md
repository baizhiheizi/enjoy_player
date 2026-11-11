# Phase 0 Research: Dictation Practice (Voice Retelling & Text Input)

**Feature**: [spec.md](spec.md) | **Date**: 2026-11-11

## 1. Lens & Practice Loop Invariant (`dictation ⇒ loop`)

- **Decision**: Align `PlayerLens` and `PlayerInteractions` with the web player's `usePracticeMode` contract (`~/Projects/enjoy/apps/web/src/hooks/player/use-practice-mode.ts`):
  - `PlayerLens.listen`: `echoActive == false && hideText == false`
  - `PlayerLens.echo`: `echoActive == true && hideText == false`
  - `PlayerLens.dictate`: `hideText == true` (with invariant `echoActive == true` whenever a session with transcript lines is active)
  - `playerLensFrom(echoActive, hideText)` returns `PlayerLens.dictate` when `hideText` is `true`, else `PlayerLens.echo` when `echoActive` is `true`, else `PlayerLens.listen`.
  - Transition table in `PlayerInteractions.selectLens` / `toggleEcho` / `toggleBlur`:
    - `Listen → Dictate`: activates `EchoMode` on the active transcript line (falling back to line `0` if the playhead is before the first cue) and activates `TranscriptBlurMode`.
    - `Echo → Dictate`: preserves the current `EchoMode` region (`startLineIndex..endLineIndex`) and activates `TranscriptBlurMode`.
    - `Dictate → Echo`: preserves the current `EchoMode` region and deactivates `TranscriptBlurMode`.
    - `Dictate → Listen` or `Echo → Listen`: deactivates both `EchoMode` and `TranscriptBlurMode`.
- **Rationale**: Because `EchoMode.active` is `true` during Dictate mode, the existing `EchoEnforcer` (loop seek clamping and pause-and-rewind at segment end), `EchoLoopEdgeRow` (`+ line` / `−` buttons), loop expansion/contraction hotkeys (`[` `]` `{` `}`), line navigation (`prevLine`, `nextLine`, `replayLine`, `seekToLine`), and `PlayerDock` Echo/Recording controls all work in Dictate mode without duplicating loop state.
- **Alternatives considered**:
  - Keeping a separate `DictationLoopState` provider parallel to `EchoMode`: rejected because it would duplicate `EchoEnforcer`, hotkey bindings, and `EchoRegionMergedCard` virtualization, and would require manual state copying when switching between Echo and Dictate.

## 2. Shared Recording Capture & ASR Transcription Pipeline

- **Decision**: Keep `ShadowReadingPanel` (and its `ShadowTakeStore` + `ShadowReadingHotkeyBus`) mounted inside `EchoRegionMergedCard` in both `Echo` and `Dictate` modes, and add an `onTakePersisted(RecordingRow row)` callback hook on `ShadowReadingPanel`:
  - Whether a recording is triggered from the **Dictation Panel**'s Record button, the bottom **PlayerDock** Record button, or the global **`R`** shortcut, it pulses `ShadowReadingHotkeyBus` and runs through the single `ShadowReadingPanel` capture lifecycle.
  - When capture stops, `ShadowTakeStore.stopAndPersist` writes `{appSupport}/recordings/{uuid}.wav`, inserts the `RecordingRow` into `recordings` via `RecordingDao`, and enqueues cloud sync (`SyncEntityType.recording`).
  - `ShadowTakesInLoopRow` (`ShadowTakeSummaryRow` + `ShadowTakesListPanel` + `triggerRecordingAssessment`) remains visible in Dictate mode so learners can replay takes (`G`), score pronunciation (`V` / `Score`), and inspect takes identically in Dictate and Echo modes.
  - When `PlayerLens.dictate` is active, `onTakePersisted` forwards the saved `RecordingRow` to `DictationController.transcribeAndCheckTake(row)`:
    1. Reads the WAV bytes from `row.localPath` on a background isolate / async file read.
    2. Calls `AsrService.transcribe(AsrRequest(audioBytes: bytes, filename: 'dictation.wav', mimeType: 'audio/wav', language: resolvedLanguage))`.
    3. On non-empty transcript: computes word diff against the loop's `referenceText`, persists a `DictationRow` via `DictationDao`, and transitions the loop's `DictationBand` and `DictationPanel` to the checked state.
    4. On `CreditsFailure` or other error (or empty transcript): keeps `row` in the takes list, sets a typed failure state on `DictationController` with a one-tap **Retry transcription** action for `row`, and surfaces the standard `AppNotice` (with the `/subscription` CTA on `CreditsFailure`).
- **Rationale**: Guarantees 100% recording unification between Dictate and Echo modes with a single `MicRecorder` owner, zero risk of concurrent recorder conflicts on Windows Media Foundation, and zero lost recordings if ASR fails.
- **Alternatives considered**:
  - Recording to a temporary buffer in `DictationPanel` and only saving to `recordings` after ASR succeeds: rejected because an ASR network/credits failure would lose the learner's spoken take, violating FR-007/FR-010 and SC-005.

## 3. Word-Level Diff & Accuracy Algorithm (`dictation_diff.dart`)

- **Decision**: Implement a pure Dart port of `~/Projects/enjoy/apps/web/src/lib/dictation/diff.ts` and `@enjoy/design`'s `dictation-band.tsx` helpers in `lib/features/dictation/domain/dictation_diff.dart`:
  - **Normalization (`dictationWordOf`, `dictationWords`)**:
    - Lowercase, strip apostrophes (`['’]`) so contractions (`don't` → `dont`) stay a single word of the same letter count, and strip punctuation (`[.,!?;:"()[\]{}<>—–-]`).
    - Split on whitespace and discard empty tokens (so standalone dashes `—` are not counted as words).
  - **Word-Level LCS Diff (`dictationChanges`)**:
    - Compute Longest Common Subsequence (LCS) over the normalized reference word list and normalized user input word list, coalescing adjacent equal, removed (missed), and added (extra) words into `List<DictationChange>`.
  - **Statistics (`dictationStatsFromChanges`)**:
    - `correctWords`: total words in unchanged chunks.
    - `missedWords` (`deletions`): total words in `removed` chunks.
    - `extraWords` (`insertions`): total words in `added` chunks.
    - `totalWords`: `correctWords + missedWords`.
    - `accuracy`: `denominator = totalWords + extraWords`; `denominator > 0 ? ((correctWords / denominator) * 100).round() : 0`.
  - **Word Block Widths & Karaoke Windows (`dictationBlockWidth`, `buildDictationBandWords`)**:
    - Block width: `max(3, lettersWithoutPunctuation.length) * 9.5` logical pixels.
    - Word windows: reuse each loop line's `TranscriptLine.timeline` (`wordMediaWindowMs`) for covered words, and spread uncovered words proportionally by word character weight over the remaining line duration (matching `~/Projects/enjoy/apps/web/src/lib/transcript/word-windows.ts`).
- **Rationale**: Matches the web app's exact scoring and visual diff contract with zero external package dependencies and deterministic O(N×M) execution (< 0.1 ms for typical 5–50 word loops).
- **Alternatives considered**:
  - Character-level diffing: rejected because dictation feedback in language learning operates at word granularity and must match the `dictations` schema (`correctWords`, `missedWords`, `extraWords`).

## 4. Dictation Persistence & Practised Line Indicators

- **Decision**:
  - Extend `DictationDao` (`lib/data/db/daos/dictation_dao.dart`) with `watchByEchoRegion` and `listByEchoRegion` using the same half-open interval overlap rule as `RecordingDao.watchByEchoRegion`:
    `targetType == query.targetType && targetId == query.targetId && language == query.language && referenceStartMs < echoEndMs && (referenceStartMs + referenceDurationMs) > echoStartMs`, ordered by `createdAt DESC`.
  - Expose `echoRegionDictationsProvider` and `dictationsForTargetProvider` in `lib/features/dictation/application/dictation_providers.dart`.
  - Update `transcriptLineRecordingCountsProvider` (`lib/features/transcript/application/transcript_line_recording_counts_provider.dart`) and `transcript_recording_counts.dart` so lines overlapped by at least one `DictationRow` also register as practised (minimum count `1` when `recordingCount == 0`), lighting up the practised dot in `TranscriptTileChrome`, `SentenceRuler`, and `DockReadout`.
- **Rationale**: Reuses the existing `dictations` table (`idx_dictations_target` already indexed in Drift schema v16) with no schema migration required.
- **Alternatives considered**:
  - Adding a new database table or modifying `dictations` columns: unnecessary because `lib/data/db/tables/dictations.dart` already contains all required columns.
