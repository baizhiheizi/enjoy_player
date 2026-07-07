/// Google OAuth client IDs for native Google Sign-In.
///
/// These are public OAuth client identifiers (not secrets) issued by Google
/// Cloud Console for this app's project — safe to embed in client code, the
/// same way they ship in `google-services.json` / `GoogleService-Info.plist`.
library;

/// Web application OAuth client ID (matches `google.client_id` in enjoy_web's
/// Rails credentials). Passed as `serverClientId` on Android so the ID token
/// returned by the SDK carries this audience, which the backend already
/// verifies by default for requests without a `platform` (and as the
/// `android` platform fallback — see
/// `NativeAuth::GoogleIdTokenVerifier.audience_for` in enjoy_web).
const String kGoogleWebClientId =
    '93185289922-28sf8q3ekkoo6lu3nflc8cjtult1clbr.apps.googleusercontent.com';

/// Whether `ios/Runner/Info.plist` and `macos/Runner/Info.plist` have been
/// updated with a real iOS/macOS-type OAuth client (`GIDClientID` + the
/// matching reversed-client-id `CFBundleURLSchemes` entry), replacing the
/// `REPLACE_WITH_*` placeholders those files ship with by default.
///
/// The `google_sign_in` iOS/macOS implementation reads `GIDClientID`
/// directly from Info.plist (see comment on `GoogleSignInService`) — Dart
/// never passes a client ID on those platforms, so this flag can't be
/// derived from the client ID above. It exists purely to gate the "Continue
/// with Google" button (see [nativeGoogleSignInSupported]): calling
/// `GIDSignIn.signIn()` while Info.plist still has the placeholder throws an
/// **uncaught** `NSInvalidArgumentException` ("Your app is missing support
/// for the following URL schemes: com.googleusercontent.apps....") that
/// crashes the whole process — it happens inside Google's native SDK before
/// control returns to Dart, so no Dart `try`/`catch` can intercept it.
///
/// Flip this to `true` in the same change that fills in the real
/// `GIDClientID`/`CFBundleURLSchemes` values (see
/// `docs/features/auth.md#google-oauth-client-setup-manual-one-time`).
const bool kGoogleNativeSignInConfiguredOnApple = true;
