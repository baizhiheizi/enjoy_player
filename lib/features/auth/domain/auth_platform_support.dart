/// Which native auth providers are offered on the current platform.
library;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

import 'package:enjoy_player/features/auth/domain/google_auth_config.dart';

/// Google native SDK is unreliable on Windows desktop. On iOS/macOS it is
/// additionally gated on [kGoogleNativeSignInConfiguredOnApple]: those
/// platforms crash the process (uncatchable native `NSException`) if
/// `GIDSignIn.signIn()` is invoked before Info.plist has a real OAuth client
/// configured, so the button must stay hidden until that setup is done.
bool get nativeGoogleSignInSupported {
  if (defaultTargetPlatform == TargetPlatform.windows) return false;
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    return kGoogleNativeSignInConfiguredOnApple;
  }
  return true;
}

/// Sign in with Apple is available on Apple platforms only.
bool get nativeAppleSignInSupported =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// OAuth PKCE redirect URI for the current platform.
///
/// Always the custom URL scheme: the backend's client registry
/// (`config/native_auth_clients.yml` in enjoy_web) only whitelists
/// `enjoyplayer://auth/callback` (plus loopback URLs for dev). A universal
/// link (`https://enjoy.bot/app/auth/callback`) would also require the
/// backend to host `apple-app-site-association` / `assetlinks.json`, which
/// it does not.
String authPkceRedirectUri() => 'enjoyplayer://auth/callback';

/// Platform string sent to `POST /api/v1/auth/google`.
String? authGooglePlatformParam() {
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.macOS => 'macos',
    _ => null,
  };
}
