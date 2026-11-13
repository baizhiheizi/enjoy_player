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
A control run also shows the budget is the invariant, not the shard count:
on a 32-core workstation, shard 0/4 at `--concurrency=6` took 437s against
435s for the full suite at 12 lanes — kernel compiles want roughly two cores
each, so halving the lanes doubles per-file wall time and a shard's wall time
at 6 lanes equals the full suite's at 12.

## Decision

1. **Every test leg runs with an explicit `--concurrency=6`.** Two colliding
   PRs put at most two legs on the host at once, so the worst case is the
   same 12 tester processes a solo run already sustains. No test process
   count on this host is left to `cores / 2` defaults again.
2. **The app suite shards 4 ways** (`--total-shards=4 --shard-index=N`,
   `fail-fast: false`), one shard per job. Shards are file-partitions, so
   they are also the unit the pool scales with — **per host**: two instances
   per host keep that host at the 12-lane budget, so adding a second host
   (two `ci` instances each) drops the matrix into a single wave. Scaling
   instances on the *same* host does not: four shards at 6 lanes on one
   24-core host is the 24-lane collapse this ADR exists to prevent. On
   today's single host the matrix runs as two waves.
3. **`Analyze` splits out of the tests.** Format / analyze / the hook
   regression suite and the governance checks run once, in a fast job; the
   shard matrix repeats only the Flutter setup it needs. The
   `ci-approval` environment stays on the `analyze` job alone — every other
   job `needs:` it, so outside-PR code still cannot execute on the pool
   before the reviewer approves, without one pending approval per matrix leg.
4. **Coverage baseline, Codecov and the DST calendar-label case move to a
   `gates` job** that runs whenever the shards have finished — including on a
   shard failure. Each shard uploads its partial lcov as an artifact; the
   gates job concatenates them (disjoint `SF` records, the gate script sums
   `LF:`/`LH:` across the file) and evaluates the baseline on the union.
   A timed-out test can no longer skip the gates silently.
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
- On today's single-host pool the matrix runs as two waves, so an
  uncontended PR lands around the same wall clock as the old solo job (~15–20
  minutes) instead of improving; the win arrives with pool scaling (see
  below) and on every collision. The scaling — a second host with two `ci`
  instances, keeping the 12-lane-per-host budget — is a gh-sr-side change
  (`runners.yml`), not a repo change.
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
- **Issue's `--shard=${{ matrix.shard }}/4` syntax.** Not valid for
  `flutter test` — it only accepts the separate `--total-shards` /
  `--shard-index` pair.
- **Parallelize the path-package loop** (the #1335 `xargs -P` suggestion).
  Measured at 22 seconds for both packages; parallelizing buys nothing and
  adds lanes.
