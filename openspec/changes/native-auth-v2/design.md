## Context

Enjoy Player optional sign-in uses `POST /api/v1/sessions/start_auth`, loads `verificationUrl` in an **InAppWebView**, and polls `GET /api/v1/sessions/poll` every 2 seconds until approved ([ADR-0016](../../../docs/decisions/0016-enjoy-account-webview-sign-in.md), [`auth_controller.dart`](../../../lib/features/auth/application/auth_controller.dart)). Bearer tokens live in `flutter_secure_storage` ([`SecureTokenStore`](../../../lib/data/api/secure_token_store.dart)); profile fetch and per-user SQLite ([ADR-0012](../../../docs/decisions/0012-per-user-sqlite-isolation.md)) are unchanged after sign-in.

IdPs often block embedded WebViews; OAuth in WebViews is discouraged by Google. The app has **no deep-link infrastructure** for auth today (launcher-only Android manifest). YouTube login remains a separate WebView flow ([ADR-0015](../../../docs/decisions/0015-youtube-playback.md)) and must not share cookies or UI with Enjoy account auth.

Backend APIs are **greenfield** — we can design `/api/v1/auth/*` endpoints that return tokens synchronously.

## Goals / Non-Goals

**Goals:**

- Native-first sign-in hub: **Google**, **Apple** (iOS/macOS), **email OTP**, and **OAuth PKCE web fallback** via system auth session + deep link.
- Unified token response: `{ accessToken, refreshToken, expiresIn, tokenType, user }` on every successful sign-in path.
- **Refresh tokens** stored in secure storage; silent refresh on `401` before sign-out.
- Retire WebView-primary sign-in and the poll timer.
- Platform-appropriate provider visibility (Apple hidden on Android/Windows; Google native skipped on Windows if unreliable).
- Account linking on backend when the same verified email appears across providers.

**Non-Goals:**

- YouTube / Google account login for playback (unchanged).
- Flutter web auth targets.
- Password-based email login (OTP only for email path).
- Social providers beyond Google/Apple in v1 (PKCE web fallback covers others indirectly).
- Changing post-auth behavior (profile sync, guest migration, library sync).

## Decisions

### 1. Native SDK + server token exchange (primary paths)

Each native provider returns a credential the **server verifies**; the app never treats IdP tokens as Enjoy API bearer tokens.

| Path | Client | Server endpoint |
|------|--------|-----------------|
| Google | `google_sign_in` → `idToken` | `POST /api/v1/auth/google` |
| Apple | `sign_in_with_apple` → `identityToken` + `authorizationCode` | `POST /api/v1/auth/apple` |
| Email | OTP UI | `POST /api/v1/auth/otp/send`, `POST /api/v1/auth/otp/verify` |

Server validates JWTs (Google/Apple JWKS), upserts user + identity row, issues Enjoy session tokens.

*Alternative considered:* keep `start_auth` + poll and only improve WebView — rejected (IdP hostility, polling UX, not best practice).

### 2. OAuth Authorization Code + PKCE for web fallback (not WebView)

Rare providers or desktop edge cases use:

1. App generates PKCE `code_verifier` / `code_challenge`.
2. Open **ASWebAuthenticationSession** (iOS/macOS), **Chrome Custom Tabs** (Android), or external browser (Windows) to `GET /api/v1/auth/authorize?...`.
3. Redirect to `https://enjoy.bot/app/auth/callback?code=...&state=...` (universal link) or `enjoyplayer://auth/callback?...` (custom scheme fallback).
4. App receives deep link, `POST /api/v1/auth/token` with `grantType: authorization_code`, `code`, `codeVerifier`, `redirectUri`.

**Never** pass `accessToken` in redirect URLs.

*Alternative considered:* InAppWebView for fallback — rejected for same IdP reasons as today.

### 3. Deep links: universal links primary, custom scheme fallback

| Platform | Mechanism |
|----------|-----------|
| Android | App Links → `https://enjoy.bot/app/auth/callback` + `assetlinks.json` |
| iOS / macOS | Associated Domains + `apple-app-site-association` |
| Windows | Register `enjoyplayer://` protocol in installer |

Flutter: `app_links` stream → auth layer validates `state` → completes PKCE exchange.

*Alternative considered:* poll-only after external browser — rejected (manual app switch, worse UX).

### 4. Refresh token rotation

- Access token TTL: **15–60 minutes** (backend choice; client reads `expiresIn`).
- Refresh token stored at `_kRefreshTokenKey` in `SecureTokenStore`.
- `ApiClient` on `401`: attempt one `POST /api/v1/auth/refresh`; retry original request; else `clearSession()`.
- Backend rotates refresh token on each use; reuse detection revokes family.

*Alternative considered:* long-lived access tokens only — rejected (weaker session hygiene).

### 5. Auth state machine (client)

```
AuthSignedOut
  → startGoogle / startApple / startOtpSend / startWebPkce
AuthAwaitingOtp(requestId, email, resendAfter)
  → verifyOtp → AuthSignedIn
AuthSigningInWebPkce(state, codeVerifier)   // waiting for deep link
  → onDeepLink → exchange → AuthSignedIn
AuthSignedIn(profile)
```

Remove `AuthSigningIn` (requestId + verificationUrl + poll) and `_pollTimer` from `AuthCtrl`.

### 6. Sign-in hub platform matrix

| Control | Android | iOS | macOS | Windows |
|---------|---------|-----|-------|---------|
| Google native | show | show | show | hide |
| Apple native | hide | show | show | hide |
| Email OTP | show | show | show | show |
| Web PKCE fallback | show | show | show | show |

iOS: Sign in with Apple **required** when Google is offered (App Store).

### 7. Account linking (backend)

```
users(id, email, …)
identities(user_id, provider, provider_uid, email_at_link)
```

- Google/Apple with **verified email** matching existing user → sign into existing user (same `user.id`).
- Apple private relay → link by `provider_uid` only; do not merge on relay email alone.
- OTP proves email ownership → merge with Google/Apple account on matching verified email.

*Alternative considered:* always create duplicate accounts — rejected (support burden).

### 8. Deprecate legacy session endpoints

Client removes all calls to `start_auth` / `poll` when this ships. Backend keeps endpoints temporarily for older app versions, then removes.

New ADR supersedes ADR-0016 (WebView-primary); references ADR-0006 / ADR-0012 for token storage and profile.

### 9. Package choices

| Package | Role |
|---------|------|
| `google_sign_in` | Google idToken |
| `sign_in_with_apple` | Apple credentials |
| `app_links` | Universal/custom scheme callbacks |
| `crypto` | PKCE code_challenge (already in pubspec) |

Evaluate `flutter_appauth` only if raw platform auth sessions are insufficient; prefer platform channels or minimal wrapper for ASWebAuthenticationSession / Custom Tabs.

## Risks / Trade-offs

- **[Backend not ready when client ships]** → Mitigation: phased rollout; email OTP endpoint first; feature-flag hub buttons.
- **[Google desktop on Windows]** → Mitigation: hide native Google on Windows; email OTP + PKCE fallback.
- **[Deep link fails / user closes browser]** → Mitigation: PKCE state timeout (5 min) → return to hub with error; no orphan poll loop.
- **[Apple relay email changes linking]** → Mitigation: identity keyed on Apple `sub`, not relay address.
- **[OTP abuse / spam]** → Mitigation: rate limits server-side; client resend countdown from `resendAfter`.
- **[Refresh token theft on rooted devices]** → Mitigation: same as today (secure storage); server rotation + reuse detection.
- **[Breaking old app versions]** → Mitigation: keep legacy endpoints on server until min app version forces upgrade.

## Migration Plan

1. **Backend**: Implement `/auth/*` endpoints + identity model + OTP delivery + hosted AASA/assetlinks.
2. **Client Phase A**: Refresh token storage + `AuthApi` extensions + repository (no UI change).
3. **Client Phase B**: Email OTP screens + hub shell (legacy WebView still available behind flag or secondary button during dogfood).
4. **Client Phase C**: Google + Apple native + platform config.
5. **Client Phase D**: PKCE fallback + deep links + remove WebView sign-in pane and poll logic.
6. **Docs**: Update `docs/features/auth.md`, add ADR, archive superseded ADR-0016 note.

**Rollback:** Feature-flag native hub; revert to legacy `start_auth` + WebView path if backend issues (requires keeping legacy code until stable).

## Open Questions

- Exact access token TTL and refresh token lifetime on backend?
- Auto-link by verified email vs prompt user to confirm merge?
- Is PKCE web fallback needed in v1 if Google + Apple + OTP cover expected users, or ship in Phase D only?
- Single Google OAuth client vs per-platform client IDs (recommended: per-platform `aud` validation)?
