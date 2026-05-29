## Context

Enjoy Player supports YouTube playback via WebView (ADR-0015) and library import via pasted URL/oEmbed (`importYoutubeVideo`). There is no in-app content discovery: Home and Library empty states only offer file or URL import. Users who lack a specific video must leave the app to browse YouTube.

YouTube exposes public Atom RSS feeds per channel (`https://www.youtube.com/feeds/videos.xml?channel_id=UC…`), returning ~15 recent uploads with video id, title, published date, and thumbnail. This is sufficient for a browse-and-add workflow without YouTube Data API keys or OAuth.

The app is local-first (Drift), uses feature-first layering, and currently performs destructive schema migrations on bump — any new tables require a schema version increment with documented data-loss risk.

## Goals / Non-Goals

**Goals:**

- Provide a **Discover** shell route where users browse recommended channels and subscribed channel feeds.
- Bundle a **curated recommended-channels catalog** (static asset) oriented toward language-learning practice (clear speech, captions common).
- Allow **local channel subscriptions** (Enjoy-only; not synced to YouTube account).
- Fetch and cache **RSS feed entries** locally; show a merged timeline sorted by `published_at`.
- **Add to library** from any feed tile via existing `MediaLibraryRepository.importYoutubeVideo()`.
- Refresh feeds on **app launch** and on a **periodic interval** (e.g. 6–12 hours) while the app is running.
- Surface a **starter discovery CTA** on Home when the library is empty.
- Work for **guest and signed-in** users (add-to-library sync behavior unchanged from existing import).

**Non-Goals:**

- YouTube Data API, OAuth channel subscription, or Worker-proxied RSS.
- Cross-device subscription sync (new sync entity deferred).
- Caption-availability pre-check in the feed UI (rely on curation + existing post-import transcript flow).
- Shorts filtering, duration filtering, or language auto-tagging from RSS.
- Replacing paste-URL import (remains in Import sheet).

## Decisions

### 1. Feature module: `lib/features/discover/`

**Decision:** New feature slice with `domain/`, `data/`, `application/`, `presentation/` per architecture rules.

**Rationale:** Discover is a distinct user journey (browse → add) separate from library ownership and playback. Keeps feature ↔ feature imports minimal; library import is called via repository provider.

**Alternative considered:** Extend `library/` — rejected because feed cache and subscriptions are not library media and would blur domain boundaries.

### 2. Drift tables separate from `videos`

**Decision:** Two new tables:

| Table | Purpose |
|-------|---------|
| `youtube_channel_subscriptions` | `channel_id` (PK), `display_name`, `thumbnail_url`, `source` (`recommended` \| `user`), `subscribed_at`, `last_fetched_at` |
| `youtube_feed_entries` | Composite PK `(video_id, channel_id)`; `title`, `thumbnail_url`, `published_at`, `fetched_at` |

**Rationale:** Feed entries are ephemeral discovery cache (~15 per channel per fetch). Library `videos` rows are created only on explicit "Add to library." Avoids polluting library lists and sync queue with unchosen items.

**Alternative considered:** Store feed as JSON blob on subscription row — rejected; harder to query merged timeline and dedupe across channels.

### 3. RSS fetch on client (native HTTP)

**Decision:** Flutter app fetches RSS directly using `package:http` (same stack as existing API client). Parse Atom XML in `discover/data/youtube_rss_parser.dart`.

**Rationale:** No CORS on mobile/desktop native. Avoids new Worker routes and latency. RSS is public and cache-friendly.

**Alternative considered:** Worker proxy — deferred; adds deployment coupling without MVP benefit.

### 4. Channel ID resolution (best-effort)

**Decision:** Accept inputs: `channel_id` (UC…), `/channel/UC…`, `/c/CustomName`, `/@handle`. Resolver fetches the channel page HTML (or canonical redirect) and extracts `channel_id` via regex on `browse?channel_id=` or `"channelId":"…"` patterns. Fail with user-visible error if unresolved.

**Rationale:** Users think in URLs/handles, not raw UC ids. Recommended catalog ships pre-resolved `channel_id` to skip resolution for bundled channels.

**Alternative considered:** Require UC id only — too hostile for subscribe UX.

### 5. Refresh strategy

**Decision:**

- `DiscoverFeedRefreshScheduler` (Riverpod, app-level) triggers refresh on:
  - App start (after DB ready), debounced
  - Manual pull-to-refresh on Discover screen
  - Timer every 8 hours while app foregrounded (configurable constant)
- Skip channels fetched within last 1 hour unless manual refresh.
- Refresh all subscribed + recommended channels that user has "followed" (recommended channels auto-subscribed on first visit optional — see Open Questions).

**Rationale:** RSS updates infrequently; aggressive polling wastes battery and may trigger rate limits.

### 6. UI placement

**Decision:**

- New shell nav item **Discover** → `/discover` (icon: explore/outbox pattern consistent with editorial shell).
- Discover screen sections:
  1. **Recommended** — horizontal channel chips from asset catalog; tap → channel feed
  2. **Subscriptions** — user's subscribed channels
  3. **Timeline** — merged feed entries (all subscribed channels), infinite-style list with `MediaCard`-like tiles
- Channel detail: vertical list of that channel's cached entries.
- Home empty state: secondary action "Browse recommended" → `/discover` (keep Import as primary).

**Rationale:** Dedicated tab matches ongoing discovery use case; Home hook solves cold start without hiding Discover later.

### 7. Add to library integration

**Decision:** Feed tile actions:

- **Add to library** → `importYoutubeVideo(videoId)` → invalidate `libraryMediaProvider` → optional snackbar → do not auto-navigate to player (user may browse more). If already in library, show "In library" disabled state (check `getYoutubeByVid`).
- **Play** (optional secondary) — only if already imported; opens player route.

**Rationale:** Reuses proven import path including oEmbed, sync enqueue, and duplicate detection.

### 8. Recommended catalog as asset

**Decision:** `assets/discover/recommended_channels.json` loaded at startup into memory. Schema:

```json
{
  "channels": [
    {
      "channelId": "UC…",
      "name": "TED",
      "description": "…",
      "language": "en",
      "tags": ["clear-speech", "captions-common"]
    }
  ]
}
```

Ship 5–10 channels for v1 (TED, TED-Ed, BBC Learning English, VOA Learning English, English with Lucy — exact list finalized at implementation).

**Rationale:** Zero backend; editorial control; updatable per release.

### 9. Schema migration

**Decision:** Bump `schemaVersion` in `AppDatabase` with new tables via existing `onUpgrade` (destructive recreate until incremental migrations exist — same policy as today). Document in ADR and release notes.

**Rationale:** Matches current project reality; incremental migration is a separate initiative.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| YouTube changes or blocks RSS / HTML scraping for channel resolution | Recommended catalog uses hard-coded `channel_id`; resolver errors are explicit; monitor in support |
| Feed shows videos without captions | Curate recommended channels; post-add transcript empty state already exists; future caption badge |
| ~15 video limit per channel | Accept for MVP; manual refresh; user can subscribe to many channels |
| Destructive schema bump clears library | Same as any schema change today — call out in changelog; consider migration follow-up |
| RSS lacks duration | oEmbed on import; lazy duration from WebView after first play (existing behavior) |
| Duplicate entries across channels | Composite PK `(video_id, channel_id)`; timeline dedupes same video_id in UI if ever duplicated |

## Migration Plan

1. Land Drift schema + feature module behind complete UI (no partial route in production).
2. Bump schema version in a dedicated release note warning about local data reset if destructive migration applies.
3. No server deployment required.
4. Rollback: revert app version; local discover tables dropped on downgrade only if user reinstalls — standard mobile rollback.

## Open Questions

1. **Auto-subscribe recommended channels on first launch?** Default lean: show recommended but require explicit Subscribe tap to avoid noisy timeline.
2. **Subscribe from recommended vs separate paste-URL flow?** v1: both — paste channel URL sheet on Discover app bar.
3. **Exact recommended channel list** — finalize during implementation with product pass (English-learning focus for v1).
