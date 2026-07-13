# Quickstart: InnerTube Channel Discover

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Date**: 2026-07-13

This is a validation / run guide. Implementation details live in `tasks.md` and the implementation phase; this document is the "how do I prove the change works end-to-end" reference.

## Prerequisites

- Flutter stable channel matching the repo's pinned version, Dart `^3.12.0`.
- `dart pub get` already run for the workspace.
- For manual end-to-end checks: a YouTube channel you can subscribe to via Manage channels (any reachable channel id works — e.g. `UC_x5XG1OV2P6uZZ5FSM9Ttw` (Google Developers), `UCBJycsmduvYEL83R_U4JriQ` (Marques Brownlee), or any small personal channel you control).

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

- New `youtube_browse_client_test.dart` (parser + continuation + malformed-response + per-profile retry) all pass.
- `discover_repository_test.dart` continues to pass; the new dual-source contract matrix (primary success, primary failure → RSS fallback, primary partial shape, dual failure preserves cache, cooldown skip, profile rotation) is green.
- `validate_ci_gates.sh` exits 0 with no Drift codegen drift (no schema change ⇒ no generated files to update).

## Targeted unit scenarios (for the implementer / reviewer)

These map directly to the spec's success criteria. Run each in isolation by passing `-N` to `flutter test`:

1. **InnerTube success path writes rows with duration** — seed 0 entries, refresh against a stubbed InnerTube response with 30 videos whose `lengthText` is populated. Assert cache = 30 rows, all `durationSeconds` non-null, and **zero** calls to `youtube.com/watch?v=…`.
   ```bash
   flutter test test/features/discover/discover_repository_test.dart -N "InnerTube primary success"
   ```
2. **InnerTube partial-shape still writes rows** — seed 0 entries, refresh against a stubbed InnerTube response with 30 videos that omit `lengthText`. Assert cache = 30 rows, `durationSeconds` is null for all rows, no fallback enrichment runs.
   ```bash
   flutter test test/features/discover/discover_repository_test.dart -N "InnerTube partial shape"
   ```
3. **InnerTube failure → RSS fallback** — seed 0 entries, configure InnerTube to 401 across all profiles, RSS to return a valid 5-entry Atom feed. Assert cache = 5 rows from RSS, `lastFetchedAt` advanced, and the legacy duration enrichment runs (mocked `YoutubeVideoDuration.fetchSeconds` returns null).
   ```bash
   flutter test test/features/discover/discover_repository_test.dart -N "InnerTube 401 falls back to RSS"
   ```
4. **Dual failure preserves cache** — InnerTube 401 across all profiles; RSS returns HTTP 200 with a bot-block HTML page. Assert `failedChannelIds` contains the channel id, cache is unchanged, `lastFetchedAt` is unchanged.
   ```bash
   flutter test test/features/discover/discover_repository_test.dart -N "dual failure preserves cache"
   ```
5. **Profile rotation retries before RSS fallback** — InnerTube returns 401 with `WEB`, then 401 with `MWEB`, then success with the next profile (or fallback to RSS). Assert the repository's call list is `[profile=web → 401, profile=mweb → 401, RSS → success]` and the cache reflects the RSS payload.
   ```bash
   flutter test test/features/discover/discover_repository_test.dart -N "profile rotation"
   ```
6. **Cooldown still skips** — refresh twice inside the 1 h window. Assert the second call hits neither source.
   ```bash
   flutter test test/features/discover/discover_repository_test.dart -N "cooldown skips refresh"
   ```
7. **Append-only cache preserved when InnerTube returns a strict subset** — seed 30 entries for one channel, refresh against an InnerTube response with the 15 newest (a subset). Assert cache = 30, the 15 seen rows have refreshed `fetchedAt`, the 15 unseen rows are untouched.
   ```bash
   flutter test test/features/discover/discover_repository_test.dart -N "append-only across InnerTube subset"
   ```
8. **Continuation pagination** — InnerTube response page 1 has 30 entries + a continuation token; page 2 has 30 more entries + a continuation token; page 3 has 0 entries. Assert `fetchChannelVideos` returns 60 entries, `pagesFetched == 3`, `exhaustedPages == false`.
   ```bash
   flutter test test/features/discover/youtube_browse_client_test.dart -N "continuation pagination"
   ```
9. **Page cap honored** — InnerTube response has 30 entries + a continuation token on every page for 7 pages. Assert `fetchChannelVideos` returns 5 * 30 entries, `pagesFetched == 5`, `exhaustedPages == true`.
   ```bash
   flutter test test/features/discover/youtube_browse_client_test.dart -N "page cap"
   ```
10. **Published-time parsing** — `_parseInnerTubePublishedTimeText("Streamed live 2 days ago", fetchedAt)` returns `fetchedAt - 2 days`; same for the rest of the table in `contracts/youtube-browse-client-contract.md`.
    ```bash
    flutter test test/features/discover/youtube_browse_client_test.dart -N "published time parsing"
    ```

(Exact test names will be finalized when tasks.md is generated; the patterns above are the behavior contract.)

## Manual end-to-end check (one platform)

This is optional — the unit tests above cover the contract. If a manual check is desired:

1. Launch the app, sign in.
2. Open **Discover → Manage channels**, subscribe to a channel with more than 15 uploads in its recent history.
3. Pull to refresh; let the refresh settle.
4. Open the channel feed; verify the **duration** label is visible on every tile that InnerTube supplied a `lengthText` for.
5. Use `Diagnostics` (or the existing `youtube_feed_entries` row count) to confirm the cache count equals or exceeds the InnerTube page 1 size.
6. Wait ≥ 1 h (or trigger `discoverRefreshStateProvider.notifier.refresh(force: true)` after temporarily lowering `minRefreshInterval` for local testing) and refresh again.
7. Verify new entries are prepended; previously seen entries are still present (append-only); the duration fields are still populated.

## Performance sanity

```bash
# Render-time check (manual; not gated by CI)
flutter run -d <desktop target>
# Open Discover with 20 subscriptions each backed by ~500 cached entries.
# Scroll the merged timeline — frames must remain smooth (60 fps on desktop, no jank).
```

If perf degrades noticeably with 500 cached entries per channel, escalate as a follow-up — the spec budget is a hard limit and the sliver pattern is expected to absorb it.

To compare request counts:

```bash
# Capture HTTP traffic during a refresh with a stub HTTP client (manual; not gated by CI)
# Expected InnerTube path:
#   20 channels × 1 POST/page = 20 POSTs (+continuation POSTs for active channels)
# Expected legacy path (for comparison):
#   20 channels × (1 RSS GET + 15 HTML GETs) = 320 GETs (≈ 60% reduction is the spec budget)
```

## Documentation updates to verify

After the implementation lands:

- `docs/features/discover.md` — the "Feed refresh", "Limitations", and "Sliver performance" sections reflect the dual-source posture and the playlist deferral note. The "InnerTube-supplied metadata" subsection explains why durations and view counts appear earlier in the timeline.
- `docs/decisions/0047-youtube-discover-innertube.md` — new ADR exists and is referenced from `discover.md`.
- ADR-0021's wording about "RSS fetch on client" is **not** edited (ADRs are append-only); ADR-0047 supersedes the data-source half by reference.

## Done when

- All targeted unit tests pass.
- `validate_ci_gates.sh` is green (format, codegen drift, analyze, test).
- Manual scroll check on at least one desktop platform with a populated cache feels smooth.
- A 20-channel refresh tick with both sources healthy issues ≤ 60% of the legacy request count.
- `docs/features/discover.md` and the new ADR are merged in the same change.
