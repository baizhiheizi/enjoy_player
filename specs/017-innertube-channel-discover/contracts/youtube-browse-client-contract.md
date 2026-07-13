# Contract: YoutubeBrowseClient (InnerTube `browse` for channel refresh)

This contract pins down the new `YoutubeBrowseClient` collaborator that the Discover refresh path uses as its primary source. It is independent of the existing `YoutubeCaptionFetcher` collaborator (which targets the `player` endpoint) and the existing `YoutubeRssParser` (which targets the Atom RSS endpoint).

## Surface

```dart
class YoutubeBrowseClient {
  YoutubeBrowseClient({
    required http.Client client,
    required List<ClientProfile> profiles,
    List<String> preferredProfileOrder = const ['web', 'mweb'],
    int maxPages = 5,
    Duration? perCallTimeout,
  });

  /// Fetches the channel's videos via InnerTube `browse` + continuation.
  ///
  /// Returns a [BrowseFetchOutcome] on success.
  /// Throws [YoutubeBrowseException] on transport error, parse error,
  /// or HTTP 401/403/5xx across all configured profiles.
  Future<BrowseFetchOutcome> fetchChannelVideos({
    required String channelId,
    required DateTime fetchedAt,
  });
}

class BrowseFetchOutcome {
  final List<BrowseVideoEntry> entries;
  final int pagesFetched;
  final bool exhaustedPages;     // true iff `maxPages` was reached with a continuation token still pending
  final String profileUsed;      // name of the ClientProfile that ultimately succeeded
}

class YoutubeBrowseException implements Exception {
  YoutubeBrowseException(this.message, {this.statusCode, this.cause});
  final String message;
  final int? statusCode;
  final Object? cause;
  @override
  String toString() => message;
}
```

## Endpoint

- **URL**: `https://youtubei.googleapis.com/youtubei/v1/browse?prettyPrint=false`
- **Method**: `POST`
- **Headers** (per call):
  - `Content-Type: application/json`
  - `X-YouTube-Client-Name: <profile.clientNameHeader>`
  - `X-YouTube-Client-Version: <profile.clientVersion>`
  - `User-Agent: <profile.userAgent>`
- **Body** (initial call):

  ```json
  {
    "context": {
      "client": {
        "clientName": "<profile.clientName>",
        "clientVersion": "<profile.clientVersion>",
        "hl": "en",
        "gl": "US",
        "userAgent": "<profile.userAgent>",
        "deviceMake": "<...>",
        "deviceModel": "<...>",
        "platform": "DESKTOP",
        "osName": "Windows",
        "osVersion": "10.0"
      }
    },
    "browseId": "UC<channelId>"
  }
  ```

- **Body** (continuation call):

  ```json
  {
    "context": { "client": { "...": "<same as initial>" } },
    "continuation": "<token>"
  }
  ```

## Response shape (channel browse)

The parser tries three paths in order and returns the first one that yields a list of `BrowseVideoEntry` projections. If all three paths return no entries, throws `YoutubeBrowseException('InnerTube browse response has no recognisable videoRenderers')`.

1. **`richGridRenderer`** (uploads tab shape — preferred). Walks
   `contents.twoColumnBrowseResultsRenderer.tabs[*].tabRenderer.content.richGridRenderer.contents[*]`
   and extracts each item via [_tryExtractEntry]. The trailing
   `continuationItemRenderer.continuationEndpoint.continuationCommand.token`
   drives the next page.
2. **`sectionListRenderer` → `shelfRenderer` → `horizontalListRenderer`**
   (Home / Videos-as-shelf shape used by some large channels like TED). Walks
   `tabs[*].tabRenderer.content.sectionListRenderer.contents[*].itemSectionRenderer.contents[*].shelfRenderer.content.horizontalListRenderer.items[*]`
   and parses each via [_tryExtractEntry]. Deduplicates by `videoId`. Not paginated.
3. **Deep recursive search** (last-resort fallback). Walks the entire response
   JSON recursively calling [_tryExtractEntry] on every Map node.
   Deduplicates by `videoId`. Not paginated.

### Renderer types recognised by `_tryExtractEntry`

The generic extractor recognises the following renderer types, either as a
direct child of a Map node or wrapped in `richItemRenderer.content`:

| Renderer key | Shape | Notes |
|---|---|---|
| `videoRenderer` | Legacy (2014+) | `videoId`, `title.runs`, `thumbnail.thumbnails`, `lengthText`, `publishedTimeText`, `viewCountText` |
| `gridVideoRenderer` | Legacy (2018+) | Same shape; duration comes from `thumbnailOverlays[*].thumbnailOverlayTimeStatusRenderer.text` instead of `lengthText` |
| `compactVideoRenderer` | Legacy (2020+) | Same shape as `videoRenderer`; seen in shelf contexts |
| `lockupViewModel` | **Modern (2024+)** — TED's channel uses this | `contentId` (videoId), `metadata.lockupMetadataViewModel.title.content`, `contentImage.thumbnailViewModel.image.sources[0].url`, `contentImage.thumbnailViewModel.overlays[*].{thumbnailBottomOverlayViewModel,thumbnailOverlayBadgeViewModel}.*.text` (duration), `metadata.lockupMetadataViewModel.metadata.contentMetadataViewModel.metadataRows[*].metadataParts[*].text.content` (relative time / view count) |
| `shortsLockupViewModel` | Modern (2024+) — Shorts | `onTap.innertubeCommand.reelWatchEndpoint.videoId`; best-effort parse (most metadata absent) |

Non-video lockups (`LOCKUP_CONTENT_TYPE_PLAYLIST`,
`LOCKUP_CONTENT_TYPE_PODCAST`) are skipped — they don't yield a
`BrowseVideoEntry`.

This covers the canonical uploads tab, the Home-tab-as-shelf shape (real
InnerTube responses from channels like TED use `lockupViewModel` directly
inside `richGridRenderer.contents[*].richItemRenderer.content`), and
renderer drift where the response uses an unusual wrapper. The
continuation-response wrapper (`onResponseReceivedEndpoints[*].appendContinuationItemsAction.continuationItems`)
is handled implicitly by path 3.

Per-entry projection (`BrowseVideoEntry`):

| Field            | Source |
|------------------|--------|
| `videoId`        | `videoRenderer.videoId` (legacy) or `lockupViewModel.contentId` (modern) |
| `title`          | `videoRenderer.title.runs[*].text` joined → `title.simpleText` (legacy) or `lockupMetadataViewModel.title.content` (modern) |
| `thumbnailUrl`   | `videoRenderer.thumbnail.thumbnails[0].url` (legacy) or `lockupViewModel.contentImage.thumbnailViewModel.image.sources[0].url` (modern) |
| `durationSeconds`| Resolved in three places (see below); `null` if absent |
| `publishedAt`    | `videoRenderer.publishedTimeText.simpleText` parsed by `_parseInnerTubePublishedTimeText(text, fetchedAt)` (legacy) or `lockupViewModel.metadata.lockupMetadataViewModel.metadata.contentMetadataViewModel.metadataRows[-1].metadataParts[-1].text.content` (modern, last row's relative time) |
| `viewCountText`  | `videoRenderer.viewCountText.simpleText` (display string, not persisted in this plan) |

`durationSeconds` is resolved in this order:

1. `lengthText.simpleText` — canonical location on `videoRenderer`.
2. `thumbnailOverlays[*].thumbnailOverlayTimeStatusRenderer.text.simpleText` — canonical location on `gridVideoRenderer` (duration is rendered as an overlay, not as a sibling field).
3. A top-level `thumbnailOverlayTimeStatusRenderer.text.simpleText` — older responses.
4. For `lockupViewModel`: `contentImage.thumbnailViewModel.overlays[*].thumbnailBottomOverlayViewModel.badges[*].thumbnailBadgeViewModel.text` or `contentImage.thumbnailViewModel.overlays[*].thumbnailOverlayBadgeViewModel.thumbnailBadges[*].thumbnailBadgeViewModel.text`.

The trailing `continuationItemRenderer.continuationEndpoint.continuationCommand.token` on the last item of a `richGridRenderer.contents` page is captured for the next call. The token is never parsed or transformed.

## Parsing helpers

### `_parseInnerTubeLengthText(String text) → int?`

- Trims whitespace.
- Strips a trailing locale suffix like `" hrs"` if present (defensive).
- Splits on `:`. Maps the parts to seconds:
  - `"SS"` → `SS`
  - `"MM:SS"` → `MM*60 + SS`
  - `"H:MM:SS"` (or `"HH:MM:SS"`) → `H*3600 + MM*60 + SS`
- Returns `null` if any segment is not an integer or the total is `<= 0`.

### `_parseInnerTubePublishedTimeText(String text, DateTime fetchedAt) → DateTime`

Handles the common InnerTube shapes:

| Input                                          | Output                                                  |
|------------------------------------------------|---------------------------------------------------------|
| `"3 days ago"`                                 | `fetchedAt - Duration(days: 3)`                         |
| `"1 hour ago"`                                 | `fetchedAt - Duration(hours: 1)`                        |
| `"30 minutes ago"`                             | `fetchedAt - Duration(minutes: 30)`                     |
| `"2 weeks ago"`                                | `fetchedAt - Duration(days: 14)`                        |
| `"5 months ago"`                               | `fetchedAt - Duration(days: 150)`                       |
| `"1 year ago"`                                 | `fetchedAt - Duration(days: 365)`                       |
| `"Streamed live 2 days ago"`                   | `fetchedAt - Duration(days: 2)`                         |
| `"Premiered 5 months ago"`                     | `fetchedAt - Duration(days: 150)`                       |
| `"Scheduled for 3 days ago"` (uncommon)        | `fetchedAt - Duration(days: 3)`                         |
| Anything else                                  | `fetchedAt` (defensive fallback; entry is still cached) |

The parser MUST be deterministic; unit tests pin every shape above.

## Failure modes

| Trigger | Surface |
|---|---|
| Transport error (timeout, DNS, connection reset) | Throws `YoutubeBrowseException(cause: <error>)` |
| HTTP 401/403 with all profiles | Throws `YoutubeBrowseException(statusCode: 401, message: "all profiles 401/403")` |
| HTTP 5xx with all profiles | Throws `YoutubeBrowseException(statusCode: 5xx, ...)` |
| HTTP 200 with no `richGridRenderer` / `richItemRenderer` (shape drift, deleted channel, suspended channel) | Throws `YoutubeBrowseException(message: "no videos in response")` |
| Continuation token returned but response body is empty | Returns `BrowseFetchOutcome { entries: [...so far], pagesFetched: N, exhaustedPages: false }` — graceful termination |
| `maxPages` reached with continuation token still pending | Returns `BrowseFetchOutcome { entries: [...], pagesFetched: maxPages, exhaustedPages: true }` |

The repository catches `YoutubeBrowseException`, logs a warning via `logNamed('discover.browse')`, and falls back to the legacy RSS path. The repository never lets `YoutubeBrowseException` escape `_refreshChannel`.

## Configuration

| Parameter | Default | Notes |
|---|---|---|
| `preferredProfileOrder` | `['web', 'mweb']` | Names matched against `ClientProfile.name` |
| `maxPages` | `5` | Hard cap on continuation pages per call |
| `perCallTimeout` | `Duration(seconds: 15)` (suggested) | Per-HTTP-call timeout, not total wall-clock |

## Logging

- `logNamed('discover.browse')` — every InnerTube POST (info: profile used, status code, page count). Errors: `warning` with stack trace.
- Never `print()`.

## Testing

- Unit test (in `test/features/discover/youtube_browse_client_test.dart`):
  - Parses a canned 1-page channel response and returns the expected `BrowseVideoEntry` list.
  - Follows a continuation token across 3 pages and stops when the source indicates no more.
  - Honors `maxPages` and reports `exhaustedPages: true`.
  - Returns an empty list and does **not** throw when the source has zero videos.
  - Throws `YoutubeBrowseException` when the response has no `richGridRenderer` / `richItemRenderer`.
  - Throws `YoutubeBrowseException` after retrying each profile on 401/403.
  - `_parseInnerTubeLengthText` and `_parseInnerTubePublishedTimeText` pass the table above.
  - Uses `http.MockClient` so the test does not hit the network.

## Out of scope

- The `player` endpoint (used by `YoutubeCaptionFetcher`) is unrelated.
- The `VL<playlistId>` form of `browseId` (used for playlists) is **explicitly deferred** to the playlist follow-up spec.
- The `navigation/resolve_url` endpoint (used for handle / URL → `channel_id` resolution) is **explicitly deferred** to a separate follow-up; the existing HTML-scrape path in `YoutubeChannelResolver` continues to be used.
- `viewCountText` is parsed but not persisted in this plan; it is available on the `BrowseVideoEntry` projection so a future change can persist it without changing the client.
