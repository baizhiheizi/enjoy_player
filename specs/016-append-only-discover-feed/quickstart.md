# Quickstart: Discover Feed Append-Only Persistence

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Date**: 2026-07-13

This is a validation / run guide. Implementation details live in `tasks.md` and the implementation phase; this document is the "how do I prove the change works end-to-end" reference.

## Prerequisites

- Flutter stable channel matching the repo's pinned version, Dart `^3.12.0`.
- `dart pub get` already run for the workspace.
- For manual end-to-end checks: a YouTube channel you can subscribe to via Manage channels (any reachable channel id works — e.g. `UCAuUUnT6oKwE6v1NGQxug`).

## Automated validation

```bash
# Run only the discover feature tests (fast loop)
flutter test test/features/discover/

# Run the broader db tests to confirm no Drift regression
flutter test test/data/db/

# Format + codegen + analyze + tests (CI gate)
bash .github/scripts/validate_ci_gates.sh
```

Expected outcomes:

- New tests asserting append-only behavior (cache grows on new entries, cache preserved when RSS omits entries, refresh idempotency, unsubscribe clears, failed refresh leaves cache untouched) all pass.
- Existing `discover_dedupe_test.dart` tests still pass — the dedupe logic in `watchTimeline` / `watchChannelFeed` is unchanged.
- `validate_ci_gates.sh` exits 0 with no Drift codegen drift (no schema change ⇒ no generated files to update).

## Targeted unit scenarios (for the implementer / reviewer)

These map directly to the spec's success criteria. Run each in isolation by passing `-N` to `flutter test`:

1. **Append on new entries** — seed 0 entries, refresh against a stubbed 5-entry RSS payload. Assert cache = 5.
   ```bash
   flutter test test/features/discover/discover_repository_test.dart -N "append new entries"
   ```
2. **Preserve on subset refresh** — seed 10 entries, refresh against a stubbed 5-entry payload whose videoIds are a strict subset. Assert cache = 10 (unchanged).
   ```bash
   flutter test test/features/discover/discover_repository_test.dart -N "preserve cache when RSS omits entries"
   ```
3. **Idempotency** — refresh twice in a row against the same stubbed payload. Assert cache = 5 and `watchChannelFeed` emits once per real change.
4. **Unsubscribe clears** — seed 8 entries for channel A and 3 for channel B. Call `unsubscribe(A)`. Assert channel A entries = 0, channel B entries = 3, A subscription row deleted.
5. **Failed refresh leaves cache untouched** — refresh against a stubbed HTTP 500 response. Assert cache unchanged and `lastFetchedAt` is `null`.

(Exact test names will be finalized when tasks.md is generated; the patterns above are the behavior contract.)

## Manual end-to-end check (one platform)

This is optional — the unit tests above cover the contract. If a manual check is desired:

1. Launch the app, sign in.
2. Open **Discover → Manage channels**, subscribe to a channel whose RSS publishes more than 15 entries (most active channels qualify).
3. Pull to refresh; let the refresh settle.
4. Note the entry count visible in the channel feed or merged timeline (no in-app counter today, so use `Diagnostics` if available, or count tiles).
5. Wait ≥ 1 h (or trigger `discoverRefreshStateProvider.notifier.refresh(force: true)` after temporarily lowering `minRefreshInterval` for local testing) and refresh again.
6. Verify entries seen in step 4 are still present; the new ones (if any) are prepended.

## Performance sanity

```bash
# Render-time check (manual; not gated by CI)
flutter run -d <desktop target>
# Open Discover with 20 subscriptions each backed by ~500 cached entries.
# Scroll the merged timeline — frames must remain smooth (60 fps on desktop, no jank).
```

If perf degrades noticeably with 500 cached entries per channel, escalate as a follow-up — the spec budget is a hard limit and the sliver pattern is expected to absorb it. The `docs/features/discover.md` "Sliver performance" section will be updated to reflect the new append-only behavior.

## Documentation updates to verify

After the implementation lands:

- `docs/features/discover.md` — the "Feed refresh", "Limitations", and "Sliver performance" sections reflect append-only semantics, and the `~15 recent videos per channel per RSS fetch` caveat is reframed as a per-fetch cap, not a cache cap.
- `docs/decisions/0046-discover-feed-append-only.md` — new ADR exists and is referenced from `discover.md`.
- `docs/features/diagnostics.md` — if a feed-cache-size metric is reported, its description matches the new semantics; if not, no change required.

## Done when

- All targeted unit tests pass.
- `validate_ci_gates.sh` is green (format, codegen drift, analyze, test).
- Manual scroll check on at least one desktop platform with a populated cache feels smooth.
- `docs/features/discover.md` and the new ADR are merged in the same change.