import 'package:enjoy_player/features/auth/domain/auth_platform_support.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authPkceRedirectUri uses the custom scheme on mobile-like targets', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(authPkceRedirectUri(), 'enjoyplayer://auth/callback');
  });

  test('authPkceRedirectUri uses the custom scheme on windows', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(authPkceRedirectUri(), 'enjoyplayer://auth/callback');
  });

  test('nativeAppleSignInSupported only on Apple platforms', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(nativeAppleSignInSupported, isTrue);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(nativeAppleSignInSupported, isFalse);
  });

  test('nativeGoogleSignInSupported is false on windows', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(nativeGoogleSignInSupported, isFalse);
  });

  test('nativeGoogleSignInSupported is true on android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(nativeGoogleSignInSupported, isTrue);
  });

  test(
    'nativeGoogleSignInSupported stays hidden on iOS/macOS until '
    'kGoogleNativeSignInConfiguredOnApple is flipped on — calling '
    'GIDSignIn.signIn() beforehand crashes the app with an uncatchable '
    'native exception (see docs/features/auth.md)',
    () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(nativeGoogleSignInSupported, isFalse);

      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(nativeGoogleSignInSupported, isFalse);
    },
  );
}
