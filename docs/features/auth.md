# Auth & profile (Enjoy account)

## Behavior

Native-first sign-in ([ADR-0027](../decisions/0027-native-auth-v2.md)) with **login-only app access** ([ADR-0031](../decisions/0031-login-only-access.md)):

- **Login gate**: Signed-out users can only open `/sign-in` and `/sign-in/email`. Home, library, discover, player, settings, profile, credits, and YouTube login routes redirect to sign-in until authenticated.
- **Welcome sign-in hub**: Single screen with welcome copy plus **Continue with Google** (Android always; iOS/macOS only once `kGoogleNativeSignInConfiguredOnApple` is flipped to `true` — see [Google OAuth client setup](#google-oauth-client-setup-manual-one-time)), **Apple** (iOS/macOS), **Email OTP**, or **Other sign-in options** (OAuth PKCE). No guest mode, skip, or cancel-to-home.
- **Post-sign-in navigation**: Redirects preserve the intended destination via `?from=` (e.g. `profile`, `credits`, or an encoded path).
- **Email OTP**: Single screen at `/sign-in/email` — enter email, then verify with a 6-digit pin on the same page. Shows the target email, supports resend with server-driven cooldown, and **Change email** to edit and resend. If the user opens the hub mid-OTP, a resume card links back to the email flow.
- **No WebView poll flow** for Enjoy account auth — legacy `start_auth` + InAppWebView verification is removed from the client.
- **Bearer + refresh tokens** in **flutter_secure_storage** (not Drift). On API `401`, the client refreshes once via `POST /api/v1/auth/refresh` before signing out.
- Last **profile snapshot** cached in secure storage for fast cold start ([ADR-0012](../decisions/0012-per-user-sqlite-isolation.md)).
- **Profile** via `GET/PATCH /api/v1/profile` (camelCase JSON over the wire from the client’s perspective).
- **Locale / learning / native language** applied from server profile on login and refresh (unchanged).
- **Sign out** returns to the welcome sign-in screen; the app is not usable without re-authenticating.

YouTube account login remains a separate WebView flow ([features/youtube.md](youtube.md), ADR-0015), reachable after Enjoy account sign-in.

## Profile

The `/profile` route (`ProfileScreen`) is a thin `Scaffold`/`AppBar` wrapper around `ProfileContent` (`lib/features/auth/presentation/widgets/profile_content.dart`) — the shared, chrome-free body with the identity hero card, practice stats, subscription/credits nav, name/goal/language preferences form, and sign out. The **same** `ProfileContent` widget is also rendered directly inline by the two-pane Settings Account tab (`showRefreshIndicator: false`; see [`settings.md`](settings.md#account-section)) so desktop users never have to leave Settings to manage their profile. The standalone route (`showRefreshIndicator: true`, the default) keeps pull-to-refresh; the inline embed shows a small manual refresh icon button instead, since it already lives inside the Settings hub's own scroll view.

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

**Windows single-instance forwarding**: Windows always launches a *new* `enjoy_player.exe` process to handle a registered `enjoyplayer://` URL — there is no OS-level concept of routing it to an already-running instance. [`windows/runner/main.cpp`](../../windows/runner/main.cpp) therefore calls `SendAppLinkToInstance()` before creating any window: it looks up the existing top-level window (class `FLUTTER_RUNNER_WIN32_WINDOW`, title `Enjoy Player`) with `FindWindow`, and if found, forwards the new process's command-line URI to it via `app_links`'s exported `SendAppLink()` (a `WM_COPYDATA` message the plugin already listens for on the first instance), restores/foregrounds that window, and exits immediately. Without this, the second process has no in-memory PKCE state (code verifier / OAuth `state`) and the original instance's `AuthDeepLinkListener` never receives the callback, so sign-in silently stalls until timeout and a stray second window is left open.

## Platform notes

- **Windows**: native Google hidden; email OTP + PKCE fallback.
- **Android**: no Apple button; Google OAuth client requires release SHA-1 in Google Cloud Console.
- **iOS**: Sign in with Apple required when Google is offered. Enable the capability on App ID `ai.enjoy.player` in Apple Developer, and ship `ios/Runner/Runner.entitlements` with `com.apple.developer.applesignin` referenced from all Runner build configurations (`CODE_SIGN_ENTITLEMENTS`). Missing entitlements surface as `AuthorizationError error 1000` before any API call.
- **macOS**: Sign in with Apple is **iOS-only** in this app. macOS local/Xcode builds use sandbox entitlements without `com.apple.developer.applesignin` (the capability is unsupported for Developer ID distribution and breaks provisioning on macOS). **Developer ID direct-download** releases use `macos/Runner/ReleaseDirect.entitlements` via `notarize_release.sh`. Direct macOS builds hide the Apple button via `nativeAppleSignInSupported`; use Google (when configured), email OTP, or PKCE.

## Google OAuth client setup (manual, one-time)

OAuth client IDs are **public identifiers**, not secrets — they are safe to embed in client code the same way they already ship in `google-services.json` / `GoogleService-Info.plist`. The Web application client ID lives as a named constant, `kGoogleWebClientId` in [`google_auth_config.dart`](../../lib/features/auth/domain/google_auth_config.dart), rather than being inlined at each call site. Rotating any of these client IDs does not affect the `enjoyplayer://auth/callback` redirect URI (see [Deep links](#deep-links-pkce-callback)) — the scheme is stable and only needs to change if the app's URL scheme itself changes.

`GoogleSignInService` and `ios/Runner/Info.plist` / `macos/Runner/Info.plist` currently ship with `REPLACE_WITH_*` placeholders. Someone with access to the Google Cloud project backing `google.client_id` in enjoy_web's Rails credentials must:

1. **Android** — no new OAuth client needed. `GoogleSignInService` already passes the existing **Web application** client ID (`kGoogleWebClientId` in [`google_auth_config.dart`](../../lib/features/auth/domain/google_auth_config.dart)) as `serverClientId`; enjoy_web's `NativeAuth::GoogleIdTokenVerifier` already accepts it for `platform=android` (falls back to `google.client_id` when `google.android_client_id` is unset). You only need to register the app's **SHA-1 fingerprints** (debug + release keystores, `keytool -list -v -keystore <path>`) against package `ai.enjoy.player` in Google Cloud Console → Credentials, or Google Sign-In will reject the app at runtime.
2. **iOS** — create an **iOS** type OAuth client for bundle ID `ai.enjoy.player`. Replace:
   - `ios/Runner/Info.plist`: `GIDClientID` value with the new client ID, and the second `CFBundleURLSchemes` entry with that client ID reversed (e.g. `com.googleusercontent.apps.123456-abc`).
   - enjoy_web Rails credentials: `google.ios_client_id` with the same client ID (`bin/rails credentials:edit`).
3. **macOS** — same as iOS: create a **macOS** (or reuse the iOS) type OAuth client, update `macos/Runner/Info.plist`'s `GIDClientID` + reversed `CFBundleURLSchemes`, and set `google.macos_client_id` in Rails credentials (optional — falls back to `ios_client_id`).
4. **Flip `kGoogleNativeSignInConfiguredOnApple` to `true`** in [`google_auth_config.dart`](../../lib/features/auth/domain/google_auth_config.dart) in the same change as steps 2–3. Until both Info.plist files *and* this flag are updated together, `nativeGoogleSignInSupported` keeps the "Continue with Google" button hidden on iOS/macOS by design: `google_sign_in`'s iOS/macOS implementation reads `GIDClientID` straight from Info.plist and calling `GIDSignIn.signIn()` while it's still the placeholder throws an **uncaught, uncatchable native `NSInvalidArgumentException`** ("Your app is missing support for the following URL schemes: com.googleusercontent.apps...") that kills the whole app process — Dart `try`/`catch` cannot intercept it because the exception fires inside Google's native SDK before control returns to the Flutter engine. `GoogleSignInService.signInForIdToken()` also throws a `StateError` early as defense-in-depth for any call site that bypasses the UI gating.
5. Rebuild the app on each platform and confirm `signInForIdToken()` returns a non-null token, then that `POST /api/v1/auth/google` succeeds.

### Configuration status (as of last doc audit)

The five steps above must land **together**. The current checkout is partially complete — keep this table honest as the missing piece lands:

| Step | State | Notes |
|------|-------|-------|
| 2 — iOS `Info.plist` `GIDClientID` + reversed `CFBundleURLSchemes` | ✅ Configured (`93185289922-ostq1e99j92mq3l5dokeb904rgetkcvu`) | Expect matching `google.ios_client_id` in enjoy_web Rails credentials. |
| 3 — macOS `Info.plist` `GIDClientID` + reversed `CFBundleURLSchemes` | ❌ Still `REPLACE_WITH_MACOS_OAUTH_CLIENT_ID` | First Google sign-in on macOS will crash (see flag caveat below). |
| 4 — `kGoogleNativeSignInConfiguredOnApple = true` | ⚠️ Flipped, but **premature for macOS** | The button is shown on macOS today; macOS Info.plist must be filled in (step 3) in the same change that flipped this flag, or revert this flag until step 3 lands. |

Until step 3 lands, do **not** ship a macOS build with `kGoogleNativeSignInConfiguredOnApple = true` to external testers — the gate's purpose is to keep the placeholder from triggering an uncatchable native crash. If macOS must ship before the OAuth client exists, revert the flag; the button hides itself again.

## Apple Sign-In setup (manual, one-time)

Apple Sign-In fails **on the device** with `com.apple.AuthenticationServices.AuthorizationError error 1000` when the app binary is not signed with the Sign in with Apple entitlement — this happens inside `SignInWithApple.getAppleIDCredential()` **before** `POST /api/v1/auth/apple`, so backend credentials cannot fix it.

### Apple Developer portal

1. [Identifiers](https://developer.apple.com/account/resources/identifiers/list) → App ID **`ai.enjoy.player`** → enable **Sign in with Apple** → Save.
2. Create a **Sign in with Apple** key (`.p8`) if enjoy_web needs server-to-server token exchange; note **Key ID** and **Team ID**.

### This repo (client)

| Platform | File | What to verify |
|----------|------|----------------|
| **iOS** | `ios/Runner/Runner.entitlements` | `com.apple.developer.applesignin` → `Default` |
| **iOS** | `ios/Runner.xcodeproj` | `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` on Debug/Release/Profile |
| **macOS (Xcode / local)** | `macos/Runner/DebugProfile.entitlements` + `Release.entitlements` | sandbox + network (no Apple Sign-In on macOS) |
| **macOS (Developer ID zip)** | `macos/Runner/ReleaseDirect.entitlements` via `notarize_release.sh` | sandbox + network + app keychain group (no Apple Sign-In entitlement) |

After editing entitlements, do a **clean rebuild** (`flutter clean && flutter run`) so Xcode regenerates the provisioning profile that includes the capability. If error 1000 persists on a physical device, open `ios/Runner.xcworkspace` (or `macos/Runner.xcworkspace`) → Runner target → **Signing & Capabilities** and confirm **Sign in with Apple** appears; toggle it off/on to refresh the profile.

### enjoy_web (backend)

Configure Apple verification credentials in Rails (`bin/rails credentials:edit`) — typically team ID, key ID, `.p8` private key, and bundle ID `ai.enjoy.player`. Backend issues only matter **after** the native sheet returns tokens; a 401 from `POST /api/v1/auth/apple` with a successful sheet means fix the server config, not entitlements.

## Secure storage configuration

[`SecureTokenStore`](../../lib/data/api/secure_token_store.dart) pins platform-specific `flutter_secure_storage` options rather than relying on defaults:

- **Android** — `AndroidOptions()` (Keystore v10 with RSA-OAEP / AES-GCM). Tokens written by older builds with legacy ciphers are auto-migrated on first read; the migration is logged at info level so support can spot tenants on stale ciphers.
- **iOS** — `IOSOptions(accessibility: KeychainAccessibility.first_unlock)` so tokens survive reboot but are gated on the first device unlock after boot, matching Apple's recommended posture for non-background tokens.

If you need to add a new platform-specific option, add a constant in `SecureTokenStore` and document the migration story here — do not change the default globally.

### Self-healing keychain writes (iOS/macOS)

All writes go through `SecureTokenStore._writeResilient()`, which retries once after deleting the key if the platform layer reports `errSecDuplicateItem` (-25299, "The specified item already exists in the keychain."). This is a real gap in `flutter_secure_storage_darwin`'s `write()`: its existence check queries with `kSecAttrAccessible` included, but that attribute isn't part of a keychain item's primary key — so a leftover item stored under a *different* accessibility (an older app build, or a process killed mid-write) makes the existence check report "not found" while the subsequent `SecItemAdd` still collides on account/service, surfacing as an uncaught `PlatformException` that otherwise permanently blocks sign-in. Deleting-then-retrying searches without the accessibility filter, so it clears the stale item regardless of its accessibility level. `AuthCtrl.handleAuthCallbackUri` also catches any non-`AuthFailure` error from the token exchange (not just this one) and resets state to `AuthSignedOut` instead of leaving the flow stuck on the "waiting for browser" pane.

## Deep link lifecycle

The PKCE callback stream is owned by the auth controller and is now properly **cancelled in `dispose()`** — previously a late deep link arriving after a widget unmount could call into a torn-down controller. `getInitialLink()` also has an `onError` handler that swallows platform-channel errors and falls through to the "no pending link" path so a broken platform implementation does not block the sign-in hub.

`AuthDeepLinkListener` (via `app_links`) is the **only** owner of `enjoyplayer://` callbacks. Flutter's own native deep-link auto-forwarding is explicitly disabled (`flutter_deeplinking_enabled=false` on Android, `FlutterDeepLinkingEnabled=false` on iOS/macOS) — otherwise the OS delivers the same callback intent/URL to *both* `app_links` and Flutter's navigation channel, and go_router sees it as an unmatched `/callback` route (no such path exists) and briefly renders the "Page not found" screen even though the token exchange completes successfully in the background. As a defense in depth, `isNativeAuthCallbackArtifact` in [`auth_redirect.dart`](../../lib/core/routing/auth_redirect.dart) also makes go_router treat a stray `/callback` location like `/` instead of falling through to the not-found screen, in case any platform still forwards it.

### Email OTP — BackButton always cancels

`EmailEntryScreen`'s `AppBar` `BackButton` unconditionally calls `AuthCtrl.cancelSignIn()` before popping, instead of only doing so when the flow state was `AuthAwaitingOtp`. The previous gating left a stale in-flight OTP request (and its `resendAfterSeconds` cooldown) alive in `AuthCtrl` state after backing out of the email entry step itself, which the resume card on the sign-in hub would then surface as if the OTP flow were still active. Cancelling unconditionally on back-navigation matches the explicit **Cancel** button's behavior in the same flow.

## Related ADRs

- [ADR-0006](../decisions/0006-auth-and-profile-sync.md)
- [ADR-0012](../decisions/0012-per-user-sqlite-isolation.md)
- [ADR-0016](../decisions/0016-enjoy-account-webview-sign-in.md) — superseded for Enjoy account delivery
- [ADR-0027](../decisions/0027-native-auth-v2.md) — §Decision 2 (redirect URI) superseded by ADR-0034
- [ADR-0031](../decisions/0031-login-only-access.md)
- [ADR-0034](../decisions/0034-custom-scheme-only-pkce-callback.md) — custom-scheme-only PKCE callback, drops the universal/app-link alternative
