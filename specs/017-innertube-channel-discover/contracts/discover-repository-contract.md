# Contracts: InnerTube Channel Discover

This feature has **no external API contracts** in the worker / cloud sense — the InnerTube surface is the same anonymous public endpoint already used by the YouTube caption fetcher. The relevant contracts are the public surface of `DiscoverRepository`, the new `YoutubeBrowseClient` collaborator, and the shared `ClientProfile` model.

The contracts below are pinned to the *post-change* behavior. Anything marked **unchanged** is preserved verbatim from the existing implementation; anything marked **changed** is part of this feature.

## C-1: `DiscoverRepository.refreshFeeds`

```dart
Future<DiscoverRefreshResult> refreshFeeds({bool force = false});
```

**Behavior**:

- `force == false` — skips channels whose `lastFetchedAt` is within `minRefreshInterval` (1 h). **Unchanged**.
- `force == true` — refreshes every subscribed channel regardless of cooldown. **Unchanged**.
- Returns `DiscoverRefreshResult { refreshedChannels, failedChannelIds }`. **Unchanged**.
- Concurrency cap: `_kRefreshChannelConcurrency = 4`. **Unchanged**.
- No HTTP requests are made when the subscription list is empty. **Unchanged**.

## C-2: `DiscoverRepository._refreshChannel` (internal, **changed**)

```dart
Future<void> _refreshChannel(String channelId, {required DateTime fetchedAt});
```

**Behavior (post-change)**:

1. Build the InnerTube `browse` request: `POST https://youtubei.googleapis.com/youtubei/v1/browse` with `{ context: { client: <profile> }, browseId: "UC<channelId>" }`. The client profile is selected from the configured `ClientProfile` list in the order `_kBrowsePreferredProfileOrder` (default `['web', 'mweb']`).
2. For each profile, attempt the InnerTube POST. On HTTP 401/403/5xx, retry the same channel with the next profile in the order. After all profiles are exhausted, fall back to the legacy RSS path.
3. **InnerTube success path** — parse the response into `BrowseVideoEntry` projections (see C-5). For each entry, upsert a `YoutubeFeedEntryRow` keyed by `(channelId, videoId)` with the supplied `durationSeconds` (when present), `viewCountText` is **not** persisted in this plan, `publishedAt`, `title`, `thumbnailUrl`. Skip the legacy `YoutubeVideoDuration.fetchSeconds` enrichment for these rows (per FR-007).
4. **InnerTube failure → RSS fallback path** — call `YoutubeFetch.getRss` against `https://www.youtube.com/feeds/videos.xml?channel_id=<channelId>`, parse with `YoutubeRssParser.parse`, upsert the same `(channelId, videoId)` rows (without duration — it is left null for this tick), then run the legacy `_enrichMissingDurations` path for those rows.
5. **Dual failure** — both paths failed (InnerTube exhausted all profiles AND RSS returned non-200 / bot-block / malformed XML). Throw the existing `YoutubeFeedFetchException` (or the new `YoutubeBrowseException` if InnerTube was the primary failure) so `_refreshChannelGuarded` records the failure and the cache / `lastFetchedAt` stay untouched.
6. **Either-source success** — touch `YoutubeChannelSubscriptionDao.touchLastFetched(channelId, fetchedAt)`. Either source's success counts.
7. Kick off `unawaited(_enrichMissingDurations(channelId, entries))` **only** when the RSS fallback path was used (the InnerTube path already supplied durations). **Changed**.
8. Kick off `unawaited(_maybeUpdateChannelAvatar(channelId))`. **Unchanged**.
9. Update the subscription `displayName` from either the InnerTube `channelMetadataRenderer.title` or the RSS `parseFeedTitle` (whichever fired). **Behavior widened**.

## C-3: `DiscoverRepository.unsubscribe`

```dart
Future<void> unsubscribe(String channelId);
```

**Behavior**: deletes the subscription row and every cached feed entry for that channel (via `YoutubeFeedEntryDao.deleteForChannel`). **Unchanged** — this remains the user-visible way to bound cache growth.

## C-4: `DiscoverRepository.watchTimeline` / `watchChannelFeed`

```dart
Stream<List<FeedEntry>> watchTimeline();
Stream<List<FeedEntry>> watchChannelFeed(String channelId);
```

**Behavior**:

- Sort order remains `publishedAt DESC`. **Unchanged**.
- Dedupe via `distinctBy(_listEqualsFeedEntry)` so identical re-emissions do not rebuild widgets. **Unchanged**.
- Result set grows monotonically over the lifetime of the subscription; only `unsubscribe` truncates it. **Unchanged**.
- `FeedEntry.durationSeconds` may now be non-null on rows that arrived via the InnerTube primary path; null is still allowed for rows that arrived via RSS before the watch-page enrichment completes.

## C-5: `YoutubeBrowseClient` (new collaborator)

```dart
class YoutubeBrowseClient {
  YoutubeBrowseClient({
    required http.Client client,
    required List<ClientProfile> profiles,
    Duration? perCallTimeout,
    int maxPages = _kBrowseMaxPages,
  });

  Future<BrowseFetchOutcome> fetchChannelVideos({
    required String channelId,
    required DateTime fetchedAt,
  });
}

class BrowseFetchOutcome {
  final List<BrowseVideoEntry> entries;
  final bool exhaustedPages; // true if the page cap was hit before the source ran out
  final int pagesFetched;
}

class BrowseVideoEntry { /* see data-model.md */ }
```

**Behavior**:

- Selects the configured profiles in `_kBrowsePreferredProfileOrder` order. Iterates per-profile on 401/403; iterates continuation pages inside a profile on success.
- Stops after `maxPages` continuation pages (default 5), even if a continuation token is still being returned. The resulting `BrowseFetchOutcome.exhaustedPages` is `true` in that case.
- Throws `YoutubeBrowseException` (new) on transport error, parse error (no `richGridRenderer` / `videoRenderer`), or HTTP 401/403/5xx across all profiles. The repository catches this and falls back to RSS.
- POST body shape: `{ context: { client: { clientName, clientVersion, ...profile.context } }, browseId: "UC<channelId>" }`.
- Continuation POST body shape: `{ context: { client: { ...same profile... } }, continuation: "<token>" }`.
- Response parsing walks `contents.twoColumnBrowseResultsRenderer.tabs[*].tabRenderer.content.richGridRenderer.contents[*]` and pulls each `richItemRenderer.content.videoRenderer` plus the trailing `continuationItemRenderer.continuationEndpoint.continuationCommand.token`.
- Logging uses `logNamed('discover.browse')`. Never `print()`.

## C-6: `ClientProfile` (existing — `WEB` added)

```dart
class ClientProfile {
  final String name;             // 'ios' | 'android_vr' | 'mweb' | 'web'
  final String clientName;       // 'IOS' | 'ANDROID_VR' | 'MWEB' | 'WEB'
  final String clientVersion;
  final String clientNameHeader;
  final String userAgent;
  final Map<String, String> context;
}
```

**Behavior**:

- `kBuiltInClientProfiles` gains a fourth entry: `web` with a current `clientVersion` (e.g., `'2.20240101.00.00'`) and a desktop Chrome user agent. Existing three entries are unchanged.
- Worker `GET /youtube/client-profiles` continues to be the source of truth for live versions; the built-ins remain the cold-start fallback.
- `YoutubeBrowseClient` consumes `ClientProfile` instances from the existing `kBuiltInClientProfiles` list filtered by name ∈ `{web, mweb}`. The caption fetcher's rotation ladder is unaffected.

## C-7: `YoutubeFeedEntryDao` (Drift accessor, unchanged methods)

| Method | Use after the change |
|---|---|
| `watchTimeline()` | `DiscoverRepository.watchTimeline` (C-4). **Unchanged**. |
| `watchForChannel(channelId)` | `DiscoverRepository.watchChannelFeed` (C-4). **Unchanged**. |
| `upsertEntry(YoutubeFeedEntryRow row)` | `DiscoverRepository._refreshChannel` on either path. InsertOrReplace by composite PK `(videoId, channelId)`. **Unchanged**. |
| `getEntry({channelId, videoId})` | `DiscoverRepository._refreshChannel` to preserve `durationSeconds`; `_enrichMissingDurations` to skip already-enriched entries. **Unchanged**. |
| `updateDurationSeconds(...)` | `YoutubeVideoDuration` enrichment, run only on the RSS fallback path. **Unchanged**. |
| `deleteForChannel(channelId)` | `unsubscribe`. **Unchanged**. |

## C-8: Drift schema (`youtube_feed_entries`, `youtube_channel_subscriptions`)

**Schema unchanged.** The new behavior (InnerTube-supplied durations) is a runtime invariant, not a schema invariant — keeping the schema stable avoids a forced migration on every existing install.

## C-9: UI surface

- `discover_screen.dart` (merged timeline) and `channel_feed_screen.dart` (per-channel feed) consume `watchTimeline` and `watchChannelFeed`. They render `FeedEntry` lists sorted by `publishedAt DESC`.
- The existing `ValueKey<String>('discover-feed-<videoId>')` / `'channel-feed-<videoId>'` keys plus `findChildIndexCallback` ensure that appending new entries at the head does not rebuild existing tiles. **Unchanged**.
- No new widget code is required. If the UI wants to render the view count, it consumes `FeedEntry.durationSeconds` (already in the type) — `FeedEntry.viewCountText` is **not** added in this plan.

## C-10: External (out of scope)

This feature does **not** touch:

- The YouTube caption fetcher's contracts (`lib/features/transcript/data/youtube_caption_fetcher.dart`); only the shared `ClientProfile` model gains a new built-in entry.
- The `videos` table (library rows); library import flow is unchanged.
- The channel subscription / avatar pipeline, except for the widened `displayName` source (C-2 step 9).
- Drift schema migrations (no migration introduced).
- Any cloud-sync surface (ADR-0010); Discover is local-only.
- The `YoutubeChannelResolver` HTML-scrape path; handle / URL → `channel_id` resolution is unchanged in this plan.
- **Playlist import** (`https://youtube.com/playlist?list=…` and the `VL<playlistId>` InnerTube `browse` path) — explicitly deferred to a follow-up spec per FR-013.

## Verification of contracts

- C-2 is exercised by `discover_repository_test.dart` (dual-source contract matrix).
- C-5 is exercised by `youtube_browse_client_test.dart` (parser + continuation + malformed-response + per-profile retry).
- C-3, C-4 are unchanged; existing tests continue to cover them.
- C-6 is exercised by a small unit test that confirms the new `WEB` profile round-trips through `ClientProfile.fromJson` and `isValid`.
- C-7, C-8 are unchanged; `test/data/db/app_database_test.dart` covers the DAO contract.
