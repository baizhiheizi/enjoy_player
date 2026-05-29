## Why

Enjoy Player today assumes users already have a YouTube target: they must browse externally, copy a URL, and paste it to import. That works for power users but fails the common cold-start case — someone who wants good practice material but has no specific video in mind. We need an in-app discovery path: browse channel feeds, pick a video, and add it to the library without leaving the app.

## What Changes

- Add a **Discover** surface (new shell route) for browsing YouTube content to practice with.
- Ship a **bundled recommended-channels catalog** (e.g. TED, BBC Learning English) with learner-friendly metadata.
- Let users **subscribe to YouTube channels** (Enjoy-local subscriptions, not YouTube OAuth) and view a merged **timeline feed** of recent uploads via public Atom RSS.
- Support **Add to library** from feed items, reusing existing `importYoutubeVideo()` (oEmbed metadata, Drift `videos` row, optional sync enqueue).
- Refresh feeds on app launch and on a background interval; cache entries locally in Drift (separate from library `videos`).
- Surface discovery on **Home empty state** so first-run users see starter content instead of only "Import."
- Resolve channel URLs/handles to `channel_id` for RSS (best-effort; paste channel URL as primary UX in v1).
- **Out of scope for this change**: YouTube Data API integration, cross-device subscription sync, caption-availability pre-check in feed, Shorts filtering, Worker-proxied RSS (client fetches RSS directly on native platforms).

## Capabilities

### New Capabilities

- `discover`: Recommended channels, local channel subscriptions, RSS feed fetch/cache/refresh, Discover UI, and add-to-library flow from feed entries.

### Modified Capabilities

<!-- No existing openspec specs require requirement-level changes. Library import and YouTube playback behavior stay the same; Discover adds a new entry path. -->

## Impact

- **Routing / shell**: New `/discover` route and nav item in `root_shell.dart` / `app_router.dart`.
- **Data**: New Drift tables for channel subscriptions and feed entry cache; schema version bump (note destructive migration policy in `docs/architecture.md`).
- **Features**: New `lib/features/discover/` module (domain, data, application, presentation).
- **Library**: Reuse `MediaLibraryRepository.importYoutubeVideo()` from Discover tiles; optional hook from Home empty state.
- **Networking**: HTTP client for YouTube RSS Atom feeds and channel-id resolution (no new Enjoy Worker routes).
- **Assets**: Bundled `recommended_channels.json` (or similar) under assets.
- **Localization**: New strings for Discover tab, subscribe/unsubscribe, feed empty/loading/error, add-to-library actions.
- **Docs**: New `docs/features/discover.md`; ADR for RSS-based discovery and local subscription model.
- **Tests**: RSS parser unit tests, channel resolver tests, repository refresh tests, widget tests for feed UI.
