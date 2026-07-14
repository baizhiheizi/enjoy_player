# Data Model: YouTube Worker Discovery

**Feature**: 018-youtube-worker-discovery  
**Date**: 2026-07-14

## Entities

### YoutubeChannelSubscriptionRow (Drift table)

Stores a user's subscription to a YouTube channel or playlist. Schema changes from existing table:

| Column | Type | Change | Description |
|--------|------|--------|-------------|
| `channelId` | TEXT PK | Unchanged | Canonical source ID (`UC...` for channels, `PL...` for playlists) |
| `displayName` | TEXT | Unchanged | Display name from feed `title` (strip ` - YouTube` suffix) |
| `thumbnailUrl` | TEXT? | Unchanged | Avatar URL from feed `icon` |
| `source` | TEXT | Unchanged | How sub was added: `recommended` (catalog) or `user` (manual) |
| `sourceType` | TEXT | **NEW** | What the source is: `channel` or `playlist` |
| `feedUrl` | TEXT | **NEW** | Constructed worker feed URL: `{base}/youtube/{type}/{id}?format=json` |
| `subscribedAt` | DATETIME | Unchanged | When the subscription was created |
| `lastFetchedAt` | DATETIME? | Unchanged | Last successful feed fetch timestamp |
| `language` | TEXT | Unchanged | Channel content language (default `'und'`) |

**Migration SQL**:
```sql
ALTER TABLE youtube_channel_subscriptions ADD COLUMN source_type TEXT NOT NULL DEFAULT 'channel';
ALTER TABLE youtube_channel_subscriptions ADD COLUMN feed_url TEXT;
```

**Backfill**: `UPDATE youtube_channel_subscriptions SET source_type = 'channel'` (all existing subs are channels). Generate `feed_url` from existing `channelId` + default worker base URL.

### YoutubeFeedEntryRow (Drift table)

Stores cached video entries from worker JSON Feed responses. No schema changes needed.

| Column | Type | Source (JSON Feed) | Description |
|--------|------|---------------------|-------------|
| `videoId` | TEXT PK | Extract from `items[].id` (YouTube URL → video ID) | YouTube video ID |
| `channelId` | TEXT PK | Subscription's canonical ID | Parent source ID |
| `title` | TEXT | `items[].title` | Video title |
| `thumbnailUrl` | TEXT? | `items[].image` | Thumbnail URL |
| `durationSeconds` | INT? | `items[].attachments[0].duration_in_seconds` | Duration in seconds |
| `publishedAt` | DATETIME | `items[].date_published` | Publication timestamp |
| `fetchedAt` | DATETIME | `DateTime.now()` on upsert | When this entry was last seen |

**Composite PK**: `(videoId, channelId)` — unchanged.

### New Domain Types

```dart
/// What kind of YouTube source this subscription represents.
enum YoutubeSourceType {
  channel,  // Channel or handle (both resolve to channel)
  playlist, // Playlist
}

/// Parsed result from user input URL validation.
class ParsedYoutubeUrl {
  final YoutubeSourceType sourceType;
  final String canonicalId;  // UC... or PL... or @handle (pre-resolution)
  final String feedUrl;      // Constructed worker feed URL
}
```

### State Transitions

**Subscription lifecycle**:
```
[User enters URL] → URL validated → feed fetched → subscription created (active)
                                                              ↓
[Refresh succeeds] ← feed re-fetched ← timer/pull-to-refresh ←┘
                                                              ↓
[Worker returns 404/410] → source marked unavailable → auto-refresh disabled
                                                              ↓
[User unsubscribes] → subscription + cached entries deleted
```

**Feed entry lifecycle**:
```
[Feed fetched] → entries parsed → upsert by (videoId, channelId)
                                      ↓
[Subsequent refresh] → same entry re-presented → title/thumbnail/duration updated, fetchedAt refreshed
                                      ↓
[Subsequent refresh] → entry no longer in feed → row untouched (append-only)
                                      ↓
[User unsubscribes] → all entries for channelId deleted
```

## Validation Rules

1. **URL validation**: Input must match one of three patterns (channel URL, handle URL, playlist URL) OR be a raw ID matching `UC...` or `PL...` or `@...`. Reject before any worker call.
2. **Duplicate prevention**: Before creating a subscription, check if `channelId` already exists in `youtube_channel_subscriptions`. For handle subscriptions, this check happens AFTER the initial feed fetch (to extract the canonical channel ID).
3. **Video ID extraction**: `items[].id` may be a full YouTube URL (`https://www.youtube.com/watch?v=dQw4w9WgXcQ`) or a bare video ID. Extract the 11-character ID via regex.
4. **Duration**: Only persist if `duration_in_seconds > 0`. Null durations are allowed (JSON Feed doesn't guarantee duration).
5. **Title/thumbnail updates**: On each upsert, overwrite `title`, `thumbnailUrl`, `durationSeconds` with the latest feed values. The append-only contract (ADR-0046) allows mutating existing rows.
