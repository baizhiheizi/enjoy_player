## 1. Backend API & identity (Enjoy API — external to this repo)

- [x] 1.1 Define OpenAPI for `/api/v1/auth/google`, `/apple`, `/otp/send`, `/otp/verify`, `/authorize`, `/token`, `/refresh` with unified token response shape
- [ ] 1.2 Implement Google ID token verification (per-platform `aud`) and user upsert
- [ ] 1.3 Implement Apple identity token + authorization code verification and user upsert
- [ ] 1.4 Implement OTP send/verify with rate limits, hashed codes, and `requestId` binding
- [ ] 1.5 Implement refresh token issuance with rotation and reuse detection
- [ ] 1.6 Implement OAuth authorize + PKCE token exchange endpoints
- [ ] 1.7 Add `identities` model and verified-email account linking rules
- [ ] 1.8 Host `apple-app-site-association` and Android `assetlinks.json` for `https://enjoy.bot/app/auth/callback`
- [x] 1.9 Deprecation plan for `/api/v1/sessions/start_auth` and `/poll` (keep for old app versions until min version bump)

## 2. Documentation & ADR

- [x] 2.1 Add ADR for native auth v2 (supersedes ADR-0016 WebView-primary; references ADR-0006/0012)
- [x] 2.2 Update `docs/features/auth.md` with new flows and endpoints
- [x] 2.3 Link ADR from `docs/decisions/README.md`

## 3. Dependencies & secure storage

- [x] 3.1 Add `google_sign_in`, `sign_in_with_apple`, and `app_links` to `pubspec.yaml`
- [x] 3.2 Extend `SecureTokenStore` with refresh token read/write/clear
- [x] 3.3 Add domain model `AuthTokenResponse` (accessToken, refreshToken, expiresIn, user)

## 4. API client & repository

- [x] 4.1 Extend `AuthApi` with google, apple, otp send/verify, token exchange, and refresh methods
- [x] 4.2 Implement `ApiClient` 401 interceptor: refresh once, retry, else sign out
- [x] 4.3 Extend `AuthRepository` with `signInGoogle`, `signInApple`, `sendOtp`, `verifyOtp`, `exchangePkceCode`, `refreshSession`
- [x] 4.4 Remove `startAuth` / `pollAuth` usage from repository once UI migrates

## 5. Auth controller & state

- [x] 5.1 Add `AuthAwaitingOtp` and `AuthSigningInWebPkce` (or equivalent) to `AuthState`
- [x] 5.2 Replace poll timer in `AuthCtrl` with method-specific sign-in actions
- [x] 5.3 Wire deep-link listener to complete PKCE exchange (validate `state`, call repository)
- [x] 5.4 Update `signOut` and `clearSession` to clear refresh token

## 6. Sign-in UI

- [x] 6.1 Replace single CTA with native sign-in hub (platform-aware provider visibility)
- [x] 6.2 Add email entry + OTP entry screens with resend cooldown
- [x] 6.3 Implement Google sign-in button and error handling
- [x] 6.4 Implement Apple sign-in button (iOS/macOS only)
- [x] 6.5 Implement PKCE web fallback launcher (auth session / external browser, not WebView)
- [x] 6.6 Remove `_SigningInWebPane` InAppWebView verification flow from `SignInScreen`
- [x] 6.7 Add l10n strings (en + zh) for hub, OTP, providers, PKCE, and errors

## 7. Platform configuration

- [x] 7.1 Android: Google OAuth client (SHA-1), App Links intent-filter for auth callback
- [x] 7.2 iOS: Google URL scheme, Sign in with Apple capability, Associated Domains
- [x] 7.3 macOS: Google + Apple entitlements (Keychain Sharing unchanged for tokens)
- [x] 7.4 Windows: register `enjoyplayer://` custom URL protocol in installer
- [ ] 7.5 Verify deep link opens app and routes to auth completion handler on each platform

## 8. PKCE utilities

- [x] 8.1 Add PKCE code verifier/challenge generation (S256) using existing `crypto` package
- [x] 8.2 Build authorize URL with `state`, `code_challenge`, `redirect_uri` per platform
- [x] 8.3 Add PKCE session timeout (5 min) and cancel handling

## 9. Verification

- [x] 9.1 Unit tests: `AuthRepository` token exchange paths (mock `AuthApi`)
- [x] 9.2 Unit tests: `AuthCtrl` state transitions (OTP, no poll timer)
- [x] 9.3 Unit tests: PKCE state validation and deep-link handler
- [x] 9.4 Widget tests: sign-in hub visibility rules and OTP screen
- [ ] 9.5 Manual E2E: email OTP on one mobile + one desktop platform
- [ ] 9.6 Manual E2E: Google (Android or iOS) and Apple (iOS) against staging API
- [ ] 9.7 Manual E2E: PKCE web fallback + deep link on Android and Windows
- [x] 9.8 Run `dart format`, `flutter analyze`, `flutter test`
