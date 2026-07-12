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
  "videoId": "dQw4w9WgXcQ",
  "language": "en",
  "source": "official",
  "timeline": [
    { "text": "We're no strangers to love", "start": 0, "duration": 3000 }
  ],
  "metadata": { "title": "Rick Astley - Never Gonna Give You Up" }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `videoId` | string | **yes** | 11-character YouTube video ID |
| `language` | string | **yes** | BCP-47 language code |
| `source` | string | **yes** | `"official"` or `"auto"` |
| `timeline` | array | **yes** | Array of `{ text, start, duration }` objects |
| `metadata` | object | no | `{ title, channel, durationMs }` |

### Responses

| HTTP | Body | Meaning |
|------|------|---------|
| 201 | `{ videoId, language, cached: true }` | Uploaded successfully |
| 409 | `{ videoId, language, cached: true, message: "already_exists" }` | Already cached (idempotent — treated as success) |
| 400 | `{ error: "..." }` | Malformed request |
| 401 | `{ error: "unauthorized" }` | Missing/invalid bearer token |

### Client Behavior

- Upload is **asynchronous and best-effort**: fire-and-forget from the client perspective.
- Client does NOT wait for upload completion before displaying the transcript.
- Upload failure is logged but never surfaced to the user.
- Client sends the bearer token (via `ApiClient` / `aiApiClient`).

---

## `GET /youtube/client-profiles`

Return the current set of YouTube InnerTube client profiles. No auth required.

### Response

```json
{
  "version": 1,
  "profiles": [
    {
      "name": "ios",
      "clientName": "IOS",
      "clientVersion": "20.10.4",
      "clientNameHeader": "5",
      "userAgent": "com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)",
      "context": {
        "deviceMake": "Apple",
        "deviceModel": "iPhone16,2",
        "platform": "MOBILE",
        "osName": "iOS",
        "osVersion": "18.3.2.22D82"
      }
    },
    {
      "name": "android_vr",
      "clientName": "ANDROID_VR",
      "clientVersion": "1.62.20",
      "clientNameHeader": "28",
      "userAgent": "com.google.android.apps.youtube.vr.oculus/1.62.20 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip",
      "context": {
        "deviceMake": "Oculus",
        "deviceModel": "Quest 3",
        "platform": "MOBILE",
        "osName": "Android",
        "osVersion": "12L",
        "androidSdkVersion": 32
      }
    },
    {
      "name": "mweb",
      "clientName": "MWEB",
      "clientVersion": "2.20251209.01.00",
      "clientNameHeader": "2",
      "userAgent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1",
      "context": {
        "platform": "MOBILE",
        "osName": "iOS",
        "osVersion": "17.5.1"
      }
    }
  ]
}
```

### Client Behavior

- Fetched at app startup and cached in Drift settings under key `youtube.client_profiles_v1`.
- Re-fetched periodically (every 24 hours) or on app foreground.
- On fetch failure: use cached version from settings.
- On cache miss: use built-in compile-time defaults.
