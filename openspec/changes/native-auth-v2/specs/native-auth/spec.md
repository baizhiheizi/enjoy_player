## ADDED Requirements

### Requirement: Native sign-in hub

The app SHALL present a sign-in hub with provider actions before starting any auth flow. The hub SHALL offer **Continue with Google** (where native Google is supported), **Continue with Apple** (iOS and macOS only), **Continue with Email**, and **Other sign-in options** (OAuth PKCE web fallback). The hub SHALL NOT load the Enjoy account verification page in an InAppWebView as the default or primary path.

#### Scenario: Hub shown when signed out

- **WHEN** the user opens the sign-in screen and auth state is signed out
- **THEN** the app SHALL show the native sign-in hub with at least Email OTP and web fallback options

#### Scenario: Apple hidden on Android

- **WHEN** the user opens the sign-in hub on Android
- **THEN** the app SHALL NOT show Continue with Apple

#### Scenario: Google native hidden on Windows

- **WHEN** the user opens the sign-in hub on Windows
- **THEN** the app SHALL NOT show Continue with Google (native) and SHALL still offer Email OTP and web fallback

### Requirement: Google native sign-in

On platforms where Google native sign-in is offered, the app SHALL use the platform Google Sign-In SDK to obtain an ID token and SHALL exchange it with `POST /api/v1/auth/google` for Enjoy session tokens. On success the app SHALL persist tokens and transition to signed-in state without polling.

#### Scenario: Successful Google sign-in

- **WHEN** the user taps Continue with Google and completes the Google account picker
- **THEN** the app SHALL POST the ID token to the backend and SHALL store `accessToken` and `refreshToken` on success

#### Scenario: Google sign-in cancelled

- **WHEN** the user cancels the Google account picker
- **THEN** the app SHALL return to the sign-in hub without error snackbar unless the platform reports an unexpected failure

#### Scenario: Google sign-in API failure

- **WHEN** the backend rejects the Google token exchange
- **THEN** the app SHALL show a user-visible error and SHALL remain signed out

### Requirement: Apple native sign-in

On iOS and macOS, the app SHALL use Sign in with Apple to obtain `identityToken` and `authorizationCode` and SHALL exchange them with `POST /api/v1/auth/apple` for Enjoy session tokens. The app MUST offer Sign in with Apple whenever Google native sign-in is offered on iOS (App Store policy).

#### Scenario: Successful Apple sign-in

- **WHEN** the user completes Sign in with Apple
- **THEN** the app SHALL POST credentials to the backend and SHALL store session tokens without polling

#### Scenario: Apple first-time name payload

- **WHEN** Apple provides a full name on first authorization only
- **THEN** the app SHALL include that name in the exchange request so the backend can populate the profile

### Requirement: Email OTP sign-in

The app SHALL support passwordless email sign-in via OTP. The user SHALL enter an email address, receive a one-time code, enter the code on a native screen, and complete sign-in via `POST /api/v1/auth/otp/send` and `POST /api/v1/auth/otp/verify`.

#### Scenario: OTP send success

- **WHEN** the user submits a valid email on the email entry screen
- **THEN** the app SHALL call the send endpoint and SHALL navigate to an OTP entry screen bound to the returned `requestId`

#### Scenario: OTP verify success

- **WHEN** the user submits the correct OTP code before expiry
- **THEN** the app SHALL receive session tokens and SHALL sign in without polling

#### Scenario: OTP resend cooldown

- **WHEN** the send response includes `resendAfter` seconds
- **THEN** the app SHALL disable resend until that interval elapses

#### Scenario: Invalid OTP

- **WHEN** the user submits an incorrect or expired OTP
- **THEN** the app SHALL show an error and SHALL allow retry or requesting a new code per backend rules

### Requirement: OAuth PKCE web fallback

The app SHALL support web-based sign-in for providers not covered by native SDKs using OAuth 2.0 Authorization Code with PKCE. The app SHALL open the authorize URL in a system auth session (ASWebAuthenticationSession / Chrome Custom Tabs / external browser on Windows), NOT in an InAppWebView. Completion SHALL occur via deep link callback carrying an authorization `code`, followed by `POST /api/v1/auth/token` exchange.

#### Scenario: PKCE flow start

- **WHEN** the user selects Other sign-in options
- **THEN** the app SHALL generate PKCE verifier/challenge, open the authorize URL with `state`, and wait for a matching deep link

#### Scenario: Deep link completes sign-in

- **WHEN** the app receives a callback URL with matching `state` and authorization `code`
- **THEN** the app SHALL exchange the code with the stored code verifier and SHALL sign in on success

#### Scenario: Deep link state mismatch

- **WHEN** the callback `state` does not match the in-flight PKCE session
- **THEN** the app SHALL ignore the callback and SHALL NOT sign in

#### Scenario: User abandons web fallback

- **WHEN** the user closes the auth session without completing login
- **THEN** the app SHALL return to the sign-in hub after timeout or cancel without a poll loop

### Requirement: Session tokens and refresh

The app SHALL store `accessToken` and `refreshToken` in `flutter_secure_storage`. The app SHALL NOT store tokens in Drift. On an API `401` response, the app SHALL attempt one token refresh via `POST /api/v1/auth/refresh` before clearing the session.

#### Scenario: Refresh success

- **WHEN** an authenticated request returns 401 and a refresh token exists
- **THEN** the app SHALL refresh tokens, persist the new pair, and retry the failed request once

#### Scenario: Refresh failure

- **WHEN** refresh fails or no refresh token exists after 401
- **THEN** the app SHALL clear auth secrets and transition to signed out

### Requirement: Post-sign-in behavior unchanged

After any successful native auth path, the app SHALL fetch or use the returned user profile, apply locale/language preferences per existing auth rules, navigate home, and offer guest migration when applicable. Token and profile handling SHALL remain compatible with existing profile and sync features.

#### Scenario: Navigate home after sign-in

- **WHEN** auth state becomes signed in from any new auth path
- **THEN** the app SHALL navigate to home the same as today's WebView flow

### Requirement: Legacy WebView poll auth removed

The app SHALL NOT use `POST /api/v1/sessions/start_auth` with InAppWebView verification and `GET /api/v1/sessions/poll` as the primary sign-in mechanism once this capability ships.

#### Scenario: No poll timer on sign-in

- **WHEN** the user starts sign-in via Google, Apple, Email OTP, or PKCE fallback
- **THEN** the app SHALL NOT start a periodic poll timer for session approval

#### Scenario: No WebView verification pane as default

- **WHEN** the user opens sign-in from settings or profile
- **THEN** the app SHALL NOT automatically embed the verification URL in InAppWebView

### Requirement: Sign-out clears all session secrets

Sign-out SHALL clear access token, refresh token, and cached profile JSON from secure storage, matching existing session teardown semantics.

#### Scenario: Sign out

- **WHEN** the user signs out
- **THEN** the app SHALL remove both access and refresh tokens and cached profile
