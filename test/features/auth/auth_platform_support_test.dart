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

  test('nativeAppleSignInSupported on iOS and not on Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(nativeAppleSignInSupported, isTrue);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(nativeAppleSignInSupported, isFalse);
  });

  test('nativeAppleSignInSupported is false on macOS direct builds', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    // Desktop defaults to direct when DISTRIBUTION_CHANNEL is unset (see
    // resolveDistributionChannel); Developer ID builds omit Apple Sign-In.
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
    'nativeGoogleSignInSupported is true on iOS/macOS once '
    'kGoogleNativeSignInConfiguredOnApple is flipped on together with real '
    'GIDClientID/CFBundleURLSchemes in Info.plist (see docs/features/auth.md)',
    () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(nativeGoogleSignInSupported, isTrue);

      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(nativeGoogleSignInSupported, isTrue);
    },
  );
}
