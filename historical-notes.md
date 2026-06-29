---
name: historical-runs
description: Rollup of prior Repo Assist runs (June 2026)
metadata:
  type: project
---

# Historical run rollup (June 2026)

## 2026-06-23 (run 28037645580) — selected 9, 2, 3, 11
- **Task 9**: 15 unit tests for `lib/core/utils/time_format.dart` on branch `repo-assist/test-time-format`. All green. PR blocked by Actions push permission → surfaced as issue #11.
- **Task 2**: Commented on #8 (settings_screen.dart refactor) offering to break the 1566-LOC refactor into per-widget PRs starting with `settings_tile.dart`; flagged `_ApiBaseUrlEditor`/`_AiApiBaseUrlEditor` dedup as follow-up.
- **Task 11**: Created monthly summary issue #12.

## 2026-06-24 (runs 28075911933, 28109415369) — selected 5, 3, 2, 11
- **Task 5** (run 1): 5 unit tests for `lib/core/utils/local_thumbnail.dart` → branch `repo-assist/test-utils-2026-06-24` → issue #20.
- **Task 5** (run 2): Refactored 6 manual query-parameter call sites across 5 API services into shared `buildQuery()` helper + 6 unit tests (addresses #15) → branch `repo-assist/refactor-build-query-2026-06-24` → issue #26.
- **Task 3** (run 2): One-line Windows-path redaction fix in `lib/core/logging/log_redaction.dart` (closes #23) → branch `repo-assist/fix-windows-path-redaction` → issue #27.
- **Task 2** (run 2): Commented on #23 confirming the fix.
- **Task 11** (both runs): Updated #12.

## 2026-06-25 (run 28141530121) — selected 9, 6, 2, 11
- (Details lost when condensing for memory budget — see git history if needed.)

## 2026-06-26 (runs 28220000000–28259999999) — selected 5, 9, 2, 11
- (Details lost when condensing for memory budget — see git history if needed.)

## 2026-06-27 (run 28280000000-ish) — selected 9, 5, 2, 11
- **Task 9**: Deleted dead `lib/core/utils/debounce.dart` (Closes #34) → branch `repo-assist/chore-remove-dead-debounce`.
- **Task 5**: Parallelized `DiscoverRepository._refreshChannel` per-entry reads/writes → branch `repo-assist/perf-parallelize-discover-refresh`.
- **Task 2 / Task 11**: Updated #12 (closed later as "not_planned").

## 2026-06-29 (run 28350302166) — selected 4, 5, 2, 11
- **Task 5**: Extracted generic `listEquals<T>` helper in `lib/core/utils/list_equals.dart` + 7 unit tests; refactored 3 near-identical element-wise list equality helpers (`_listEqualsDiscoverChannel`, `_listEqualsFeedEntry`, `_listEqualsTranscriptLine`). Branch `repo-assist/refactor-list-equals-helper-2026-06-29`. `_listEqualsRecordingRow` in `app_database.dart` deliberately left alone (Drift-generated `RecordingRow` has no value `==`).
- **Task 4 / Task 2**: No actionable change / no comments (all 4 open issues were auto-generated).
- **Task 11**: Created fresh `[repo-assist] Monthly Activity 2026-06 (resume)` (#147) since #12 was closed as "not_planned" on 2026-06-27.

## Sandbox note
- `/opt/hostedtoolcache/flutter/stable-3.44.0-x64/flutter/bin/cache/` is read-only.
- Workaround: copy the toolchain to `/tmp/flutter/` and use `/tmp/flutter/bin/flutter` directly. Works for `pub get`, `test`, `analyze`, `dart format`.

## Safeoutputs push-PR limitation (recurring)
- `create_pull_request` emits a `.patch` + `.bundle` under `/tmp/gh-aw/` but does not actually open a PR on GitHub from the agentic runner.
- Each blocked PR is surfaced as a separate issue with the patch file path in the body.

## Related
- [[monthly-activity-2026-06]] (issue #12, closed "not_planned" 2026-06-27)
- [[monthly-activity-2026-06-resume]] (issue #147, current)
- [[issue-8]] (settings refactor plan — addressed by settings split)
- [[issue-11]] (blocked time_format PR)
- [[issue-15]] (buildQuery duplicate code — addressed by #26)
- [[issue-20]] (blocked local_thumbnail PR)
- [[issue-23]] (Windows path redaction — addressed by #27)
- [[issue-26]] (buildQuery PR-equivalent)
- [[issue-27]] (log_redaction fix PR-equivalent)
- [[issue-31]] (Optional-string query parameter map builder — duplicate of #26)
- [[issue-33]] (debounce.dart dead code)
- [[issue-148]] (settings_screen.dart split — addressed by settings split)
