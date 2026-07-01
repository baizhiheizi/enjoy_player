---
name: historical-runs
description: Rollup of prior Repo Assist runs (June 2026)
metadata:
  type: project
---

# Historical run rollup (June 2026)

## 2026-06-23 → 2026-06-27 — see git history
- 06-23 (run 28037645580): 15 time_format unit tests → blocked PR #11.
- 06-24 (2 runs): local_thumbnail tests (#20), buildQuery refactor (#26), log_redaction fix (#27).
- 06-25: see git history.
- 06-26 (2 runs): see git history.
- 06-27: deleted dead debounce.dart (Closes #34) → `repo-assist/chore-remove-dead-debounce`; parallelized `_refreshChannel`.

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
