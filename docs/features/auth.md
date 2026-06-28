# Auth & profile (Enjoy account)

## Behavior

Native-first sign-in ([ADR-0027](../decisions/0027-native-auth-v2.md)):

- **Sign-in hub**: Continue with **Google** (Android/iOS/macOS), **Apple** (iOS/macOS), **Email OTP**, or **Other sign-in options** (OAuth PKCE in the system browser + deep link).
- **Email OTP**: Single screen at `/sign-in/email` — enter email, then verify with a 6-digit pin on the same page. Shows the target email, supports resend with server-driven cooldown, and **Change email** to edit and resend. If the user opens the hub mid-OTP, a resume card links back to the email flow.
- **No WebView poll flow** for Enjoy account auth — legacy `start_auth` + InAppWebView verification is removed from the client.
- **Bearer + refresh tokens** in **flutter_secure_storage** (not Drift). On API `401`, the client refreshes once via `POST /api/v1/auth/refresh` before signing out.
- Last **profile snapshot** cached in secure storage for fast cold start ([ADR-0012](../decisions/0012-per-user-sqlite-isolation.md)).
- **Profile** via `GET/PATCH /api/v1/profile` (camelCase JSON over the wire from the client’s perspective).
- **Locale / learning / native language** applied from server profile on login and refresh (unchanged).
- **Guest → account migration** banner on Home when guest DB has data (unchanged).

YouTube account login remains a separate WebView flow ([features/youtube.md](youtube.md), ADR-0015).

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

- Universal / App Links: `https://enjoy.bot/app/auth/callback`
- Custom scheme (Windows fallback): `enjoyplayer://auth/callback`

Backend must host `apple-app-site-association` and Android `assetlinks.json`. Windows installer registers the `enjoyplayer://` protocol.

## Platform notes

- **Windows**: native Google hidden; email OTP + PKCE fallback.
- **Android**: no Apple button; Google OAuth client requires release SHA-1 in Google Cloud Console.
- **iOS**: Sign in with Apple required when Google is offered; enable capability in Xcode.
- **macOS**: Keychain Sharing entitlements still required for secure storage (see ADR-0012).

## Secure storage configuration

[`SecureTokenStore`](../../lib/features/auth/data/secure_token_store.dart) pins platform-specific `flutter_secure_storage` options rather than relying on defaults:

- **Android** — `AndroidOptions()` (Keystore v10 with RSA-OAEP / AES-GCM). Tokens written by older builds with legacy ciphers are auto-migrated on first read; the migration is logged at info level so support can spot tenants on stale ciphers.
- **iOS** — `IOSOptions(accessibility: KeychainAccessibility.first_unlock)` so tokens survive reboot but are gated on the first device unlock after boot, matching Apple's recommended posture for non-background tokens.

If you need to add a new platform-specific option, add a constant in `SecureTokenStore` and document the migration story here — do not change the default globally.

## Deep link lifecycle

The PKCE callback stream is owned by the auth controller and is now properly **cancelled in `dispose()`** — previously a late deep link arriving after a widget unmount could call into a torn-down controller. `getInitialLink()` also has an `onError` handler that swallows platform-channel errors and falls through to the "no pending link" path so a broken platform implementation does not block the sign-in hub.

## Related ADRs

- [ADR-0006](../decisions/0006-auth-and-profile-sync.md)
- [ADR-0012](../decisions/0012-per-user-sqlite-isolation.md)
- [ADR-0016](../decisions/0016-enjoy-account-webview-sign-in.md) — superseded for Enjoy account delivery
- [ADR-0027](../decisions/0027-native-auth-v2.md)
