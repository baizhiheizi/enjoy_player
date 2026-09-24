# ADR-0015: YouTube playback via WebView + HTML5 video

## Status

Accepted

> **Wording refresh** (issue #751, post-#720): decision 2 restated to the
> capability-interface split and the presentation-owned stage (issues #664 /
> #720); decision 3 gains the single identity resolver. **No decision
> change.**

## Context

Enjoy Player historically targeted **local-first** media only ([ADR-0005](0005-mvp-scope-local-only.md)) and a **single `media_kit`** playback surface ([ADR-0003](0003-player-core-media-kit.md)). Users want **YouTube** videos for the same transcript + echo / shadow-reading workflows without downloading media files.

YouTube **embed** playback is unreliable inside embedded WebViews (policy errors). A proven approach loads the **mobile watch page** (`m.youtube.com/watch?v=…`), drives the page’s HTML5 `<video>` via JavaScript, and hides chrome with injected CSS.

## Decision

1. **Dual engines behind `PlayerEngine`**  
   - **`MediaKitPlayerEngine`** remains the **only** owner of `package:media_kit` `Player()` for local files and generic HTTP(S) URLs.  
   - **`YouTubePlayerEngine`** uses **`flutter_inappwebview`** to render and control playback; it **must not** construct `media_kit` `Player()`.

2. **`PlayerEngine` is the abstraction** for transport and its streams (`position`, `duration`, `playing`, `buffering`, `completed`) plus the swap-lifecycle hooks (`awaitSurfaceReady` / `awaitSurfaceDetached` / `prepareNativeBackend` / …) — *transport + streams + swap-lifecycle only* (issue #720). What only some engines can do lives in capability interfaces (`player_engine_capabilities.dart`): embedded subtitle control (`SubtitleTrackControl`, `media_kit` `Tracks` behind it), frame capture (`PosterCapture`, media_kit only; YouTube returns null), the YouTube playback marker, and `PlayerEngineMetadata`. The video widget subtree is **not** part of the engine contract either: presentation maps engine identity to a stage (`buildPlayerVideoStage`, issue #664) and stage mounting stays with the permanent `PlayerSurfaceHost` ([ADR-0057](0057-permanent-player-surface-host.md)).

3. **Engine selection** happens when opening a media row: rows with `videos.provider == 'youtube'` resolve to `YoutubePlayableSource` and bind `YouTubePlayerEngine`; others use `MediaKitPlayerEngine`. The active engine is swapped when navigating between different source kinds, and *which* engine is live resolves through the single `PlayerEngineIdentity` precedence — test double · owned · lazy default (issue #751).

4. **Import**  
   - Users paste a URL or id; we parse the canonical **11-character video id**, store `provider='youtube'`, `vid=<id>`, optional `mediaUrl` canonical watch URL for sync.  
   - **Metadata**: best-effort **YouTube oEmbed**; duration may be filled lazily after first decode from the HTML5 `<video>` metadata stream.

5. **Login / ads**  
   - Optional sign-in uses Google **ServiceLogin** → `m.youtube.com`, sharing the WebView **cookie jar**. Logged-in state is inferred from cookies (`LOGIN_INFO` / `SID` on `https://m.youtube.com`).  
   - **Logout** uses `CookieManager.deleteAllCookies()` — **not** scoped to YouTube-only (cross-platform limitation); document for users.  
   - **Player WebView navigation**: Google account URLs are cancelled during watch-page playback; explicit login uses `/youtube/login` only — see [ADR-0025](0025-youtube-player-block-google-signin-nav.md).

6. **Transcripts**  
   - Cloud transcripts continue via existing **`GET /api/v1/transcripts`** with **`targetId` = local Drift row id** after sync. Local subtitle file import is hidden for YouTube rows.

## Consequences

- **Supersedes** (partial): ADR-0005 “local files only” for **YouTube-linked** rows; local files remain primary. ADR-0003 “sole player engine” becomes **“sole media_kit Player owner”** — YouTube does not use `media_kit`.
- **Echo clamp granularity**: YouTube position updates ~250 ms while polling; possible overshoot vs media_kit — acceptable for MVP.
- **Platforms**: `flutter_inappwebview` supports Android, iOS, macOS, Windows; Linux WebView support may be limited — verify before enabling Linux builds.
- **Recording preview** (`recording_preview_player.dart`) remains a separate `media_kit` `Player` instance per ADR-0003 exception for preview-only use.

## References

- Feature notes: `docs/features/youtube.md`
