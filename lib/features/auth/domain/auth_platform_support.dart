/// Which native auth providers are offered on the current platform.
library;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Google native SDK is unreliable on Windows desktop.
bool get nativeGoogleSignInSupported =>
    defaultTargetPlatform != TargetPlatform.windows;

/// Sign in with Apple is available on Apple platforms only.
bool get nativeAppleSignInSupported =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// OAuth PKCE redirect URI for the current platform.
String authPkceRedirectUri({required bool preferUniversalLink}) {
  if (preferUniversalLink &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    return 'https://enjoy.bot/app/auth/callback';
  }
  return 'enjoyplayer://auth/callback';
}

/// Platform string sent to `POST /api/v1/auth/google`.
String? authGooglePlatformParam() {
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.macOS => 'macos',
    _ => null,
  };
}
