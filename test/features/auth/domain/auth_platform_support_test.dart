import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/core/release/distribution_channel.dart';
import 'package:enjoy_player/features/auth/domain/auth_platform_support.dart';
import 'package:enjoy_player/features/auth/domain/google_auth_config.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, TargetPlatform;
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('nativeGoogleSignInSupported', () {
    test('returns false on Windows', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(
        nativeGoogleSignInSupported,
        false,
        reason: 'The Google native SDK is unreliable on Windows desktop.',
      );
    });

    test('follows the platform-availability flag on Linux (ADR-0084)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(
        nativeGoogleSignInSupported,
        googleSignInAvailableOnLinux,
        reason: 'The Linux branch must follow the platform-availability flag.',
      );
      expect(
        googleSignInAvailableOnLinux,
        isFalse,
        reason:
            'The Google Sign-In browser-based OAuth flow fails on real '
            'Linux installs; the button is hidden and users sign in with '
            'email OTP or the web PKCE fallback (ADR-0084).',
      );
    });

    test('returns true on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(nativeGoogleSignInSupported, true);
    });

    test('follows the Apple client configuration on iOS and macOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(nativeGoogleSignInSupported, kGoogleNativeSignInConfiguredOnApple);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(nativeGoogleSignInSupported, kGoogleNativeSignInConfiguredOnApple);
    });
  });

  group('nativeAppleSignInSupported', () {
    test('returns true on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(nativeAppleSignInSupported, true);
    });

    test('returns false on macOS for a direct-download build', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      if (resolveDistributionChannel() != DistributionChannel.direct) {
        markTestSkipped(
          'this build targets the store channel, where macOS keeps the '
          'Apple Sign-In entitlement',
        );
        return;
      }
      expect(
        nativeAppleSignInSupported,
        false,
        reason:
            'Developer ID direct-download macOS builds omit the Apple '
            'Sign-In entitlement.',
      );
    });

    test('returns true on macOS for a store build', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      if (resolveDistributionChannel() != DistributionChannel.store) {
        markTestSkipped(
          'this build targets the direct channel, where macOS omits the '
          'Apple Sign-In entitlement',
        );
        return;
      }
      expect(
        nativeAppleSignInSupported,
        true,
        reason: 'Store builds ship the Apple Sign-In entitlement.',
      );
    });

    test('returns false on Windows, Linux, and Android', () {
      for (final platform in <TargetPlatform>[
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.android,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(nativeAppleSignInSupported, false, reason: '$platform');
      }
    });
  });

  group('authGooglePlatformParam', () {
    test('returns the platform tag for Android, iOS, and macOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(authGooglePlatformParam(), 'android');
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(authGooglePlatformParam(), 'ios');
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(authGooglePlatformParam(), 'macos');
    });

    test('returns null on Windows and Linux', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(authGooglePlatformParam(), isNull);
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(authGooglePlatformParam(), isNull);
    });
  });

  group('authPkceRedirectUri', () {
    test('always uses the custom URL scheme on every platform', () {
      for (final platform in TargetPlatform.values) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          authPkceRedirectUri(),
          'enjoyplayer://auth/callback',
          reason: '$platform',
        );
      }
    });
  });
}
