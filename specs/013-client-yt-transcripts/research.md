# Research: Client-Side YouTube Transcript Fetching

**Feature**: [spec.md](spec.md) | **Date**: 2026-07-12

## R1: How does `youtube-caption-extractor` fetch captions?

### Decision

Port the two-step approach directly to Dart:

1. **POST to YouTube InnerTube API** (`https://youtubei.googleapis.com/youtubei/v1/player`) with spoofed client profiles (IOS, ANDROID_VR, MWEB) in sequence until one returns a playable response with `captionTracks`.
2. **GET the track's `baseUrl`** with `&fmt=json3` appended, parse the JSON structure into `TranscriptLine` segments.

### Rationale

The library is ~200 lines of TypeScript that map cleanly to Dart. No DOM, no WebView, no scraping — two HTTP calls + JSON parsing. The existing codebase already has precedent for direct YouTube HTTP calls with custom User-Agent headers (`YoutubeFetch` in `lib/features/discover/data/youtube_fetch.dart`).

### Alternatives Considered

- **WebView-based caption extraction**: Inject JS to read `video.textTracks` — unreliable across platforms, requires the WebView to be loaded with the video playing, fragile.
- **Keep worker as sole source**: Defeats the purpose of client-side fetching and retains the server bottleneck.
- **Use yt-dlp binary**: Requires bundling a native binary per platform, heavy dependency, overkill for one API call.

---

## R2: How should client profiles be configured?

### Decision

Three-tier configuration:

1. **Built-in defaults**: Hardcoded in Dart matching the current `youtube-caption-extractor` profiles (IOS `20.10.4`, ANDROID_VR `1.62.20`, MWEB `2.20251209.01.00`).
2. **Worker config endpoint**: `GET /youtube/client-profiles` returns an up-to-date JSON array of profiles. Fetched at app startup and periodically (e.g., every 24h).
3. **Local cache**: Store the last-fetched profiles in Drift settings (JSON blob under a new key). If the worker is unreachable, fall back to cached, then built-in.

### Rationale

YouTube changes client versions periodically (the TS library notes they track yt-dlp commits). A remote config lets us update without an app release. Built-in defaults prevent bricking when both worker and cache are unavailable.

### Alternatives Considered

- **Hardcoded only**: Fragile — requires app update when YouTube changes.
- **Worker poll on every fetch**: Adds latency to every transcript request.
- **App-wide version manifest**: The existing `GET dl.enjoy.bot/player/latest.json` pattern could work but mixes concerns; a dedicated worker endpoint is cleaner.

---

## R3: What should the worker API contract be?

### Decision

Three new/replacement endpoints on the worker:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/youtube/transcripts` | GET | Lookup cached transcript by `videoId` + `language` |
| `/youtube/transcripts` | POST | Upload client-fetched transcript for caching (body includes videoId, language, source, timeline) |
| `/youtube/client-profiles` | GET | Return current client profile versions |

The existing `POST /youtube/transcripts` (poll-based fetch+translate) is **deprecated** but kept for backward compatibility. The separate translation endpoint (`POST /translations`) remains unchanged.

### Rationale

The POST endpoint becomes upload-only (the client pushes results up). The GET endpoint is a simple cache lookup — no long-poll, no generation, no Apify fallback. This drastically simplifies the worker. Profiles serve a dual purpose: configuration relay and version synchronization.

### Alternatives Considered

- **Single POST with mode flag**: Overloads the endpoint, harder to reason about cache behavior.
- **Separate upload service (S3/R2)**: More infrastructure, less integrated with existing Enjoy auth.
- **No upload at all**: Loses cross-device caching benefit; every client hits YouTube independently.

---

## R4: How should the fallback chain be implemented?

### Decision

Extend `TranscriptRepository.fetchCloudTranscripts()` with a three-tier chain:

```
local persistence (Drift) → worker GET cache → client-side direct fetch
```

Each tier is tried only if the previous returns "no data" (not "error"). On a successful direct fetch, the transcript is asynchronously uploaded to the worker cache via POST (best-effort, non-blocking).

### Rationale

This preserves the existing local-persistence check (already in `TranscriptFetchCtrl._hydrateFromPersisted()`). The worker GET replaces the old worker POST/poll as the first network path. The direct fetch is the final fallback. Upload ensures the worker cache warms up for future sessions.

### Alternatives Considered

- **Parallel fetch (race worker vs direct)**: Wastes bandwidth, no latency benefit since local+worker are near-instant for cache hits.
- **Direct-first, worker as backup**: Loses the worker cache benefit — the worker is faster for pre-cached videos.
- **Local-only**: Loses cross-device and fresh-fetch benefits.

---

## R5: What packages are needed for HTML entity/strip in Dart?

### Decision

Use `dart:convert`'s built-in `HtmlUnescape` for entity decoding (equivalent to `he.decode` in the TS library) and a simple `RegExp(r'<[^>]*>')` for tag stripping (equivalent to `striptags` in the TS library). No new dependencies needed.

### Rationale

`dart:convert` provides `HtmlUnescape` out of the box. Tag stripping via regex is a one-liner sufficient for YouTube's caption markup (which only contains simple `<b>`, `<i>`, `<font>` tags). `package:html` is not in `pubspec.yaml` and adding it for two trivial operations is unnecessary weight.

### Alternatives Considered

- **`package:html`**: Adds a dependency for `parseFragment(...).text`. The caption HTML is simple enough that a regex suffices.
- **Manual entity table**: Reinventing entity decoding is error-prone; `dart:convert`'s `HtmlUnescape` handles all standard entities correctly.

---

## R6: How does the `json3` caption format map to `TranscriptLine`?

### Decision

Parse the `json3` response directly into `List<TranscriptLine>`:

```dart
// json3 response structure:
// { "events": [{ "tStartMs": 0, "dDurationMs": 3000, "segs": [{"utf8": "text"}], "aAppend": 0 }] }

// For each event:
// - Skip if aAppend == 1
// - Join segs[].utf8 → decode HTML entities → strip tags → trim
// - TranscriptLine(text: cleaned, startMs: tStartMs, durationMs: dDurationMs)
```

### Rationale

The `json3` format maps directly to `TranscriptLine` fields. The `tStartMs` and `dDurationMs` are already in milliseconds, matching `TranscriptLine.startMs` and `TranscriptLine.durationMs`. No unit conversion needed.

### Alternatives Considered

- **xml format**: The TS library used XML parsing in earlier versions; `json3` is more reliable for multi-line and special-character edge cases.
- **srv1/srv2/srv3 formats**: Other YouTube caption formats exist but `json3` is the most structured and stable.

---

## R7: How to handle the uploaded transcript format vs worker expectations?

### Decision

Upload body matches the existing worker transcript format:

```json
{
  "videoId": "dQw4w9WgXcQ",
  "language": "en",
  "source": "official",
  "timeline": [{"text": "...", "start": 0, "duration": 3000}],
  "metadata": {"title": "..."}
}
```

This is structurally identical to what the old `POST /youtube/transcripts` returned in `"ready"` responses (single-language path). The worker stores it as-is and returns it via GET.

### Rationale

Reuses the existing response format that the client already knows how to parse. The worker's cache layer is simply store-and-retrieve — no transformation needed.

---

## R8: What happens to the existing polling-based worker flow?

### Decision

The old `POST /youtube/transcripts` (poll-based fetch + translate) remains functional but the **client no longer calls it** for transcript fetching. The `YoutubeTranscriptsClient` interface gets new methods:

```dart
abstract class YoutubeTranscriptsClient {
  // Existing (deprecated but kept for backward compat)
  Future<Map<String, dynamic>> pollTranscript({...});
  Future<Map<String, dynamic>> pollTranscripts({...});
  
  // New
  Future<Map<String, dynamic>?> getCachedTranscript({required String videoId, required String language});
  Future<void> uploadTranscript({required Map<String, dynamic> transcript});
  Future<List<ClientProfile>> fetchClientProfiles();
}
```

A new implementation `YoutubeDirectClient` handles the direct YouTube fetch (not through `YoutubeTranscriptsClient` — it's a separate concern).

### Rationale

Keeps the interface extensible and the old methods available for compatibility. The `TranscriptRepository` is the orchestrator that chooses which path to use.

---

## Unresolved

- **Worker API implementation**: The new GET/upload/profile endpoints require server-side work. This plan defines the client-side contract; server implementation is coordinated separately. The fallback chain handles worker unavailability gracefully.
