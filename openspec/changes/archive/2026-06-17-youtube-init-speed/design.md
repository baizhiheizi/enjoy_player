## Context

YouTube playback uses `YoutubePlayerEngine` with `flutter_inappwebview` loading `https://m.youtube.com/watch?v=<vid>` and controlling the page HTML5 `<video>` (ADR-0015). Embed URLs (`youtube-nocookie.com/embed/…`) fail with Error 153 in native WebViews due to missing embed identity / Referer — confirmed in exploration; embed migration is out of scope.

Current init timeline:

```
Route /player/:id
  → ExpandedPlayerLoadingBody (skeleton)
  → openMedia(): engine swap, engine.open(), seek restore, publish session
  → ExpandedPlayerChromeBody mounts buildVideoStage()
  → InAppWebView cold-starts + loads watch page + inject + first frame
```

Pain points:

1. WebView creation waits until session publish — no overlap with `openMedia()`.
2. `PlayerController.clear()` disposes `YoutubePlayerEngine` entirely — cold WebView on every dismiss.
3. Video stage shows black while WebView loads — thumbnails exist in Drift but are not shown on the stage.
4. `warmVideoSurface()` is a no-op for YouTube (MediaKit only uses it today).

Constraints to preserve:

- Single long-lived WebView per YouTube engine (no `Key` by `videoId`; navigate via `loadWatchPage`).
- Shared cookie jar with YouTube login WebView (mobile Chrome UA).
- Echo seek/rate/position semantics unchanged.
- No new dependencies.

## Goals / Non-Goals

**Goals:**

- Reduce **time-to-first-frame** by overlapping WebView cold-start with `openMedia()` work.
- Improve **perceived init** with thumbnail artwork during loading and buffering.
- Reuse a **warm WebView process** across YouTube sessions within an app run.
- Optional **pre-warm on library tap** before route navigation.
- Add fine-level timing logs for init phases.

**Non-Goals:**

- Switching to embed / IFrame API / `youtube_player_iframe`.
- Changing playback URL (`m.youtube.com/watch`).
- Altering echo clamp, ad-reload inject, or login flow.
- Linux WebView support.
- Persisting warm WebView across app restarts.

## Decisions

### 1. Poster overlay on video stage (not a separate route)

**Decision:** Wrap `_YoutubeWebViewHost` in a `Stack`. When `buffering == true`, show a full-bleed `Image.network` poster above the WebView (opacity fade-out on first `canplay`/`playing`).

**Rationale:** Thumbnails are already stored (oEmbed/RSS). Zero YouTube cost; instant visual feedback like Folo's static thumb.

**Poster URL resolution:** Reuse `remoteThumbnailForCard(thumbnailPath, youtubeVideoId: vid, mediaUrl: …)` from session/chrome metadata passed into the engine or read from `PlaybackSession.thumbnailUrl`.

**Alternative considered:** Replace WebView with thumbnail until user taps play — rejected; Enjoy opens directly into playback + echo, not a click-to-play modal.

### 2. YouTube-aware loading body

**Decision:** When `openMediaActionProvider` is loading and the target row is `provider == 'youtube'`, show the row's remote thumbnail (with MQ fallback) centered in `ExpandedPlayerLoadingBody` instead of only `SkeletonAppBootstrap`.

**Rationale:** Covers the gap before session publish when the video stage is not mounted.

**Implementation:** `ExpandedPlayerScreen` reads video row (or passes thumbnail from route extra) — prefer a small `youtubeOpenPreviewProvider(mediaId)` that loads Drift row once.

### 3. Early WebView mount via shared engine host

**Decision:** Introduce a **persistent off-tree WebView host** owned by `YoutubePlayerEngine` (or a dedicated `YoutubeWebViewRegistry` provider) that can mount before `ExpandedPlayerChromeBody`.

Flow:

```
openMedia() starts
  → ensureEngineForPlayableSource (YoutubePlayerEngine)
  → engine.open(source) sets videoId
  → engine.ensureWebViewAttached()  // NEW: signals host to mount if not mounted
  → (parallel) DB/seek/session work continues
ExpandedPlayerChromeBody.buildVideoStage()
  → reuses same WebView via OverlayPortal / global host (not a second instance)
```

**Rationale:** Overlaps WebView process spawn + initial navigation with seek restore and side effects without publishing session early.

**Alternative considered:** Publish `PlaybackSession` earlier with `buffering: true` — rejected; would flash transport chrome and complicate open-generation races.

**Mechanism:** Move `_YoutubeWebViewHost` to a `YoutubeWebViewLayer` inserted under the player route via `Overlay` or a root-level `Stack` keyed by `playerEngineRevProvider`. `buildVideoStage()` returns a **placeholder `SizedBox`** with the same constraints; the actual WebView is positioned with `CompositedTransformTarget` / `Follower` (or simpler: `Stack` in `VideoPlayerLayout` where stage slot hosts a `YoutubeVideoStageSlot` widget that the engine fills).

**Simpler v1 (preferred for first PR):** Mount `_YoutubeWebViewHost` inside `ExpandedPlayerLoadingBody` when YouTube open is in-flight (same engine instance from `playerEngineProvider`), hidden behind thumbnail; on session publish, `VideoPlayerLayout` continues using `buildVideoStage()` which returns the **same** host widget (extract to shared widget, no second WebView).

### 4. Warm YouTube engine on `clear()`

**Decision:** `PlayerController.clear()` stops playback and clears session but **does not dispose** `YoutubePlayerEngine` when no engine swap is needed. Dispose only when:

- Opening a non-YouTube source (`ensureEngineForPlayableSource` swap to MediaKit), or
- Controller/provider disposal (app teardown).

After stop, engine loads `about:blank` (or pauses on last frame) to release media decoder while keeping WebView process warm.

**Rationale:** Matches Folo's persistent renderer; avoids repeated cold-start on dismiss → re-open same video.

**Trade-off:** ~50–150 MB memory retained while app runs — acceptable for desktop; monitor on mobile.

**Alternative considered:** Always dispose — current behavior; rejected for init speed goal.

### 5. `warmVideoSurface()` for YouTube

**Decision:** Implement `YoutubePlayerEngine.warmVideoSurface()` to call `ensureWebViewAttached()` and load `about:blank` if no video is open yet.

**Trigger:** Library/discover row `onTap` for `provider == 'youtube'` calls `ref.read(playerControllerProvider.notifier).warmYoutubeSurface()` before `context.push('/player/…')`.

**Rationale:** Overlaps WebView cold-start with route transition animation.

**Non-goal:** Warm on hover (desktop-only nicety — defer).

### 6. Init timing logs

**Decision:** Log at `fine` level in `YoutubePlayerEngine`:

- `webview_created`
- `load_stop` (with URL)
- `first_playing` (first `playing` event)

Use monotonic clock deltas from `openMedia` start (pass optional `openGeneration` marker).

No user-visible metrics UI in v1.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Two WebView instances if loading body and chrome both mount hosts | Single shared host widget; guard with `engine.webViewMounted` flag; tests assert one controller |
| Warm engine retains memory | Document in `docs/features/youtube.md`; dispose on engine swap |
| Poster hides WebView errors | Fade poster only on `canplay`/`playing`; show error state if `onVideoEvent error` and still buffering after timeout |
| `about:blank` after clear breaks cookie session | Do not clear cookies; only navigate to blank or pause — login jar unchanged |
| CompositedTransform complexity | Start with v1 simpler approach (host in loading body → same widget in stage) |
| Windows `MissingPluginException` on stale controller | Existing handling retained; warm path must not call `loadUrl` on disposed controller |

## Migration Plan

1. Ship behind no flag (behavior improvement only).
2. Update `docs/features/youtube.md` with poster + warm-session semantics.
3. No DB migration.
4. Rollback: revert `clear()` retention and remove early mount — poster overlay is independently safe.

## Open Questions

- **Mobile memory:** Should warm retention be desktop-only (`Platform.isWindows \|\| Platform.isMacOS`) in v1?
- **Poster on audio-only YouTube rows:** N/A — all YouTube rows are video.
- **Cloud library open:** Ensure thumbnail URL is available on `PlaybackSession` for synced YouTube rows without local thumb file.
