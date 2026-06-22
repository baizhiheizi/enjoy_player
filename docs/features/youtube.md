# YouTube playback

## Summary

Users **Import → From YouTube URL** and paste a watch URL, short URL, embed URL, or raw video id. The app stores a `videos` row with `provider: youtube` and `vid` set to the canonical id. Playback uses **`flutter_inappwebview`** loading `https://m.youtube.com/watch?v=<vid>` and controlling the page HTML5 `<video>` (not the iframe embed API — see [ADR-0015](../decisions/0015-youtube-playback.md)).

## Metadata

- **Title / thumbnail**: best-effort [YouTube oEmbed](https://oembed.com/) on import; if it fails, title falls back to `YouTube video <id>`. **Discover → Add to library** passes RSS title/thumbnail when available. When a row still has placeholder title or missing thumbnail, opening the player triggers a **lazy oEmbed retry** after the WebView reports playback-ready (buffering cleared or duration known).
- **Duration**: filled lazily when the WebView reports `loadedmetadata` / duration stream and the row still has `durationSeconds == 0`.

## Login

Optional **YouTube / Google** sign-in opens a **dedicated** WebView (`/youtube/login`) starting at Google ServiceLogin with `continue=https://m.youtube.com/`. Session cookies (`LOGIN_INFO` / `SID`) on `m.youtube.com` determine logged-in state. Logout clears **all** WebView cookies (see ADR-0015).

**Session persistence**: cookies live in the app WebView profile (e.g. `%APPDATA%\Enjoy\Enjoy Player\` on Windows) and normally survive app restarts until logout or Google expires the session. Enjoy account sign-in is separate.

The **player** WebView does **not** complete Google login inline — see [Player navigation](#player-navigation) below.

## Player navigation

While a video is open, the player WebView [`shouldOverrideUrlLoading`](../../lib/features/player/application/engines/youtube/youtube_webview_host.dart) applies [`youtube_watch_navigation_policy.dart`](../../lib/features/player/application/engines/youtube/youtube_watch_navigation_policy.dart) ([ADR-0025](../decisions/0025-youtube-player-block-google-signin-nav.md)):

| Navigation | Policy |
|------------|--------|
| `m.youtube.com` / `youtube.com` / `youtu.be` watch and redirect hops | Allow |
| `consent.youtube.com`, `gstatic.com`, `googleapis.com`, other allowed Google static/consent URLs | Allow |
| **`accounts.google.com` (passive or active sign-in)** | **Cancel** |
| Unrelated origins | Cancel |

**Why**: YouTube’s mobile watch page often redirects through **passive Google sign-in** when no session cookies exist. In embedded WebViews (especially release builds), that chain can finish without a playable `<video>` — infinite loading. Blocking account navigations in the player keeps anonymous playback on the watch page; use **YouTube login** when a signed-in session is needed.

## Transcripts

Only the **Enjoy API** path (`GET /api/v1/transcripts` with local row `targetId`) — same as other videos. The row must sync to the cloud for server-side transcripts to attach. Local subtitle file import is disabled for YouTube rows.

When the **worker** transcript poll returns `status: failed`, the app records a **fetched** state so the UI does not spin forever; users can retry later (e.g. after captions exist or policy changes) without an infinite poll loop. See [`transcript_repository.dart`](../../lib/features/transcript/data/transcript_repository.dart).

## Limitations

- **Init speed**: Thumbnail artwork shows during player open and while the WebView buffers. The shared WebView may mount during `openMedia()` (overlapping cold-start with DB work) and is **kept warm** after dismiss until the user opens non-YouTube media or the app exits. Optional pre-warm runs when tapping a YouTube row in Library or Discover. Playback still uses the mobile watch page — not embed (Error 153 in native WebViews).
- **iOS inline playback**: the WebView sets `allowsInlineMediaPlayback`, injects `playsinline` on the `<video>`, and hooks iOS native fullscreen to stay inline so the 16:9 frame stays visible for echo / shadow reading. Player and login WebViews share the same Chrome mobile `userAgent` so Google sign-in is not blocked as an insecure browser.
- Position updates while playing are polled (~250 ms); echo clamp may overshoot slightly vs `media_kit`.
- Embedded MKV/MP4 subtitle track extraction is unavailable for YouTube (no `media_kit` decode of the stream).
- Ad behavior depends on YouTube, cookies, and account; “no ads” is best-effort when signed in with Premium where applicable.

## Troubleshooting (Windows release)

If YouTube stalls on loading in a **release** or installed build but works in `flutter run`:

1. Confirm you are on a build that includes ADR-0025 (blocks `accounts.google.com` in the player WebView).
2. Try **YouTube login** once, then reopen the video (establishes session cookies).
3. Compare portable `build\windows\x64\runner\Release\enjoy_player.exe` vs Program Files install (antivirus can slow first launch).

Policy rules are unit-tested in [`youtube_watch_navigation_policy_test.dart`](../../test/features/player/youtube_watch_navigation_policy_test.dart).
