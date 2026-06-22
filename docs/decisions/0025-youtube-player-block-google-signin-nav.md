# ADR-0025: Block Google sign-in navigations in YouTube player WebView

## Status

Accepted

## Context

YouTube playback loads `https://m.youtube.com/watch?v=<id>` in the **player** `InAppWebView` and controls the page HTML5 `<video>` ([ADR-0015](0015-youtube-playback.md)). Optional **explicit** YouTube login uses a separate screen (`/youtube/login`) that shares the WebView cookie jar.

On **release** Windows builds (and some cold WebView profiles), opening a video triggered YouTube’s **passive Google sign-in** chain:

`m.youtube.com/watch` → `accounts.google.com/ServiceLogin?passive=true&…` → `…/signin/identifier`

The WebView reported `load_stop` on the watch URL but never reached a playable `<video>` (`first_playing` never fired). **Debug** builds often appeared fine because of slower timing and/or existing `LOGIN_INFO` / `SID` cookies from prior dev sessions.

We initially tightened navigation to require `v=<id>` in every URL, which blocked legitimate YouTube redirect hops. The durable fix is to **deny Google account navigations in the player WebView** while allowing YouTube/Google static assets and consent flows.

## Decision

1. **Centralize policy** in [`youtube_watch_navigation_policy.dart`](../../lib/features/player/application/engines/youtube/youtube_watch_navigation_policy.dart) with unit tests.

2. **While `videoId` is non-empty**, the player WebView [`shouldOverrideUrlLoading`](../../lib/features/player/application/engines/youtube/youtube_webview_host.dart):
   - **Cancels** all `accounts.google.com` navigations (passive and active).
   - **Allows** `youtube.com`, `youtu.be`, `consent.youtube.com`, `google.com` (captcha/interstitial), `gstatic.com`, `googleapis.com`, `myaccount.google.com`, and `about:blank`.
   - **Cancels** everything else.

3. **Explicit sign-in unchanged**: users sign in via [`YoutubeLoginScreen`](../../lib/features/player/presentation/youtube_login_screen.dart). Session cookies persist in the shared WebView profile across app restarts until logout (`CookieManager.deleteAllCookies()`).

4. **Do not** load embed URLs or iframe APIs — still out of scope per ADR-0015.

## Consequences

- **Anonymous playback** works on cold installs without getting stuck on Google sign-in.
- **Signed-in / Premium** behavior requires using the in-app YouTube login flow first; the player WebView will not complete Google login inline.
- If YouTube changes passive sign-in to use non-`accounts.google.com` origins, extend the policy and tests.
- Navigation policy is covered by [`youtube_watch_navigation_policy_test.dart`](../../test/features/player/youtube_watch_navigation_policy_test.dart).

## References

- Feature notes: [`docs/features/youtube.md`](../features/youtube.md)
- Supplements: [ADR-0015](0015-youtube-playback.md) (login / cookies)
