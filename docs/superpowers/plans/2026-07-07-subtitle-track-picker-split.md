# Subtitle Track Picker Split — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split `lib/features/transcript/presentation/subtitle_track_picker_sheet.dart` (1253 LOC) into 5 focused modules + a slimmed sheet, with no behavior/API change and a new smoke widget test.

**Architecture:** Pure code motion grouped by dependency layer: helpers (pure fns) → primitives (`MetaChip`) → tiles → sections → actions → slimmed sheet. Underscore-private symbols that must cross file boundaries become plain-named feature-internal symbols (Dart `_` is file-scoped). Convention is separate library files with explicit `package:enjoy_player/...` imports (no `part of`).

**Tech Stack:** Dart / Flutter / flutter_riverpod. Design spec: [`docs/superpowers/specs/2026-07-07-subtitle-track-picker-split-design.md`](../specs/2026-07-07-subtitle-track-picker-split-design.md).

---

## File Structure

All under `lib/features/transcript/presentation/`:

| File | Responsibility |
|---|---|
| `subtitle_track_picker_helpers.dart` | Pure functions + `PickerSection` enum + `kExpandedTrackListMaxHeight` const. No widgets. |
| `subtitle_track_picker_primitives.dart` | `MetaChip` shared visual primitive. |
| `subtitle_track_picker_tiles.dart` | `TrackOptionTile<T>`, `NoneOptionTile`. |
| `subtitle_track_picker_sections.dart` | `CollapsibleTrackSection`, `SelectionSummary`. |
| `subtitle_track_picker_actions.dart` | `SubtitleActionsSection`. |
| `subtitle_track_picker_sheet.dart` (slimmed) | Public API: enum, `showSubtitleTrackPicker`, `SubtitleTrackPickerSheet` + state. |

New test: `test/features/transcript/subtitle_track_picker_sheet_test.dart`.

Rename map (underscore → shared):
- `_sheetHorizontalPadding` → `sheetHorizontalPadding`
- `_trackOptionPadding` → `trackOptionPadding`
- `_trackPickerRadioTheme` → `trackPickerRadioTheme`
- `_trackLabel` → `trackLabel`
- `_findTrack` → `findTrack`
- `_providerLabel` → `providerLabel`
- `_providerBadgeColors` → `providerBadgeColors`
- `_kExpandedTrackListMaxHeight` → `kExpandedTrackListMaxHeight`
- `_PickerSection` → `PickerSection`
- `_MetaChip` → `MetaChip`
- `_CollapsibleTrackSection` → `CollapsibleTrackSection`
- `_SelectionSummary` → `SelectionSummary`
- `_TrackOptionTile` → `TrackOptionTile`
- `_NoneOptionTile` → `NoneOptionTile`
- `_SubtitleActionsSection` → `SubtitleActionsSection`

Symbols that stay underscore-private (only used within their own file): none — every extracted widget/helper is referenced from the sheet file.

---

### Task 1: Extract `subtitle_track_picker_helpers.dart`

**Files:**
- Create: `lib/features/transcript/presentation/subtitle_track_picker_helpers.dart`
- Modify: `lib/features/transcript/presentation/subtitle_track_picker_sheet.dart`

- [ ] **Step 1: Create helpers file** with `sheetHorizontalPadding`, `trackOptionPadding`, `trackPickerRadioTheme`, `trackLabel`, `findTrack`, `providerLabel`, `providerBadgeColors`, `kExpandedTrackListMaxHeight`, `PickerSection` enum. Required imports: `dart:ui` (Color), `package:flutter/material.dart`, `package:enjoy_player/core/theme/enjoy_tokens.dart`, `package:enjoy_player/features/transcript/domain/transcript_track.dart`, `package:enjoy_player/l10n/app_localizations.dart`.
- [ ] **Step 2: Update sheet file** — remove moved declarations, add `import 'package:enjoy_player/features/transcript/presentation/subtitle_track_picker_helpers.dart';`, replace `_sheetHorizontalPadding`→`sheetHorizontalPadding`, `_trackOptionPadding`→`trackOptionPadding`, `_trackPickerRadioTheme`→`trackPickerRadioTheme`, `_trackLabel`→`trackLabel`, `_findTrack`→`findTrack`, `_providerLabel`→`providerLabel`, `_providerBadgeColors`→`providerBadgeColors`, `_kExpandedTrackListMaxHeight`→`kExpandedTrackListMaxHeight`, `_PickerSection`→`PickerSection`.
- [ ] **Step 3: Verify** — `dart format --output=none --set-exit-if-changed lib test && flutter analyze` (no errors). `flutter test` (existing tests pass).
- [ ] **Step 4: Commit** — `git add -A && git commit -m "refactor(transcript): extract subtitle_track_picker_helpers (#206)"`.

### Task 2: Extract `subtitle_track_picker_primitives.dart` (`MetaChip`)

**Files:**
- Create: `lib/features/transcript/presentation/subtitle_track_picker_primitives.dart`
- Modify: `lib/features/transcript/presentation/subtitle_track_picker_sheet.dart`

- [ ] **Step 1: Create primitives file** moving `_MetaChip` → `MetaChip`. Imports: `package:flutter/material.dart`, `package:enjoy_player/core/theme/enjoy_tokens.dart`.
- [ ] **Step 2: Update sheet file** — remove `_MetaChip` class, add import, replace `_MetaChip`→`MetaChip`.
- [ ] **Step 3: Verify** — `dart format ... && flutter analyze && flutter test`.
- [ ] **Step 4: Commit** — `git commit -m "refactor(transcript): extract MetaChip primitive (#206)"`.

### Task 3: Extract `subtitle_track_picker_tiles.dart`

**Files:**
- Create: `lib/features/transcript/presentation/subtitle_track_picker_tiles.dart`
- Modify: `lib/features/transcript/presentation/subtitle_track_picker_sheet.dart`

- [ ] **Step 1: Create tiles file** moving `_TrackOptionTile<T>` → `TrackOptionTile<T>` and `_NoneOptionTile` → `NoneOptionTile`. Imports: `package:flutter/material.dart`, `package:enjoy_player/core/theme/enjoy_tokens.dart`, `package:enjoy_player/features/transcript/domain/transcript_track.dart`, `package:enjoy_player/l10n/app_localizations.dart`, plus the helpers + primitives files.
- [ ] **Step 2: Update sheet file** — remove both classes, add tiles import, replace usages.
- [ ] **Step 3: Verify** — gates.
- [ ] **Step 4: Commit** — `git commit -m "refactor(transcript): extract track option tiles (#206)"`.

### Task 4: Extract `subtitle_track_picker_sections.dart`

**Files:**
- Create: `lib/features/transcript/presentation/subtitle_track_picker_sections.dart`
- Modify: `lib/features/transcript/presentation/subtitle_track_picker_sheet.dart`

- [ ] **Step 1: Create sections file** moving `_CollapsibleTrackSection` → `CollapsibleTrackSection` and `_SelectionSummary` → `SelectionSummary`. Imports: `package:flutter/material.dart`, `package:enjoy_player/core/theme/enjoy_tokens.dart`, `package:enjoy_player/features/transcript/domain/transcript_track.dart`, `package:enjoy_player/l10n/app_localizations.dart`, helpers, primitives.
- [ ] **Step 2: Update sheet file** — remove both classes, add sections import, replace usages.
- [ ] **Step 3: Verify** — gates.
- [ ] **Step 4: Commit** — `git commit -m "refactor(transcript): extract collapsible sections (#206)"`.

### Task 5: Extract `subtitle_track_picker_actions.dart`

**Files:**
- Create: `lib/features/transcript/presentation/subtitle_track_picker_actions.dart`
- Modify: `lib/features/transcript/presentation/subtitle_track_picker_sheet.dart`

- [ ] **Step 1: Create actions file** moving `_SubtitleActionsSection` → `SubtitleActionsSection`. Imports: `package:flutter/material.dart`, `package:enjoy_player/core/theme/enjoy_tokens.dart`, `package:enjoy_player/l10n/app_localizations.dart`, `transcript_busy_action.dart`.
- [ ] **Step 2: Update sheet file** — remove the class, add actions import, replace usages.
- [ ] **Step 3: Verify** — gates.
- [ ] **Step 4: Commit** — `git commit -m "refactor(transcript): extract subtitle actions section (#206)"`.

### Task 6: Add smoke widget test

**Files:**
- Create: `test/features/transcript/subtitle_track_picker_sheet_test.dart`

- [ ] **Step 1: Write the test** mirroring `transcript_fetch_ui_test.dart`'s harness, pumping `SubtitleTrackPickerSheet(presentation: dialog)` with overrides for `allTranscriptsForMediaProvider`, `transcriptFetchCtrlProvider`, `activeTranscriptIdProvider`, `secondaryTranscriptIdProvider`, `videoRowForMediaProvider`, `playerControllerProvider`. Two cases: empty → `noTranscriptHint` shows, no `CollapsibleTrackSection`; one track → primary + translation headers render.
- [ ] **Step 2: Run** — `flutter test test/features/transcript/subtitle_track_picker_sheet_test.dart`. Expected: both pass.
- [ ] **Step 3: Full gates** — `dart format ... && flutter analyze && flutter test`.
- [ ] **Step 4: Commit** — `git commit -m "test(transcript): smoke widget test for SubtitleTrackPickerSheet (#206)"`.

### Task 7: Final verification + push + PR

- [ ] **Step 1: Confirm LOC targets** — `subtitle_track_picker_sheet.dart` < 750 lines; each new file < 300 lines (`wc -l`).
- [ ] **Step 2: Full gates green** — `dart format --output=none --set-exit-if-changed lib test && flutter analyze && flutter test`.
- [ ] **Step 3: Push** — `git push -u origin refactor/split-subtitle-track-picker-206`.
- [ ] **Step 4: Open PR** with `gh pr create` body referencing "Closes #206", summarizing the 5-file dependency-layer split, the corrected `_MetaChip` placement, and the new smoke test. Note the agentic-threat warning on the issue (manual-review disclaimer).
