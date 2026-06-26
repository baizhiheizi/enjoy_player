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

## 2026-06-24 (run 28075911933) — selected 5, 3, 2, 11
- **Task 5**: 5 unit tests for `lib/core/utils/local_thumbnail.dart` on branch `repo-assist/test-utils-2026-06-24`. PR blocked → surfaced as issue #20.
- **Task 11**: Updated #12.

## 2026-06-24 run 2 (run 28109415369) — selected 5, 3, 2, 11
- **Task 5**: Refactored 6 manual query-parameter call sites across 5 API services into a shared `lib/data/api/query_params.dart#buildQuery()` helper + 6 unit tests. Addresses #15. Branch `repo-assist/refactor-build-query-2026-06-24`. Patch emitted → surfaced as issue #26.
- **Task 3**: One-file fix in `lib/core/logging/log_redaction.dart`. Closes #23. Branch `repo-assist/fix-windows-path-redaction`. Patch emitted → surfaced as issue #27. The pre-existing test in `log_redaction_test.dart` now passes.
- **Task 2**: Commented on #23 confirming the one-line fix.
- **Task 11**: Updated #12.

## Sandbox note
- `/opt/hostedtoolcache/flutter/stable-3.44.0-x64/flutter/bin/cache/` is read-only.
- Workaround: copy the toolchain to `/tmp/flutter/` and use `/tmp/flutter/bin/flutter` directly. Works for `pub get`, `test`, `analyze`, `dart format`.

## Safeoutputs push-PR limitation (recurring)
- `create_pull_request` emits a `.patch` + `.bundle` under `/tmp/gh-aw/` but does not actually open a PR on GitHub from the agentic runner.
- Each blocked PR is surfaced as a separate issue with the patch file path in the body.

## Related
- [[monthly-activity-2026-06]] (issue #12)
- [[issue-8]] (settings refactor plan)
- [[issue-11]] (blocked time_format PR)
- [[issue-15]] (buildQuery duplicate code — addressed by #26)
- [[issue-20]] (blocked local_thumbnail PR)
- [[issue-23]] (Windows path redaction — addressed by #27)
- [[issue-26]] (buildQuery PR-equivalent)
- [[issue-27]] (log_redaction fix PR-equivalent)
- [[issue-31]] (Optional-string query parameter map builder — duplicate of #26)
- [[issue-33]] (debounce.dart dead code)
