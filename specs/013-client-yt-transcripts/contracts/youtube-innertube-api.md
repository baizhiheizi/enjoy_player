# Contract: YouTube InnerTube Caption API

**Feature**: [spec.md](../spec.md) | **Source**: youtube-caption-extractor v1.10.2

This is the external YouTube API that the Flutter client calls directly (bypassing the Enjoy Worker). No auth required; YouTube's public InnerTube endpoint.

---

## `POST https://youtubei.googleapis.com/youtubei/v1/player`

Fetches video metadata including available caption tracks.

### Request Headers

| Header | Value (IOS profile example) |
|--------|------------------------------|
| `Content-Type` | `application/json` |
| `Accept` | `*/*` |
| `User-Agent` | `com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)` |
| `X-YouTube-Client-Name` | `5` |
| `X-YouTube-Client-Version` | `20.10.4` |
| `Origin` | `https://www.youtube.com` |

### Request Body

```json
{
  "context": {
    "client": {
      "clientName": "IOS",
      "clientVersion": "20.10.4",
      "hl": "en",
      "gl": "US",
      "deviceMake": "Apple",
      "deviceModel": "iPhone16,2",
      "platform": "MOBILE",
      "osName": "iOS",
      "osVersion": "18.3.2.22D82"
    },
    "user": { "lockedSafetyMode": false },
    "request": { "useSsl": true }
  },
  "videoId": "dQw4w9WgXcQ",
  "contentCheckOk": true,
  "racyCheckOk": true
}
```

### Response (relevant fields)

```json
{
  "playabilityStatus": { "status": "OK" },
  "videoDetails": {
    "title": "Video Title",
    "shortDescription": "Description text..."
  },
  "captions": {
    "playerCaptionsTracklistRenderer": {
      "captionTracks": [
        {
          "baseUrl": "https://www.youtube.com/api/timedtext?v=dQw4w9WgXcQ&lang=en&...",
          "vssId": ".en",
          "languageCode": "en",
          "kind": ""
        },
        {
          "baseUrl": "https://www.youtube.com/api/timedtext?v=dQw4w9WgXcQ&lang=en&...",
          "vssId": "a.en",
          "languageCode": "en",
          "kind": "asr"
        }
      ]
    }
  }
}
```

### Track Selection Precedence

1. `vssId == ".{lang}"` — manual captions
2. `vssId == "a.{lang}"` — auto-generated captions
3. `languageCode == "{lang}"` — any track with matching code
4. `vssId` contains `".{lang}"` — partial match
5. First available track — fallback

---

## `GET {baseUrl}&fmt=json3`

Fetches and parses individual caption track data.

### URL Construction

Take the `baseUrl` from the selected caption track. Remove any existing `&fmt=` parameter, then append `&fmt=json3`.

### Response

```json
{
  "events": [
    {
      "tStartMs": 0,
      "dDurationMs": 3000,
      "segs": [{"utf8": "Hello world"}, {"utf8": " &amp; goodbye"}],
      "aAppend": 0
    },
    {
      "tStartMs": 3000,
      "dDurationMs": 2500,
      "segs": [{"utf8": "<b>Next</b> line"}],
      "aAppend": 0
    }
  ]
}
```

### Parsing Rules

For each event in `events`:
- Skip if `aAppend == 1` (appends to previous segment)
- Join all `segs[].utf8` values
- Decode HTML entities
- Strip HTML tags
- Trim whitespace
- Map to `{ start: tStartMs / 1000, dur: dDurationMs / 1000, text: cleaned }`

### Client Profile Fallback Chain

Try profiles in order: `ios` → `android_vr` → `mweb`. A profile succeeds when:
- HTTP response is 200
- `playabilityStatus.status == "OK"`
- `captionTracks` is non-empty (for getSubtitles) OR any playable status (for getVideoDetails)

If all profiles fail, throw with a combined error listing each attempt.
