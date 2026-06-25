---
name: historical-runs
description: Rollup of prior Repo Assist runs (June 2026) — kept compact to fit memory budget
metadata:
  type: project
---

# Historical run rollup (June 2026)

## Run 2026-06-23 (workflow run 28037645580) — selected 9, 2, 3, 11

- **Task 9**: 15 unit tests for `lib/core/utils/time_format.dart` (branch `repo-assist/test-time-format`). All green. PR blocked by Actions push permission → surfaced as issue #11.
- **Task 2**: Commented on #8 (settings_screen.dart refactor) offering to break the 1566-LOC refactor into per-widget PRs starting with `settings_tile.dart`; flagged `_ApiBaseUrlEditor`/`_AiApiBaseUrlEditor` dedup as follow-up.
- **Task 11**: Created monthly summary issue #12.

## Run 2026-06-24 (workflow run 28075911933) — selected 5, 3, 2, 11

- **Task 5**: 5 unit tests for `lib/core/utils/local_thumbnail.dart` (branch `repo-assist/test-utils-2026-06-24`). All green. PR blocked → surfaced as issue #20.
- **Task 11**: Updated #12.

## Run 2026-06-24 (run 2) (workflow run 28109415369) — selected 5, 3, 2, 11

- **Task 5**: Refactored 6 manual query-parameter call sites across 5 API services into a shared `lib/data/api/query_params.dart#buildQuery()` helper + 6 unit tests. Addresses #15. Branch `repo-assist/refactor-build-query-2026-06-24`. Patch emitted → surfaced as issue #26 (PR-equivalent).
- **Task 3**: One-file fix in `lib/core/logging/log_redaction.dart` (normalize `\` → `/` before `p.basename` so Windows paths shorten on POSIX hosts). Closes #23. Branch `repo-assist/fix-windows-path-redaction`. Patch emitted → surfaced as issue #27 (PR-equivalent). The pre-existing test in `log_redaction_test.dart` now passes on this branch.
- **Task 2**: Commented on #23 confirming the one-line fix.
- **Task 11**: Updated #12.

## Sandbox note

- `/opt/hostedtoolcache/flutter/stable-3.44.0-x64/flutter/bin/cache/` is read-only; `flutter` calls fail with `engine.stamp.tmp.PID: Read-only file system`.
- Workaround: copy the toolchain to `/tmp/flutter/flutter/` and use `/tmp/flutter/flutter/bin/flutter` directly. Works for `pub get`, `test`, `analyze`, `dart format`.

## Safeoutputs push-PR limitation (recurring)

- `create_pull_request` emits a `.patch` + `.bundle` under `/tmp/gh-aw/` but does not actually open a PR on GitHub from the agentic runner — Actions lacks `workflows` permission to push to the protected default branch, and direct `git push` is unauthenticated.
- The branch + commit are local; a maintainer is needed to open the PR via the suggested-actions list in #12. Each blocked PR is surfaced as a separate issue with the patch file path in the body.

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
