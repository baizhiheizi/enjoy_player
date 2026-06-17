## 1. Engine lifecycle and warm session

- [x] 1.1 Add `ensureWebViewAttached()` and `webViewMounted` guard on `YoutubePlayerEngine`; call from `open()` after setting `videoId`
- [x] 1.2 Implement `warmVideoSurface()` to pre-mount WebView and load `about:blank` when idle
- [x] 1.3 Change `PlayerController.clear()` to stop YouTube playback without disposing `YoutubePlayerEngine`; dispose only on MediaKit swap or provider teardown
- [x] 1.4 After YouTube stop/clear, navigate WebView to `about:blank` (or equivalent idle state) without clearing cookies
- [x] 1.5 Add fine-level init timing logs (`webview_created`, `load_stop`, `first_playing`) in `YoutubePlayerEngine`

## 2. Shared WebView host (early mount)

- [x] 2.1 Extract `_YoutubeWebViewHost` to a shared widget usable from loading body and video stage
- [x] 2.2 Mount shared host from `ExpandedPlayerLoadingBody` when YouTube open is in-flight (same engine instance)
- [x] 2.3 Ensure `buildVideoStage()` reuses the same host — no second `InAppWebView` on session publish
- [x] 2.4 Add widget or unit test asserting single WebView controller per engine across loading → chrome transition

## 3. Thumbnail poster overlay

- [x] 3.1 Pass poster URL into video stage (from `PlaybackSession.thumbnailUrl` or `remoteThumbnailForCard` + vid fallback)
- [x] 3.2 Wrap YouTube video stage in `Stack` with full-bleed poster `Image.network` while `buffering == true`
- [x] 3.3 Fade out or remove poster on first `playing` / buffering cleared; handle mq fallback for failed maxres load
- [x] 3.4 Add `youtubeOpenPreviewProvider(mediaId)` (or equivalent) to resolve row thumbnail during loading

## 4. Loading body artwork

- [x] 4.1 Update `ExpandedPlayerLoadingBody` / `ExpandedPlayerScreen` to show YouTube thumbnail when target row is `provider == 'youtube'`
- [x] 4.2 Keep generic skeleton for non-YouTube opens

## 5. Library pre-warm hook

- [x] 5.1 Add `PlayerController.warmYoutubeSurface()` delegating to engine `warmVideoSurface()`
- [x] 5.2 Call pre-warm on YouTube row tap in library and discover before player navigation (best-effort, non-blocking)

## 6. Documentation and verification

- [x] 6.1 Update `docs/features/youtube.md` with poster overlay, early mount, and warm-session behavior
- [x] 6.2 Add/update tests for `clear()` YouTube retention and engine swap disposal
- [x] 6.3 Run `flutter analyze` and `flutter test` on touched packages
