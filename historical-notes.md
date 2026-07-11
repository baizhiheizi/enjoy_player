---
name: historical-rollup-through-2026-07-09
description: Compact rollup of Repo Assist activity through 2026-07-09; older per-run notes were condensed for memory budget
metadata:
  type: project
---

# Historical Repo Assist Rollup through 2026-07-09

## 2026-06-23 → 2026-06-27 — Initial setup, refactors, tests
- Added time-format tests; commented on early refactor issues (#8, #23, #31, #39, #40, #44, #45).
- Created PR-equivalent branches for query construction, Windows path redaction, quantized position, dead `debounce.dart` removal (#34), and Discover refresh parallelization.

## 2026-06-29 — settings_screen split, listEquals helper
- Extracted a generic list-equality helper.
- Split `settings_screen.dart` from 1,605 LOC to 716 LOC and deduped API URL editors.
- Commented on #148.

## 2026-07-01 — workerLanguagePair helper, palette cache
- Extracted `resolveWorkerLanguagePair` (addresses #163).
- Implemented artwork palette cache invalidation by `path+size+mtime` (later merged by maintainer as PR #188).
- Commented on #151/#163.

## 2026-07-02 — hotkey tests, testing.md update
- Added hotkey-format tests and `docs/testing.md` hotkey layout notes.
- Added `enjoy_ids` deterministic-ID tests.
- Commented on #185.

## 2026-07-06 — #205 dedupe, transcript panel perf
- Branch `repo-assist/dedupe-format-duration-ms-2026-07-06` (commit `17d69e1`) — removed both private `_formatDurationMs`; switched 5 call sites; collapsed two redundant ternaries. `flutter test` 784/2/0. Addresses #205.
- Branch `repo-assist/perf-transcript-panel-chrome-select-2026-07-06` (commit `2304f4d`) — `transcript_panel.dart:77` switched to `select(playbackChromeOf)`; closes #189 backlog item. `flutter test` 784/2/0.

## 2026-07-07 — duplicate-code wave + .editorconfig
- Three substantive duplicate-code comments on #211/#212/#213.
- Branch `repo-assist/eng-add-editorconfig-2026-07-07` (commit `69c11e6`) — 44-line `.editorconfig` codifying project conventions. PR-fallback patch at `/tmp/gh-aw/0001-chore-editor-add-.editorconfig-matching-project-conv.patch` (2,614 bytes).

## 2026-07-08 — maintenance run
- Audited stale duplicate-code queue (#152–#154, #161, #162, #203, #204, #206) — all closed or completed by maintainer PRs (#222, #223, #225–#228, #242).
- No new comments or PRs.
- Refreshed #165 to remove merged items.

## 2026-07-09 — selector perf, monthly summary refresh
- Branch `repo-assist/perf-player-session-selectors-2026-07-09` (commit `ac0e21f`) — switched `transcript_panel.dart`, `subtitle_track_picker_sheet.dart`, `share_practice_poster_button.dart` to narrow `.select(...)` slices. Avoids rebuilds on playback clock ticks.
- Replaced body of #165 with current July format and concise suggested actions.

## Carried-over branches (all available locally via PR-fallback or remote)
- `repo-assist/test-time-format` (#11)
- `repo-assist/test-utils` (#20)
- `repo-assist/refactor-build-query-2026-06-24` (#26)
- `repo-assist/fix-windows-path-redaction-5c65346f188bda5f` (#27)
- `repo-assist/refactor-quantized-position-2026-06-25` (#33)
- `repo-assist/chore-remove-dead-debounce` (#34)
- `repo-assist/test-echo-region-bounds-2026-06-25`
- `repo-assist/refactor-list-equals-helper-2026-06-29`
- `repo-assist/split-settings-screen-2026-06-29` (#148)
- `repo-assist/refactor-worker-language-pair-2026-07-01` (#163)
- `repo-assist/perf-palette-cache-invalidation-2026-07-01` (#151 backlog item)
- `repo-assist/test-hotkey-format-2026-07-02`
- `repo-assist/docs-test-layout-hotkeys-2026-07-02`
- `repo-assist/dedupe-format-duration-ms-2026-07-06` (#205)
- `repo-assist/perf-transcript-panel-chrome-select-2026-07-06` (#189)
- `repo-assist/eng-add-editorconfig-2026-07-07`
- `repo-assist/perf-player-session-selectors-2026-07-09`

Live monthly issue: #165.