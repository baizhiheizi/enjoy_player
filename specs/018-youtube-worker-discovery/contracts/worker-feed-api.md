# Worker Feed API Contract

**Feature**: 018-youtube-worker-discovery  
**Date**: 2026-07-14

The worker is an RSSHub proxy. The canonical API reference is https://docs.rsshub.app/routes/youtube. This document defines the client-facing contract.

## Endpoints

### `GET /youtube/channel/{channel_id}`

Channel feed by canonical channel ID.

**Example**: `GET https://worker.enjoy.bot/youtube/channel/UC...?format=json`

**Query params**: `format=json` (required for JSON output)

**Success (200)** — JSON Feed v1.1:
```json
{
  "version": "https://jsonfeed.org/version/1.1",
  "title": "Channel Name - YouTube",
  "home_page_url": "https://www.youtube.com/channel/UC...",
  "icon": "https://yt3.ggpht.com/...",
  "description": "YouTube channel Channel Name - Powered by RSSHub",
  "items": [
    {
      "id": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "title": "Video Title",
      "content_html": "<p>Video description</p>",
      "image": "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
      "date_published": "2026-07-10T08:00:00.000Z",
      "authors": [{ "name": "Channel Name" }],
      "attachments": [
        {
          "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          "mime_type": "text/html",
          "duration_in_seconds": 212
        }
      ]
    }
  ]
}
```

**Errors**:
- `404` — channel not found
- `410` — channel unavailable (deleted/private/terminated)
- `429` — rate limited
- `502` — YouTube upstream failure

---

### `GET /youtube/user/{handle}`

User/handle feed. RSSHub resolves the handle to the underlying channel.

**Example**: `GET https://worker.enjoy.bot/youtube/user/@TED?format=json`

**Query params**: `format=json` (required)

**Success (200)** — same JSON Feed v1.1 shape as channel endpoint. The `home_page_url` contains the canonical channel URL (e.g., `https://www.youtube.com/channel/UC...`).

**Errors**: same as channel endpoint.

---

### `GET /youtube/playlist/{playlist_id}`

Playlist feed by playlist ID.

**Example**: `GET https://worker.enjoy.bot/youtube/playlist/PL...?format=json`

**Query params**: `format=json` (required)

**Success (200)** — same JSON Feed v1.1 shape. `home_page_url` contains the playlist URL. Items are in playlist order (not reverse-chronological).

**Errors**: same as channel endpoint.

## Client Parsing Contract

The client MUST parse the JSON Feed v1.1 response as follows:

### Feed-level fields

| JSON path | Required | Client action |
|-----------|----------|---------------|
| `title` | Yes | Strip ` - YouTube` suffix → subscription display name |
| `home_page_url` | Yes | Extract canonical ID from URL path (channel: `/channel/UC...`, playlist: `/playlist?list=PL...`) |
| `icon` | No | Subscription avatar URL. Use default avatar if missing. |
| `items` | Yes | Array of video entries |

### Item-level fields

| JSON path | Required | Client action |
|-----------|----------|---------------|
| `id` | Yes | Extract video ID via regex `v=([a-zA-Z0-9_-]{11})` from URL |
| `url` | Yes | YouTube watch URL for playback |
| `title` | Yes | Video title |
| `image` | No | Thumbnail URL |
| `date_published` | No | Published timestamp (ISO 8601). Use `DateTime.now()` if missing. |
| `authors[0].name` | No | Channel author name (may differ from feed-level title) |
| `attachments[0].duration_in_seconds` | No | Video duration in seconds. Persist only if > 0. |
| `attachments[0].mime_type` | No | Should be `text/html` for YouTube videos |

## Handle → ID Canonicalization

When the user subscribes via `@handle`:
1. Fetch `GET /youtube/user/@handle?format=json`
2. Parse `home_page_url` from response → extract channel ID
3. Store the canonical channel ID in the subscription
4. All subsequent refresh requests use `GET /youtube/channel/{canonical_channel_id}?format=json`

This prevents duplicate subscriptions and avoids handle resolution on every refresh.
