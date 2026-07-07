# Design: Split `subtitle_track_picker_sheet.dart` (resolves #206)

**Date:** 2026-07-07
**Issue:** [#206 — Split `subtitle_track_picker_sheet.dart` (1253 LOC) into focused modules](https://github.com/baizhiheizi/enjoy_player/issues/206)
**Branch:** `refactor/split-subtitle-track-picker-206`
**Type:** Pure mechanical refactor (no behavior or API change)

## Goal

Split the 1253-LOC `lib/features/transcript/presentation/subtitle_track_picker_sheet.dart`
into focused, single-responsibility modules that are each easy to navigate and test,
while keeping the public API and behavior identical.

## Constraints (non-negotiable)

1. **Public API unchanged.** `showSubtitleTrackPicker`, `SubtitleTrackPickerSheet`, and
   `SubtitleTrackPickerPresentation` stay exported from `subtitle_track_picker_sheet.dart`
   with unchanged signatures. The single external caller
   (`lib/features/player/presentation/widgets/transport/transport_cc_fullscreen.dart`)
   requires zero changes.
2. **No behavior change.** Pure code motion — no logic edits, no widget tree changes.
3. **Follow the codebase idiom: separate library files with explicit imports.**
   The repo has no `part of` usage outside generated `.g.dart` files. Convention
   ([`docs/conventions.md`](../../conventions.md) § Imports) prefers
   `package:enjoy_player/...` paths for cross-layer presentation imports.

## Audit findings (what the automated issue got wrong)

The issue's structural analysis is accurate (1253 lines; the 8 types/helpers it lists
are real). However its **grouping** has a cohesion bug:

- The issue places `_MetaChip` into `subtitle_track_picker_actions.dart` alongside
  `_SubtitleActionsSection`.
- But `_MetaChip` is **never used by** `_SubtitleActionsSection`. It is a shared visual
  primitive consumed by `_SelectionSummary` and `_TrackOptionTile`.
- That grouping would force the tiles/sections files to import the actions file purely
  for a chip, inverting the natural dependency direction and coupling unrelated widgets.

## Approach: group by dependency layer

Split into 5 new/slimmed files, each a clean dependency layer with no cycles.

```
subtitle_track_picker_helpers.dart        ← pure functions + enum + const (no widgets)
        │
        ▼
subtitle_track_picker_primitives.dart     ← _MetaChip (shared visual primitive)
        │
        ▼
subtitle_track_picker_tiles.dart          ← _TrackOptionTile<T>, _NoneOptionTile
subtitle_track_picker_sections.dart       ← _CollapsibleTrackSection, _SelectionSummary
subtitle_track_picker_actions.dart        ← _SubtitleActionsSection (leaf)
        │
        ▼
subtitle_track_picker_sheet.dart          ← slimmed: enum, launcher, main state
```

### File contents

| File | Contents | ~LOC |
|---|---|---|
| `subtitle_track_picker_helpers.dart` | `sheetHorizontalPadding`, `trackOptionPadding`, `trackPickerRadioTheme`, `trackLabel`, `findTrack`, `providerLabel`, `providerBadgeColors`, `kExpandedTrackListMaxHeight`, `PickerSection` enum | ~120 |
| `subtitle_track_picker_primitives.dart` | `MetaChip` | ~40 |
| `subtitle_track_picker_tiles.dart` | `TrackOptionTile<T>`, `NoneOptionTile` | ~150 |
| `subtitle_track_picker_sections.dart` | `CollapsibleTrackSection`, `SelectionSummary` | ~265 |
| `subtitle_track_picker_actions.dart` | `SubtitleActionsSection` | ~90 |
| `subtitle_track_picker_sheet.dart` (slimmed) | `SubtitleTrackPickerPresentation` enum, `showSubtitleTrackPicker`, `SubtitleTrackPickerSheet` + `_SubtitleTrackPickerSheetState` | ~700 |

### Visibility / naming

Dart's `_` prefix is **file-scoped**, so symbols that must be shared across the new files
cannot stay underscore-private. The shared helpers and extracted widgets are renamed to
plain (non-underscore) names. They remain implementation details of the feature folder —
not exported beyond it. Truly-private widgets keep `_` where they stay within one file
(none in this split — every extracted widget is referenced by the sheet).

## Test coverage (insurance)

This file currently has **zero test coverage**. Add a small smoke widget test:

**New file:** `test/features/transcript/subtitle_track_picker_sheet_test.dart`

Mirrors the harness in `transcript_fetch_ui_test.dart`. Two cases:

1. **Empty tracks** → the `noTranscriptHint` localised string renders; no
   `CollapsibleTrackSection` is present.
2. **One track** → primary (`subtitlesPrimary`) + translation (`subtitlesTranslation`)
   section headers render, and the track label appears.

Provider overrides: `allTranscriptsForMediaProvider`, `transcriptFetchCtrlProvider`,
`activeTranscriptIdProvider`, `secondaryTranscriptIdProvider`,
`videoRowForMediaProvider`, `playerControllerProvider`.

## Verification gates (issue acceptance criteria)

Run after **each** file extraction, and once at the end:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Acceptance checklist (from issue):

- [ ] `subtitle_track_picker_sheet.dart` is under 750 lines
- [ ] Each new file is under 300 lines
- [ ] All new files have a single, clearly-named responsibility
- [ ] `showSubtitleTrackPicker` and `SubtitleTrackPickerSheet` retain their public API
- [ ] `dart format --output=none --set-exit-if-changed lib test` is clean
- [ ] `flutter analyze` is clean
- [ ] `flutter test` passes (including the new smoke test)

## Implementation order

One file at a time, running the three verification gates between steps so a regression
is localized:

1. Create `subtitle_track_picker_helpers.dart` (move pure fns + enum + const; update sheet).
2. Create `subtitle_track_picker_primitives.dart` (move `_MetaChip` → `MetaChip`).
3. Create `subtitle_track_picker_tiles.dart` (move `_TrackOptionTile<T>`, `_NoneOptionTile`).
4. Create `subtitle_track_picker_sections.dart` (move `_CollapsibleTrackSection`, `_SelectionSummary`).
5. Create `subtitle_track_picker_actions.dart` (move `_SubtitleActionsSection`).
6. Slim `subtitle_track_picker_sheet.dart` (remove moved code, add imports).
7. Add `test/features/transcript/subtitle_track_picker_sheet_test.dart`.

## Out of scope

- No behavior changes, no API changes.
- No extraction of `_SubtitleTrackPickerSheetState` action handlers
  (`_importFile`, `_extractEmbedded`, `_refreshCloud`, `_deleteTrack`, `_toggleSection`,
  `_collapseSection`, `_buildSheetHeader`, `_buildTracksContent`, `_buildTrackListBody`).
  They belong with the picker state — moving them out would fragment cohesion. The
  actions *section widget* moves out; the action *handlers* stay.
- No new ADR — pure mechanical refactor with no architectural decision.
