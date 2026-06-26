## Why

Enjoy account sign-in today uses an in-app WebView loading a verification URL plus a 2-second poll loop until the server approves the session. IdPs often block or degrade embedded WebViews, the UX feels like a web page trapped in the app, and completion is inferred by polling rather than an explicit callback. With backend API flexibility, we can adopt industry-standard native auth (Google, Apple, email OTP), refresh tokens, and OAuth Authorization Code + PKCE with deep links for the rare web fallback — and retire the WebView-first flow.

## What Changes

- Replace the single **Sign in → WebView → poll** path with a **native sign-in hub**: Continue with Google, Continue with Apple (iOS/macOS), Continue with Email (OTP), and **Other sign-in options** (OAuth PKCE via system auth session + deep link).
- Add new Enjoy API endpoints under `/api/v1/auth/*` that return `{ accessToken, refreshToken, expiresIn, user }` synchronously (no polling).
- Store **refresh tokens** in `flutter_secure_storage` alongside the bearer access token; refresh on `401` before signing out.
- Configure **deep links** (`https://enjoy.bot/app/auth/callback` universal/app links + `enjoyplayer://auth/callback` custom scheme fallback) for PKCE web fallback completion.
- **Remove** InAppWebView as the primary Enjoy account sign-in surface; remove the poll timer from `AuthCtrl`.
- **BREAKING (API):** Deprecate and remove client usage of `POST /api/v1/sessions/start_auth` and `GET /api/v1/sessions/poll` once native paths ship (backend may keep temporarily for older app versions).
- Update docs: supersede ADR-0016 (WebView-primary sign-in); extend auth feature spec and add ADR for native auth v2.

## Capabilities

### New Capabilities

- `native-auth`: Native-first Enjoy account sign-in (Google, Apple, email OTP, OAuth PKCE web fallback), token refresh, deep-link callback handling, sign-in hub UI, and retirement of WebView + poll auth.

### Modified Capabilities

<!-- None: no existing OpenSpec spec covers Enjoy account auth behavior. -->

## Impact

- **App code**: `lib/features/auth/` (controller, repository, presentation), `lib/data/api/services/auth_api.dart`, `SecureTokenStore`, `SignInScreen`; new OTP screens; deep-link listener wired into GoRouter or auth layer.
- **Dependencies**: `google_sign_in`, `sign_in_with_apple`, `app_links` (or equivalent); possible `flutter_appauth` for PKCE session on some platforms.
- **Platform config**: Google OAuth client IDs (Android SHA-1, iOS/macOS), Apple Sign in with Apple capability, Android App Links, iOS/macOS Associated Domains, Windows custom URL protocol in installer.
- **Backend (Enjoy API)**: New `/api/v1/auth/google`, `/apple`, `/otp/send`, `/otp/verify`, `/token` (PKCE exchange), `/refresh`; account linking by provider identity; rate limits on OTP; hosted `apple-app-site-association` and Android `assetlinks.json` for callback URLs.
- **Docs**: `docs/features/auth.md`, new ADR superseding ADR-0016 partially; ADR-0006 auth mechanism section updated by reference.
- **l10n**: Sign-in hub strings, OTP flow, provider errors, web-fallback copy.
- **Tests**: Auth repository/controller unit tests; widget tests for OTP and hub; deep-link handler tests.
- **Out of scope**: YouTube account login (unchanged WebView flow per ADR-0015); Flutter web targets.
