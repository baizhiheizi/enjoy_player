# ADR-0034: Custom-scheme-only PKCE callback

## Status

Accepted — supersedes [ADR-0027](0027-native-auth-v2.md) §Decision 2 only

## Context

[ADR-0027](0027-native-auth-v2.md) §Decision 2 specified two possible PKCE redirect URIs: a universal/app link (`https://enjoy.bot/app/auth/callback`) or the Windows-only custom scheme (`enjoyplayer://auth/callback`). In practice, hosting the universal/app link required `apple-app-site-association` and Android `assetlinks.json` on the backend, plus the corresponding intent filter / associated-domain entitlement work on every mobile platform — none of which materialized before the native-auth-v2 rollout.

`auth_pkce_redirect_uri()` was refactored to always return `enjoyplayer://auth/callback` regardless of `TargetPlatform`, and the Android universal-link intent filter was removed from `AndroidManifest.xml`. This is a real behavioral divergence from ADR-0027, not just an implementation detail — a future maintainer reading ADR-0027 would reasonably expect a live universal/app-link path that no longer exists in the client.

Separately, the same change introduced `kGoogleWebClientId` (`google_auth_config.dart`) as the canonical home for the Google **Web application** OAuth client ID, passed as `serverClientId` on Android per-platform ID-token verification. This constant is a public OAuth client identifier, not a secret.

## Decision

1. **Single redirect URI, every platform:** `authPkceRedirectUri()` returns `enjoyplayer://auth/callback` for Android, iOS, macOS, and Windows. There is no universal/app-link alternative.
2. **Per-platform scheme registration** (no backend-hosted association files required):
   - **Android** — `VIEW` intent filter for the `enjoyplayer` scheme in `AndroidManifest.xml` (the universal-link intent filter is removed).
   - **iOS / macOS** — `CFBundleURLSchemes` entry for `enjoyplayer` in `Info.plist`.
   - **Windows** — Inno Setup installer registers the `enjoyplayer://` protocol handler at install time.
3. **`kGoogleWebClientId` is first-class:** the Google Web application OAuth client ID lives in `lib/features/auth/domain/google_auth_config.dart` as a named public constant, rather than being inlined at each call site. It is passed as `serverClientId` on Android so the returned ID token's audience matches what `NativeAuth::GoogleIdTokenVerifier` already accepts by default.
4. **Everything else in ADR-0027 stands.** The native SDK exchanges (`/api/v1/auth/google`, `/api/v1/auth/apple`, `/api/v1/auth/otp/*`), the `/api/v1/auth/token` PKCE exchange endpoint, refresh-token rotation, the platform matrix, account linking, and the `start_auth`/WebView deprecation are unaffected by this ADR.

## Consequences

- No backend work needed to host `apple-app-site-association` or `assetlinks.json` — one fewer moving part for the mobile deep-link story.
- Windows requires the single-instance forwarding workaround documented in [`docs/features/auth.md`](../features/auth.md#deep-links-pkce-callback) (`SendAppLinkToInstance`) since the OS always launches a fresh process for a registered custom-scheme URL; a universal/app link would not have needed this on iOS/macOS, but Windows never supported universal links anyway.
- `enjoy_web`'s `config/native_auth_clients.yml` only needs to whitelist the one custom-scheme redirect URI.
- If a future universal/app-link requirement re-emerges (e.g. an OS deprecates custom URL schemes), it will need its own ADR rather than reviving this superseded decision.
