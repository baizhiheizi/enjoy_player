# ADR-0027: Native auth v2 (Google, Apple, email OTP, PKCE fallback)

## Status

Accepted

## Context

[ADR-0016](0016-enjoy-account-webview-sign-in.md) loads the Enjoy verification URL in an **InAppWebView** and polls until the session is approved. IdPs often block embedded WebViews; OAuth in WebViews is discouraged. Completion is inferred by polling rather than an explicit callback.

The product needs native sign-in (Google, Apple, email OTP) and a standards-based web fallback. Backend APIs can be added on Enjoy API without retaining the poll contract.

## Decision

1. **Primary sign-in:** Native SDK paths exchange credentials synchronously with new `/api/v1/auth/*` endpoints (see [native-auth-v2.openapi.yaml](../api/native-auth-v2.openapi.yaml)):
   - `POST /api/v1/auth/google` — Google `idToken`
   - `POST /api/v1/auth/apple` — Apple `identityToken` + `authorizationCode`
   - `POST /api/v1/auth/otp/send` + `/otp/verify` — passwordless email

2. **Web fallback:** OAuth 2.0 Authorization Code + PKCE via system auth session (not InAppWebView). Redirect to `https://enjoy.bot/app/auth/callback` (universal/app links) or `enjoyplayer://auth/callback` (Windows custom scheme). Exchange code with `POST /api/v1/auth/token`.

3. **Sessions:** Issue `accessToken` + **refreshToken**; client stores both in `flutter_secure_storage`. `POST /api/v1/auth/refresh` rotates refresh tokens. Profile and per-user SQLite behavior unchanged ([ADR-0012](0012-per-user-sqlite-isolation.md)).

4. **Platform matrix:** Google native on Android/iOS/macOS; Apple on iOS/macOS; email OTP everywhere; hide native Google on Windows; PKCE fallback on all platforms.

5. **Account linking:** Backend `identities` table; merge on verified email for Google/OTP; Apple keyed by `sub` (not private relay email alone).

6. **Deprecation:** Client removes `start_auth` + WebView + poll. Backend keeps `/api/v1/sessions/start_auth` and `/poll` until minimum app version no longer needs them.

7. **Supersedes** ADR-0016 §Decision point 1 (WebView-primary verification). Token storage and profile sync remain per ADR-0006 / ADR-0012. YouTube login WebView is unchanged ([ADR-0015](0015-youtube-playback.md)).

## Consequences

- Requires Google Cloud OAuth clients (per platform `aud`), Apple Sign in with Apple for bundle `ai.enjoy.player`, hosted `apple-app-site-association` and Android `assetlinks.json`, and email delivery for OTP.
- New Flutter dependencies: `google_sign_in`, `sign_in_with_apple`, `app_links`.
- Deep-link and installer work on four platforms; Windows uses custom URL protocol.
- Backend implementation lives outside this repository; OpenAPI contract is the integration boundary.
