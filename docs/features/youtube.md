# YouTube playback

## Summary

Users **Import → From YouTube URL** and paste a watch URL, short URL, embed URL, or raw video id. The app stores a `videos` row with `provider: youtube` and `vid` set to the canonical id. A **content language** is collected at import time (YouTube does not expose original language via oEmbed) and can be edited later from Library. Playback uses **`flutter_inappwebview`** loading `https://m.youtube.com/watch?v=<vid>` and controlling the page HTML5 `<video>` (not the iframe embed API — see [ADR-0015](../decisions/0015-youtube-playback.md)).

## Metadata

- **Title / thumbnail**: best-effort [YouTube oEmbed](https://oembed.com/) on import; if it fails, title falls back to `YouTube video <id>`. **Discover → Add to library** passes RSS title/thumbnail when available. When a row still has placeholder title or missing thumbnail, opening the player triggers a **lazy oEmbed retry** after the WebView reports playback-ready (buffering cleared or duration known).
- **Duration**: filled lazily when the WebView reports `loadedmetadata` / duration stream and the row still has `durationSeconds == 0`.

## Login

Optional **YouTube / Google** sign-in opens a **dedicated** WebView (`/youtube/login`) starting at Google ServiceLogin with `continue=https://m.youtube.com/`. Session cookies (`LOGIN_INFO` / `SID`) on `m.youtube.com` determine logged-in state. Logout clears **all** WebView cookies (see ADR-0015).

**Session persistence**: cookies live in the app WebView profile (`%LOCALAPPDATA%\…\WebView2` on Windows — see [`windows_webview_environment.dart`](../../lib/core/webview/windows_webview_environment.dart)) and normally survive app restarts until logout or Google expires the session. Enjoy account sign-in is separate.

The **player** WebView does **not** complete Google login inline — see [Player navigation](#player-navigation) below.

## Player navigation

While a video is open, the player WebView [`shouldOverrideUrlLoading`](../../lib/features/player/application/engines/youtube/youtube_webview_host.dart) applies [`youtube_watch_navigation_policy.dart`](../../lib/features/player/application/engines/youtube/youtube_watch_navigation_policy.dart) ([ADR-0025](../decisions/0025-youtube-player-block-google-signin-nav.md)):

| Navigation | Policy |
|------------|--------|
| `m.youtube.com` / `youtube.com` / `youtu.be` watch and redirect hops | Allow (main frame only) |
| `googlevideo.com`, `ytimg.com`, and other CDN/static asset hosts | Allow |
| Subresource / iframe loads (`isForMainFrame: false`) | Always allow (all platforms) |
| `consent.youtube.com`, `gstatic.com`, `googleapis.com`, other allowed Google static/consent URLs | Allow |
| **`accounts.google.com` (passive or active sign-in)** | **Cancel** (main frame); player reloads watch URL |
| Unrelated main-frame origins | Cancel |

**Why**: YouTube’s mobile watch page often redirects through **passive Google sign-in** when no session cookies exist. In embedded WebViews (especially **release** builds on any platform), that chain can finish without a playable `<video>` — infinite loading. Blocking account navigations in the player keeps anonymous playback on the watch page; the engine reloads the watch URL when sign-in is cancelled. Use **YouTube login** when a signed-in session is needed.

## Transcripts

Signed-in learners get **bilingual** captions automatically: when the video's
content language differs from the learner's native language, the app requests
the **original** caption and a **native-language translation** together in a
single Enjoy Worker `POST /youtube/transcripts` call (the worker's `languages`
array), then stores the original as the **primary** subtitle and the translation
as the **secondary** subtitle so both appear with no extra taps. When the content
language equals the native language (or the native language is unknown), the app
uses the existing **single-language** path (`language:` only), preserving the
worker's Apify fallback. Source language `und`/empty skips cloud entirely.

The worker is **server-side long-polled** (`wait_ms`), so a video typically
resolves in a handful of POSTs rather than the prior fixed 2 s × 30 loop; a
`partial` result (some languages missing) is treated as success — every caption
that *is* ready is stored and shown, never an error. See
[ADR-0036](../decisions/0036-youtube-bilingual-transcripts.md) and the YouTube
(Worker) section of [transcript.md](transcript.md). Local subtitle file import
remains disabled for YouTube rows.

When the worker poll returns `status: failed`, the app records a **fetched**
state so the UI does not spin forever; users can retry later (e.g. after captions
exist or policy changes) without an infinite poll loop. See
[`transcript_repository.dart`](../../lib/features/transcript/data/transcript_repository.dart).

## Limitations

- **Init speed**: Thumbnail artwork shows during player open and while the WebView buffers. The shared WebView may mount during `openMedia()` (overlapping cold-start with DB work) and is **kept warm** after dismiss until the user opens non-YouTube media or the app exits. Optional pre-warm runs when tapping a YouTube row in Library or Discover. After the watch page loads, the engine nudges `<video>.play()` at ~6s if autoplay has not started; **one** full reload may run at ~12s if playback is still stalled (no reload loop once `first_playing`). Playback still uses the mobile watch page — not embed (Error 153 in native WebViews).
- **Windows play startup**: `flutter_inappwebview`'s `mediaPlaybackRequiresUserGesture` setting is not implemented by its WebView2 backend. Programmatic play therefore starts muted, waits for the authoritative HTML5 `playing` event, and restores the configured volume after a short initial settle window; later pause/resume cycles restore volume immediately. The earlier flow force-unmuted on the optimistic `play` event, which could make YouTube immediately pause before frames advanced. A `play` event alone no longer marks the app transport as playing; rejected `play()` promises are logged.
- **iOS inline playback**: the WebView sets `allowsInlineMediaPlayback`, injects `playsinline` on the `<video>`, and hooks iOS native fullscreen to stay inline so the 16:9 frame stays visible for echo / shadow reading. Player and login WebViews share the same Chrome mobile `userAgent` so Google sign-in is not blocked as an insecure browser.
- Position updates while playing are polled (~250 ms); echo clamp may overshoot slightly vs `media_kit`.
- Embedded MKV/MP4 subtitle track extraction is unavailable for YouTube (no `media_kit` decode of the stream).
- Ad behavior depends on YouTube, cookies, and account; “no ads” is best-effort when signed in with Premium where applicable.
- **Captions**: YouTube's own captions/CC (`.ytp-caption-window-container` and any native `<track>` cues) are force-hidden by [`kYoutubeMobileWatchInjectScript`](../../lib/features/player/application/engines/youtube/youtube_page_inject.dart) — injected CSS, disabling `video.textTracks`, and unloading the player `captions`/`cc` modules on every hook/enforce cycle. Some videos default captions on (auto-captions, saved viewer prefs), and since the native control bar is also hidden there would otherwise be no way to turn them off; the app's own transcript panel (see [Transcripts](#transcripts) above) is the only caption source shown to users.

## Buffering transitions

`YoutubePlayerEngine._emitBuffering(false)` only bumps the internal `mountTick` on the **first** buffering → playing transition per open. Mid-roll ad breaks and re-bufferings after the first play do not retrigger the tick, so the player UI does not flash the loading indicator on every ad pause. Tests for the buffering state should cover the "buffering → playing → buffering → playing" sequence and assert the mountTick only changes once.

## Platform notes

| Platform | WebView | Profile / cookies | Navigation policy (ADR-0025) | Process crash recovery |
|----------|---------|-------------------|------------------------------|-------------------------|
| **Windows** | WebView2 via [`platform_webview_environment.dart`](../../lib/core/webview/platform_webview_environment.dart) — user data under `%APPDATA%…\WebView2` (required for Program Files installs) | Shared environment for player + login + Enjoy sign-in | `shouldOverrideUrlLoading` + CDN subframe allowlist | N/A (reload via stall watchdog) |
| **Android** | System WebView | App data directory | `useShouldOverrideUrlLoading: true` | `onRenderProcessGone` → reload watch URL |
| **iOS** | WKWebView | App sandbox | Same policy; `isForMainFrame: null` treated as subframe | `onWebContentProcessDidTerminate` → reload |
| **macOS** | WKWebView | App sandbox | Same as iOS | `onWebContentProcessDidTerminate` → reload |

Login WebViews use the same Windows [`appWebViewEnvironment`](../../lib/core/webview/platform_webview_environment.dart) so YouTube cookies from **YouTube login** apply to the player WebView.

## Troubleshooting (release / cold profile)

If YouTube stalls on loading in a **release** or installed build but works in `flutter run`:

1. Confirm you are on a build that includes the navigation-policy fix (ADR-0025 + subframe/CDN allowlist).
2. Try **YouTube login** once, then reopen the video (establishes session cookies).
3. Check diagnostic logs for `youtube play command`, `youtube video play requested`, `youtube video playing`, `youtube play rejected`, `youtube pause confirmed`, `youtube init load_stop`, `youtube playback stalled`, or `WebView process terminated`. Enable **Settings → About → Diagnostic logging** before reproduction to include the FINE-level command, event, and poll-transition records.
4. **Windows only**: compare portable `build\windows\x64\runner\Release\enjoy_player.exe` vs Program Files install. Installed builds require a writable WebView2 user-data folder (not next to the exe); diagnostic logs include `webViewUserData=…` and `exe=…` on each session. Shortcuts from the installer set `WorkingDir` to the install folder.

Policy rules are unit-tested in [`youtube_watch_navigation_policy_test.dart`](../../test/features/player/youtube_watch_navigation_policy_test.dart).
