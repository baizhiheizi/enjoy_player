# Contract: Worker Transcript Cache & Profile API

**Feature**: [spec.md](../spec.md) | **Replaces**: `POST /youtube/transcripts` (poll-based)

New worker endpoints for the client-side transcription architecture. The old `POST /youtube/transcripts` is deprecated but kept for backward compatibility.

---

## `GET /youtube/transcripts`

Look up a previously cached transcript.

### Query Parameters

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `videoId` | string | **yes** | 11-character YouTube video ID |
| `language` | string | **yes** | BCP-47 language code (base subtag only, e.g., `"en"`) |

### Responses

| HTTP | Body | Meaning |
|------|------|---------|
| 200 | `{ videoId, language, source, timeline, metadata }` | Cache hit — transcript available |
| 404 | `{ error: "not_found" }` | Cache miss — no transcript stored for this video+language |
| 400 | `{ error: "invalid_video_id" }` | Malformed video ID |

### 200 Response Body

```json
{
  "videoId": "dQw4w9WgXcQ",
  "language": "en",
  "source": "official",
  "timeline": [
    { "text": "We're no strangers to love", "start": 0, "duration": 3000 }
  ],
  "metadata": { "title": "Rick Astley - Never Gonna Give You Up" }
}
```

---

## `POST /youtube/transcripts`

Upload a client-fetched transcript for caching.

### Request Body

```json
{
  "format": "enjoy",
  "videoId": "dQw4w9WgXcQ",
  "language": "en",
  "captionFetch": "official",
  "source": "official",
  "timeline": [
    { "text": "We're no strangers to love", "start": 0, "duration": 3000 }
  ],
  "metadata": { "title": "Rick Astley - Never Gonna Give You Up" },
  "generatedAt": "2026-07-13T12:34:56.789Z"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `format` | string | **yes** | Must be `"enjoy"` (validated server-side; reject otherwise). |
| `videoId` | string | **yes** | 11-character YouTube video ID |
| `language` | string | **yes** | BCP-47 language code |
| `captionFetch` | string | **yes** | `"auto"` \| `"official"` — caption selection strategy on the worker side. For client-driven uploads this is derived from `source`: `source == "official"` → `"official"`, otherwise `"auto"`. |
| `source` | string | **yes** | `"official"` \| `"auto"` \| `"ai"` \| `"user"` — provenance of the timeline being uploaded. |
| `timeline` | array | **yes** | Array of `{ text, start, duration }` objects (must be non-empty). |
| `metadata` | object | no | `{ title, channel, durationMs }`. `translated_from` / `translated_to` are not allowed on uploads. |
| `generatedAt` | string | **yes** | ISO 8601 UTC timestamp recorded when the client produced this payload. |

### Responses

| HTTP | Body | Meaning |
|------|------|---------|
| 201 | `{ videoId, language, cached: true }` | Uploaded successfully |
| 409 | `{ videoId, language, cached: true, message: "already_exists" }` | Already cached (idempotent — treated as success) |
| 400 | `{ error: "..." }` | Malformed request (any required field missing or out of range returns 400). |
| 401 | `{ error: "unauthorized" }` | Missing/invalid bearer token |

### Client Behavior

- Upload is **asynchronous and best-effort**: fire-and-forget from the client perspective.
- Client does NOT wait for upload completion before displaying the transcript.
- Upload failure is logged but never surfaced to the user.
- Client sends the bearer token (via `ApiClient` / `aiApiClient`).
- `captionFetch` is currently derived from `source` server-side at
  `_validation.ts`; clients may pass `"auto"` or `"official"` based on
  whether the upstream `source` was the official caption track.

---

## `GET /youtube/client-profiles`

Return the current set of YouTube InnerTube client profiles. No auth required.

### Response

```json
{
  "version": "2026-07-12",
  "profiles": [
    {
      "name": "IOS",
      "version": "20.12.1",
      "client_name_header": "5",
      "user_agent": "com.google.ios.youtube/20.12.1 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)",
      "context": {
        "deviceMake": "Apple",
        "deviceModel": "iPhone16,2",
        "platform": "MOBILE",
        "osName": "iOS",
        "osVersion": "18.3.2.22D82"
      }
    },
    {
      "name": "WEB",
      "version": "2.20250709.00.00",
      "client_name_header": "1",
      "user_agent": "...",
      "context": { ... }
    }
  ]
}
```

The body is wrapped in a `{"version", "profiles"}` envelope (not a bare
array). Clients must read `response.profiles`.

### Client Behavior

- Fetched at app startup and cached in Drift settings under key `youtube.client_profiles_v1`.
- Re-fetched periodically (every 24 hours) or on app foreground.
- On fetch failure: use cached version from settings.
- On cache miss: use built-in compile-time defaults.
