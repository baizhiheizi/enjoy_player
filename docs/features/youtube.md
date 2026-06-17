# YouTube playback

## Summary

Users **Import → From YouTube URL** and paste a watch URL, short URL, embed URL, or raw video id. The app stores a `videos` row with `provider: youtube` and `vid` set to the canonical id. Playback uses **`flutter_inappwebview`** loading `https://m.youtube.com/watch?v=<vid>` and controlling the page HTML5 `<video>` (not the iframe embed API — see ADR-0015).

## Metadata

- **Title / thumbnail**: best-effort [YouTube oEmbed](https://oembed.com/) on import; if it fails, title falls back to `YouTube video <id>`. **Discover → Add to library** passes RSS title/thumbnail when available. When a row still has placeholder title or missing thumbnail, opening the player triggers a **lazy oEmbed retry** after the WebView reports playback-ready (buffering cleared or duration known).
- **Duration**: filled lazily when the WebView reports `loadedmetadata` / duration stream and the row still has `durationSeconds == 0`.

## Login

Optional **YouTube / Google** sign-in opens a dedicated WebView starting at Google ServiceLogin with `continue=https://m.youtube.com/`. Session cookies (`LOGIN_INFO` / `SID`) on `m.youtube.com` determine logged-in state. Logout clears **all** WebView cookies (see ADR-0015).

## Transcripts

Only the **Enjoy API** path (`GET /api/v1/transcripts` with local row `targetId`) — same as other videos. The row must sync to the cloud for server-side transcripts to attach. Local subtitle file import is disabled for YouTube rows.

When the **worker** transcript poll returns `status: failed`, the app records a **fetched** state so the UI does not spin forever; users can retry later (e.g. after captions exist or policy changes) without an infinite poll loop. See [`transcript_repository.dart`](../../lib/features/transcript/data/transcript_repository.dart).

## Limitations

- **Init speed**: Thumbnail artwork shows during player open and while the WebView buffers. The shared WebView may mount during `openMedia()` (overlapping cold-start with DB work) and is **kept warm** after dismiss until the user opens non-YouTube media or the app exits. Optional pre-warm runs when tapping a YouTube row in Library or Discover. Playback still uses the mobile watch page — not embed (Error 153 in native WebViews).
- **iOS inline playback**: the WebView sets `allowsInlineMediaPlayback`, injects `playsinline` on the `<video>`, and hooks iOS native fullscreen to stay inline so the 16:9 frame stays visible for echo / shadow reading. Player and login WebViews share the same Chrome mobile `userAgent` so Google sign-in is not blocked as an insecure browser.
- Position updates while playing are polled (~250 ms); echo clamp may overshoot slightly vs `media_kit`.
- Embedded MKV/MP4 subtitle track extraction is unavailable for YouTube (no `media_kit` decode of the stream).
- Ad behavior depends on YouTube, cookies, and account; “no ads” is best-effort when signed in with Premium where applicable.
