# ADR-0104: Local git hooks stay narrow; CI owns the heavy gates

**Status**: Accepted (2026-11-12)
**Related**: [docs/packaging.md § Git hooks](../packaging.md),
[docs/features/agentic-workflows.md](../features/agentic-workflows.md),
[.github/scripts/test_git_hooks.sh](../../.github/scripts/test_git_hooks.sh),
[.github/workflows/ci.yml](../../.github/workflows/ci.yml)

## Context

Two repo-local hooks were installed per clone with
`git config core.hooksPath .githooks`:

- `pre-commit` scanned the **entire staged diff** with five regexes, including a
  bare `[0-9a-f]{64}`. Every recorded trigger of that rule was a false positive:
  public sha256 checksums, an SHA-256-of-empty-string test fixture, gh-aw lock
  `frontmatter_hash` / `body_hash` values, and OCI image pins. Five commits
  (four distinct events) resorted to `git commit --no-verify`, and because the
  scanner read `-` deletion lines, a commit that merely **removed** a checksum
  was blocked too. Two successive masking patches (`sha256:`, then gh-aw hash
  keys) had already been added, with no end to the whack-a-mole in sight.
  A bypass habit makes the gate worthless.
- `pre-push` ran `check_dart_format.sh`, `check_codegen_drift.sh` (build_runner)
  and `flutter analyze` — ~15 s warm, ~40 s cold, up to 240 s on a poisoned
  incremental cache. All three already run in CI on every PR (`ci.yml`
  `Analyze & test`, `codegen_drift.yml`) and the repo intends them as required
  checks, though the `main: required checks` ruleset is currently disabled.
  `build_runner` also rewrites the working tree on every push and can delete
  checked-in generated files in an agent worktree, which the Codegen drift
  workflow explicitly warns about.

Neither hook is a server-side control: installation is manual and optional, and
`--no-verify` bypasses both. The repository has no self-hosted secret-scanning
workflow and no push protection. GitHub's GitGuardian integration reports a
`GitGuardian Security Checks` check run on PRs, but that is post-commit
detection — by the time it fires the key is already in git history and must be
rotated. The local scanner is therefore the only **pre-commit** credential
control.

## Decision

1. **Keep `pre-commit`, but scan only added lines.** `git diff --cached
   --unified=0` filtered to `^[+][^+]`. Deleted and context lines cannot leak a
   new secret. File names are read NUL-delimited (`-z`) so spaces are safe, and
   the loop is a pipeline rather than process substitution for Git Bash
   portability.
2. **Split the rules by confidence.** High-confidence shapes — `AKIA…`,
   `AWS_SECRET_ACCESS_KEY=` / `AWS_ACCESS_KEY_ID=`, `R2_SECRET_ACCESS_KEY=` /
   `PUBLISH_*SECRET*=`, `SPARKLE_DSA_PRIV_PEM_BASE64=`, and R2 endpoint tokens —
   block in **any** file, including tests, and run against the unmasked lines.
   The shape-only bare 64-hex rule blocks only outside `test/` and outside known
   digest contexts.
3. **Centralize the exemptions** instead of adding one mask per incident — and
   mask **the digest's hex value, never the whole line**: binaries / `*.lock` /
   example templates / the hook itself are skipped; `sha256:<64 hex>`, any
   `*hash` JSON key (`frontmatter_hash`, `body_hash`, `computedHash`),
   path-keyed JSON digest mappings, and `checksum=` / `digest=` assignments each
   mask only the hex they qualify. Generic keywords such as `fixture` are **not**
   exemptions, so `fixtureSecret = "<hex>"` stays blocked, and a bare 64-hex
   sharing a line with a real digest is still caught. `test/`, `skills-lock.json`
   and `.specify/integrations/*.manifest.json` are exempt from the shape rule as
   whole files (the high-confidence rules still run on them). A public digest
   therefore has a fix that does **not** require `--no-verify`.
4. **Reduce `pre-push` to `check_dart_format.sh` only** (~3 s), still skipped for
   docs/workflow-only pushes. CI runs codegen drift and analyze on every PR, so
   the local duplication buys only a few minutes of earlier feedback at the
   cost of working-tree rewrites and multi-minute stalls. `bash
   .github/scripts/validate_ci_gates.sh --fix` remains the full local mirror
   for anyone who wants the complete run before pushing.
5. **Add `.github/scripts/test_git_hooks.sh`**: 27 cases in throwaway git
   repositories covering blocked credentials (including inside `test/`),
   exempted digests and tool-generated manifests, the deleted-line regression,
   digest-plus-secret same-line regressions, stubs proving `pre-push` invokes
   only the format gate, and an assertion that the `changes` job's PATTERN
   matches `.githooks/pre-commit`, `.githooks/pre-push` and `lib/foo.dart`.
   Run it as a step in `ci.yml`'s `Analyze & test` job, and add `.githooks/` to
   that job's `changes` path pattern so hook-only PRs trigger it. The prefix
   branches of that pattern are deliberately left unanchored at the end; only
   the fully-named file branches carry `$`.

## Consequences

- Removing a checksum line, editing a test fixture, or refreshing a gh-aw lock
  file no longer needs `--no-verify`; high-confidence credential assignments are
  still blocked. Pushes no longer rewrite the working tree or wait on
  build_runner.
- The shape-only rule can still meet a new digest form. Extend the centralized
  exemption list, do not reach for `--no-verify`; the regression suite pins the
  known forms. Masks are value-scoped: never "simplify" one back into a
  whole-line deletion, which would let a bare secret hide next to a digest
  (two regression cases pin this).
- Because the `main: required checks` ruleset is currently disabled, a red CI
  check does not block a merge. Enabling it is the follow-up that makes "CI
  owns the heavy gates" load-bearing; until then `validate_ci_gates.sh --fix`
  is the way to catch codegen/analyze failures before pushing.
- Local hooks remain optional and bypassable, so they are **not** a substitute
  for a server-side control. GitGuardian detects leaks only after they are in
  history. Follow-up (not part of this change): enable the `main: required
  checks` ruleset, and evaluate GitGuardian push protection or a CI
  secret-scanning job. Once a real push-blocking control lands, the local
  scanner can be downgraded to an advisory warning.
- The full local mirror (`validate_ci_gates.sh --fix`) is unchanged, so agents
  and maintainers still have a single command for format + codegen + analyze +
  tests.

## Alternatives considered

- **Remove both hooks.** Rejected: GitGuardian only detects a leak after it is
  in history, so this would delete the only pre-commit credential control while
  leaving the efficiency problem (which came from `pre-push`, not `pre-commit`)
  untouched.
- **Keep the full `pre-push`.** Rejected: it duplicates the CI checks and is
  the source of the working-tree rewrites and multi-minute stalls.
- **Downgrade bare 64-hex to a warning.** Rejected: a leaked key in git history
  costs more than a false positive, and the centralized exemptions already
  remove the historical triggers without weakening the block.
