import 'package:enjoy_player/features/auth/domain/auth_platform_support.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, TargetPlatform;
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('nativeGoogleSignInSupported on Linux', () {
    test('returns true on Linux (google_sign_in is enabled by default per '
        'ADR-0048)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(
        nativeGoogleSignInSupported,
        true,
        reason:
            'Google Sign-In is available on Linux via browser-based '
            'OAuth flow. If smoke shows a crash, flip '
            'googleSignInAvailableOnLinux to false.',
      );
    });

    test('does not throw on Linux', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(() => nativeGoogleSignInSupported, returnsNormally);
    });
  });

  group('nativeAppleSignInSupported on Linux', () {
    test('returns false on Linux (Apple Sign-In is macOS/iOS only)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(
        nativeAppleSignInSupported,
        false,
        reason: 'Apple Sign-In is not available outside iOS/macOS.',
      );
    });

    test('does not throw on Linux', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(() => nativeAppleSignInSupported, returnsNormally);
    });
  });

  group('authGooglePlatformParam on Linux', () {
    test('returns null on Linux (no platform string sent for Google auth on '
        'Linux)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(
        authGooglePlatformParam(),
        null,
        reason:
            'The backend does not classify Linux as a distinct Google '
            'auth platform today. The null value signals "desktop, no '
            'platform param."',
      );
    });

    test('does not throw on Linux', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(() => authGooglePlatformParam(), returnsNormally);
    });
  });
}
