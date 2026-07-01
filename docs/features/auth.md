# Auth & profile (Enjoy account)

## Behavior

Native-first sign-in ([ADR-0027](../decisions/0027-native-auth-v2.md)) with **login-only app access** ([ADR-0031](../decisions/0031-login-only-access.md)):

- **Login gate**: Signed-out users can only open `/sign-in` and `/sign-in/email`. Home, library, discover, player, settings, profile, credits, and YouTube login routes redirect to sign-in until authenticated.
- **Welcome sign-in hub**: Single screen with welcome copy plus **Continue with Google** (Android/iOS/macOS), **Apple** (iOS/macOS), **Email OTP**, or **Other sign-in options** (OAuth PKCE). No guest mode, skip, or cancel-to-home.
- **Post-sign-in navigation**: Redirects preserve the intended destination via `?from=` (e.g. `profile`, `credits`, or an encoded path).
- **Email OTP**: Single screen at `/sign-in/email` — enter email, then verify with a 6-digit pin on the same page. Shows the target email, supports resend with server-driven cooldown, and **Change email** to edit and resend. If the user opens the hub mid-OTP, a resume card links back to the email flow.
- **No WebView poll flow** for Enjoy account auth — legacy `start_auth` + InAppWebView verification is removed from the client.
- **Bearer + refresh tokens** in **flutter_secure_storage** (not Drift). On API `401`, the client refreshes once via `POST /api/v1/auth/refresh` before signing out.
- Last **profile snapshot** cached in secure storage for fast cold start ([ADR-0012](../decisions/0012-per-user-sqlite-isolation.md)).
- **Profile** via `GET/PATCH /api/v1/profile` (camelCase JSON over the wire from the client’s perspective).
- **Locale / learning / native language** applied from server profile on login and refresh (unchanged).
- **Sign out** returns to the welcome sign-in screen; the app is not usable without re-authenticating.

YouTube account login remains a separate WebView flow ([features/youtube.md](youtube.md), ADR-0015), reachable after Enjoy account sign-in.

## API endpoints (client)

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/v1/auth/google` | Exchange Google `idToken` |
| POST | `/api/v1/auth/apple` | Exchange Apple credentials |
| POST | `/api/v1/auth/otp/send` | Send email OTP |
| POST | `/api/v1/auth/otp/verify` | Verify OTP → session |
| GET | `/api/v1/auth/authorize` | Start PKCE web fallback |
| POST | `/api/v1/auth/token` | Exchange auth code (PKCE) |
| POST | `/api/v1/auth/refresh` | Rotate refresh token |

OpenAPI contract: [native-auth-v2.openapi.yaml](../api/native-auth-v2.openapi.yaml).

## Deep links (PKCE callback)

- Custom scheme (all platforms): `enjoyplayer://auth/callback`

This is the only redirect URI whitelisted in enjoy_web's `config/native_auth_clients.yml`; a universal/app link (`https://enjoy.bot/app/auth/callback`) was considered but dropped to avoid the backend needing to host `apple-app-site-association` / `assetlinks.json`. Windows installer registers the `enjoyplayer://` protocol; Android and iOS register it via manifest/Info.plist intent filters.

## Platform notes

- **Windows**: native Google hidden; email OTP + PKCE fallback.
- **Android**: no Apple button; Google OAuth client requires release SHA-1 in Google Cloud Console.
- **iOS**: Sign in with Apple required when Google is offered; enable capability in Xcode.
- **macOS**: Keychain Sharing entitlements still required for secure storage (see ADR-0012).

## Google OAuth client setup (manual, one-time)

`GoogleSignInService` and `ios/Runner/Info.plist` / `macos/Runner/Info.plist` currently ship with `REPLACE_WITH_*` placeholders. Someone with access to the Google Cloud project backing `google.client_id` in enjoy_web's Rails credentials must:

1. **Android** — no new OAuth client needed. `GoogleSignInService` already passes the existing **Web application** client ID (`kGoogleWebClientId` in [`google_auth_config.dart`](../../lib/features/auth/domain/google_auth_config.dart)) as `serverClientId`; enjoy_web's `NativeAuth::GoogleIdTokenVerifier` already accepts it for `platform=android` (falls back to `google.client_id` when `google.android_client_id` is unset). You only need to register the app's **SHA-1 fingerprints** (debug + release keystores, `keytool -list -v -keystore <path>`) against package `ai.enjoy.player` in Google Cloud Console → Credentials, or Google Sign-In will reject the app at runtime.
2. **iOS** — create an **iOS** type OAuth client for bundle ID `ai.enjoy.player`. Replace:
   - `ios/Runner/Info.plist`: `GIDClientID` value with the new client ID, and the second `CFBundleURLSchemes` entry with that client ID reversed (e.g. `com.googleusercontent.apps.123456-abc`).
   - enjoy_web Rails credentials: `google.ios_client_id` with the same client ID (`bin/rails credentials:edit`).
3. **macOS** — same as iOS: create a **macOS** (or reuse the iOS) type OAuth client, update `macos/Runner/Info.plist`'s `GIDClientID` + reversed `CFBundleURLSchemes`, and set `google.macos_client_id` in Rails credentials (optional — falls back to `ios_client_id`).
4. Rebuild the app on each platform and confirm `signInForIdToken()` returns a non-null token, then that `POST /api/v1/auth/google` succeeds.

## Secure storage configuration

[`SecureTokenStore`](../../lib/features/auth/data/secure_token_store.dart) pins platform-specific `flutter_secure_storage` options rather than relying on defaults:

- **Android** — `AndroidOptions()` (Keystore v10 with RSA-OAEP / AES-GCM). Tokens written by older builds with legacy ciphers are auto-migrated on first read; the migration is logged at info level so support can spot tenants on stale ciphers.
- **iOS** — `IOSOptions(accessibility: KeychainAccessibility.first_unlock)` so tokens survive reboot but are gated on the first device unlock after boot, matching Apple's recommended posture for non-background tokens.

If you need to add a new platform-specific option, add a constant in `SecureTokenStore` and document the migration story here — do not change the default globally.

## Deep link lifecycle

The PKCE callback stream is owned by the auth controller and is now properly **cancelled in `dispose()`** — previously a late deep link arriving after a widget unmount could call into a torn-down controller. `getInitialLink()` also has an `onError` handler that swallows platform-channel errors and falls through to the "no pending link" path so a broken platform implementation does not block the sign-in hub.

`AuthDeepLinkListener` (via `app_links`) is the **only** owner of `enjoyplayer://` callbacks. Flutter's own native deep-link auto-forwarding is explicitly disabled (`flutter_deeplinking_enabled=false` on Android, `FlutterDeepLinkingEnabled=false` on iOS/macOS) — otherwise the OS delivers the same callback intent/URL to *both* `app_links` and Flutter's navigation channel, and go_router sees it as an unmatched `/callback` route (no such path exists) and briefly renders the "Page not found" screen even though the token exchange completes successfully in the background. As a defense in depth, `isNativeAuthCallbackArtifact` in [`auth_redirect.dart`](../../lib/core/routing/auth_redirect.dart) also makes go_router treat a stray `/callback` location like `/` instead of falling through to the not-found screen, in case any platform still forwards it.

## Related ADRs

- [ADR-0006](../decisions/0006-auth-and-profile-sync.md)
- [ADR-0012](../decisions/0012-per-user-sqlite-isolation.md)
- [ADR-0016](../decisions/0016-enjoy-account-webview-sign-in.md) — superseded for Enjoy account delivery
- [ADR-0027](../decisions/0027-native-auth-v2.md)
- [ADR-0031](../decisions/0031-login-only-access.md)
