# Data Model: Client-Side YouTube Transcript Fetching

**Feature**: [spec.md](spec.md) | **Date**: 2026-07-12

## Entities

### ClientProfile

Configuration for impersonating a YouTube client when calling the InnerTube API.

| Field | Type | Description |
|-------|------|-------------|
| `name` | String | Human-readable identifier: `"ios"`, `"android_vr"`, `"mweb"` |
| `clientName` | String | InnerTube client name sent in request body and `X-YouTube-Client-Name` header |
| `clientVersion` | String | Version string sent in request body and `X-YouTube-Client-Version` header |
| `clientNameHeader` | String | Numeric client ID for `X-YouTube-Client-Name` header (e.g., `"5"` for IOS) |
| `userAgent` | String | `User-Agent` header value |
| `context` | Map\<String, String\> | Device context fields: `deviceMake`, `deviceModel`, `platform`, `osName`, `osVersion`, `androidSdkVersion` |

**Storage**: Cached as JSON array in Drift `settings` table under key `youtube.client_profiles_v1`. Built-in defaults exist as a compile-time constant.

**Validation**: At least one profile with `clientName`, `clientVersion`, and `userAgent` populated.

---

### CaptionTrack

A caption track descriptor extracted from the InnerTube player response.

| Field | Type | Description |
|-------|------|-------------|
| `baseUrl` | String | URL for fetching the timed text data |
| `vssId` | String? | Track selector (e.g., `".en"` for manual, `"a.en"` for auto) |
| `languageCode` | String? | ISO language code |
| `kind` | String? | `"asr"` (auto-generated) or absent (manual) |

**Lifecycle**: Transient — extracted from InnerTube JSON response, used to select and fetch a track, not persisted.

---

### CaptionFetchResult

Outcome of a direct YouTube caption fetch attempt.

| Field | Type | Description |
|-------|------|-------------|
| `subtitles` | List\<TranscriptLine\> | Parsed caption segments (empty if none found) |
| `source` | String | `"official"` or `"auto"` — determined by the selected track's `vssId` |
| `language` | String | Language code of the fetched track |
| `fetchProfile` | String | Which client profile succeeded (e.g., `"ios"`) |
| `error` | String? | Error message if the fetch failed at any step |

**Lifecycle**: Transient — produced by `YoutubeCaptionFetcher`, consumed by `TranscriptRepository` for persistence.

---

### TranscriptFetchResult (extended)

The existing `TranscriptResolveResult` and `TranscriptCloudFetchResult` remain. A new domain concept is added:

**FetchSource** enum: `local`, `worker`, `directYoutube`

Added to the existing fetch state tracking to differentiate where a transcript came from. This is surfaced in the `TranscriptFetchUiState` (or a companion field) so the UI can show appropriate source attribution.

---

## State Transitions

### Transcript Fetch per Media Item

```
[Video Opened]
     │
     ▼
┌──────────────┐    has tracks    ┌──────────┐
│  Local Check │ ────────────────→│  Display  │
│  (Drift)     │                  │  (idle)   │
└──────┬───────┘                  └──────────┘
       │ no tracks
       ▼
┌──────────────┐    cache hit     ┌──────────┐
│ Worker GET   │ ────────────────→│  Display  │──→ Upload (async, no-op if already cached)
│ Cache Lookup │                  │ (success) │
└──────┬───────┘                  └──────────┘
       │ cache miss / error
       ▼
┌──────────────┐    success       ┌──────────┐
│ Direct       │ ────────────────→│  Display  │──→ Upload to worker (async, best-effort)
│ YouTube Fetch│                  │ (success) │
└──────┬───────┘                  └──────────┘
       │ all profiles fail
       ▼
┌──────────────┐
│ No Transcript│
│ Available    │
└──────────────┘
```

### Client Profile Refresh

```
[App Start]
     │
     ▼
┌──────────────┐    success       ┌──────────────┐
│ Worker GET   │ ────────────────→│ Persist to    │
│ /client-     │                  │ settings DB   │
│ profiles     │                  │ (cache 24h)   │
└──────┬───────┘                  └──────────────┘
       │ error
       ▼
┌──────────────┐    hit           ┌──────────────┐
│ Check local  │ ────────────────→│ Use cached    │
│ settings     │                  │ profiles      │
└──────┬───────┘                  └──────────────┘
       │ miss
       ▼
┌──────────────┐
│ Use built-in  │
│ defaults      │
└──────────────┘
```

---

## Database Changes

### New Settings Key

| Key | Type | Purpose |
|-----|------|---------|
| `youtube.client_profiles_v1` | TEXT (JSON) | Cached client profiles array from worker |

### Modified Table: `transcript_fetch_states`

No schema changes. The existing `lastStatus` (`success`/`empty`/`error`) covers all fetch sources. The `lastFetchedAt` timestamp is set regardless of which source produced the result.

### No New Tables

The existing `transcripts` table already stores all transcript data. New `source` values are not needed — the `"official"` and `"auto"` values from YouTube's API match the existing enum. Worker-fetched and directly-fetched transcripts are stored identically.
