# ADR-0105: CI test shards and the shared host's 12-lane budget

**Status**: Accepted (2026-11-13)
**Related**: [#1335](https://github.com/baizhiheizi/enjoy_player/issues/1335),
[#1269](https://github.com/baizhiheizi/enjoy_player/pull/1269),
[docs/ci-self-hosted-runners.md](../ci-self-hosted-runners.md),
[.github/workflows/ci.yml](../../.github/workflows/ci.yml),
[.github/scripts/check_coverage_gate.sh](../../.github/scripts/check_coverage_gate.sh)

## Context

The `Analyze & test` job ran the whole app suite (793 files, ~7,250 cases) as
one `flutter test` at the runner's default concurrency — `cores / 2` = 12
tester processes on the pool's 24-core host — with a 5-minute per-test budget
added by #1269 because Drift-backed tests failed on timing there.

On 2026-11-13 two PR runs collided on x1 (both `ci` runners live on that one
24-core / 60 GiB host): 24 tester processes plus two `frontend_server`s
drove the host into swap (19.5 GiB), `/proc/pressure/io` peaked at 27.7, and
the suite doubled from **13.1 minutes (solo, measured on runs 43354041732 /
43143451374 / 43184674994) to 28.5 minutes** — and the two Drift-backed
`setup_logging` cases failed on timing again, this time *with* the 5-minute
budget. Because everything was one job, the failing test step also silently
skipped the calendar-label check, the coverage baseline, the Codecov upload
and the path-package suites behind it.

The cost is not per-job parallelism but **host-wide lane budget**: two runner
instances share one host, so any two legs running at once see each other.
The solo 12-lane run sustains 13.1 minutes; 24 lanes collapse into swap.
Splitting the suite into more, faster shards cannot beat that arithmetic on
this host — it can only avoid *exceeding* the budget and isolate failures.
Two control runs sharpen the picture. On a 32-core workstation, a
`--total-shards` shard at `--concurrency=6` took 437s against 435s for the
full suite at 12 lanes — no faster, because `flutter test`'s
`--total-shards` / `--shard-index` slice **by test case inside every file**:
each shard still compiles all 793 files and runs a quarter of the cases, so
the compile work — the dominant cost — is duplicated per shard, and every
shard's lcov records the same ~1,100 `SF` files (all four artifacts of the
first pool run carried exactly 1,088). The sharding that helps must partition
**files**, which is what `split_test_shards.sh` now does.

## Decision

1. **Every test leg runs with an explicit `--concurrency=6`.** Two colliding
   PRs put at most two legs on the host at once, so the worst case is the
   same 12 tester processes a solo run already sustains. No test process
   count on this host is left to `cores / 2` defaults again.
2. **The app suite shards 4 ways by explicit, disjoint file lists**
   (`split_test_shards.sh` round-robins the `LC_ALL=C`-sorted
   `test/**_test.dart` list; each shard runs `flutter test <its files>`;
   `fail-fast: false`), one shard per job. A test file executes in exactly
   one shard, so each shard compiles and runs only its quarter instead of
   four copies of the whole suite. The shards stay the unit the pool scales
   with — **per host**: two instances per host keep that host at the 12-lane
   budget, so adding a second host (two `ci` instances each) drops the matrix
   into a single wave. Scaling instances on the *same* host does not: four
   shards at 6 lanes on one 24-core host is the 24-lane collapse this ADR
   exists to prevent. On today's single host the matrix runs as two waves.
3. **`Analyze` splits out of the tests.** Format / analyze / the hook
   regression suite and the governance checks run once, in a fast job; the
   shard matrix repeats only the Flutter setup it needs. The fast path is
   ~2 minutes, but the job keeps a 40-minute timeout (the analyze, path and
   gates jobs all do): it gates every test job, and a cold pub cache or a
   host busy with another PR's shards must not skip the whole matrix with
   zero test signal. The `ci-approval` environment stays on the `analyze`
   job alone — every other job `needs:` it, so outside-PR code still cannot
   execute on the pool before the reviewer approves, without one pending
   approval per matrix leg.
4. **Coverage baseline, Codecov and the DST calendar-label case move to a
   `gates` job** that runs whenever the shards have finished — including on a
   shard failure. Each shard uploads its partial lcov as an artifact; the
   gates job **union-merges** them (`merge_shard_lcov.sh`: per `SF` record,
   `DA` hits take the max across shards, `LF` is emitted once, `LH` is
   recomputed) and evaluates the baseline on the union. A concatenation would
   multiply `LF` by the shard count while `LH` grows by something else
   entirely — on the first pool run it reported 55.91% where the true union
   is 73.33% (and a single full-suite run measures 73.41%, within the 0.5pt
   the review required) — so the merge must be exact, not lucky. The gates
   job carries the same sqlite3 prefetch as the shard jobs: the DST case is
   a root-package `flutter test`, and every job that runs one builds
   `package:sqlite3`'s native asset — without the prefetch its no-retry
   download is a random red. A timed-out test can no longer skip the gates
   silently. `test/ci_workflow_lane_budget_test.dart` pins the lane cap, the
   four-leg split, the union merge (with a two-shard overlapping-file
   fixture) and the aggregate semantics so they cannot silently regress.
5. **The required check keeps its name via an aggregate.** `Analyze & test`
   is now a zero-step job that succeeds when every job behind it succeeded
   or was skipped (an irrelevant PR skips the whole chain) and fails when any
   leg failed — so re-enabling the `main: required checks` ruleset keeps
   working without re-deriving its check list.
6. **The two Drift-backed `setup_logging` budgets drop from 5 minutes back
   to 60 seconds** (#1335 acceptance check): with the lane cap there is no
   24-process I/O storm to hide behind, and a 60-second failure returning is
   the signal that the host is saturated for real. The global `--timeout=5m`
   stays as the stall-detection budget for the rest of the suite, and the
   `migration_pre_v6_guard` case keeps its 5-minute budget — it runs real
   pre-v6 migrations, not a handle open.

## Consequences

- A two-PR collision can no longer double the suite or push the host into
  swap; the load ceiling is now a property of the workflow, not of who pushes
  when.
- One flaky shard reds its own check while the other three, the path-package
  suite and the coverage baseline all still report.
- On today's single-host pool the matrix runs as two waves; the wall clock
  there is owned by compile throughput, and the file partition is what makes
  each wave a quarter-compile instead of a full one. The scaling — a second
  host with two `ci` instances, keeping the 12-lane-per-host budget — is a
  gh-sr-side change (`runners.yml`), not a repo change. First pool run
  (2026-11-13 05:14–06:16 UTC, run 43370711369, case-sharded draft): every
  job green — shards ≈ 27 min each — on a daytime host whose
  `/proc/pressure/io` avg300 read 22.7 during the run (the 13.1-minute solo
  reference came from 03:00 quiet-host runs); re-check the wall clock on a
  quiet host under the file-partition scheme before tuning shard count or
  concurrency. The two 60-second Drift-backed logging budgets passed **on
  that loaded host**, which is the #1335 acceptance signal working early.
- The union merge makes the gate number exact: on the first pool run's four
  artifacts the old concatenation arithmetic reported 55.91% while the
  union is 73.33% (`LF` 243,224 → 61,185). The gate floor (32%) hid the
  dilution; the Codecov upload would not have.
- Per-shard coverage artifacts cost a few MB of proxy traffic per PR
  (`retention-days: 1`); everything else in the job's dependency path already
  rides the LAN cache.
- The pub-cache save step is now `continue-on-error`: on a cold cache the
  matrix legs race the same key and exactly one writer may win.
- Follow-up levers if wall clock must drop further on this host, in order of
  cost: drop `--coverage` from PR shards and gate the baseline on `main`
  pushes only (saves the instrumentation overhead, weakens PR gating), add a
  second host with two `ci` instances so the shard matrix runs in one wave
  (repo-side config already supports it), or move to a bigger host —
  anything that raises the 12-lane budget.

## Alternatives considered

- **Only cap concurrency, no sharding.** Fixes collisions and is the minimal
  diff, but leaves the failure semantics: one timed-out test still skips the
  calendar-label check, coverage baseline, Codecov and path packages behind
  it in the same job, and there is no unit the pool can scale with.
- **`dart_test.yaml` with a concurrency cap.** Rejected: it would also slow
  every local `flutter test` on 32-core workstations for a problem that only
  exists on the shared pool.
- **Run the suite without `--coverage` on PRs, gate the baseline on pushes to
  `main` only** (the #1335 suggestion). Rejected for now: it removes the
  line-baseline gate from PRs, which is a real regression in gating strength;
  kept as the first follow-up lever instead.
- **`flutter test --total-shards` / `--shard-index`** (a first draft of this
  ADR; caught in review on #1335). Rejected: the flags slice by test case
  inside every file, so every shard compiles all 793 files — four full
  compiles instead of one — and every shard's lcov records the whole file
  set, which is also why the merge has to union by `SF` record.
- **Concatenate the shard lcov files with `cat`.** Rejected: `LF` would be
  counted once per shard while `LH` grows by the hits each shard adds —
  measured at 55.91% against a true union of 73.33% on the first pool run's
  artifacts. `merge_shard_lcov.sh` emits each `SF` once with merged `DA`
  hits.
- **Issue's `--shard=${{ matrix.shard }}/4` syntax.** Not valid for
  `flutter test` — it only accepts the separate `--total-shards` /
  `--shard-index` pair.
- **Parallelize the path-package loop** (the #1335 `xargs -P` suggestion).
  Measured at 22 seconds for both packages; parallelizing buys nothing and
  adds lanes. The loop keeps its `--concurrency=6` cap like every other test
  leg.
