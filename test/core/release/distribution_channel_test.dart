/// Tests for [resolveDistributionChannel] and [isDirectDistributionChannel] —
/// the compile-time distribution-channel resolver that decides whether a
/// build should run the direct-download update coordinator (Windows/macOS
/// installer, Android sideload APK) or the store-only path (TestFlight,
/// Play test, future App Store/Play production).
///
/// `DISTRIBUTION_CHANNEL` is a `--dart-define`, so its value is baked at
/// compile time. In the test runner it is unset, which means every test
/// here exercises the platform-fallback branch:
///
/// * `TargetPlatform.iOS` and `TargetPlatform.android` → `store`
/// * every other platform (macOS, Windows, Linux, Fuchsia) → `direct`
///
/// [isDirectDistributionChannel] is a thin getter over [resolveDistributionChannel];
/// the tests pin that derivation as a separate contract.
library;

import 'package:enjoy_player/core/release/distribution_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DistributionChannel enum', () {
    test('exposes store and direct values', () {
      expect(DistributionChannel.values, hasLength(2));
      expect(DistributionChannel.values.toSet(), {
        DistributionChannel.store,
        DistributionChannel.direct,
      });
    });

    test('store is the mobile / app-store channel', () {
      expect(DistributionChannel.store.name, 'store');
    });

    test('direct is the sideload / installer channel', () {
      expect(DistributionChannel.direct.name, 'direct');
    });
  });

  group('resolveDistributionChannel (platform fallback)', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('iOS falls back to store', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(resolveDistributionChannel(), DistributionChannel.store);
    });

    test('Android falls back to store', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(resolveDistributionChannel(), DistributionChannel.store);
    });

    test('macOS falls back to direct', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(resolveDistributionChannel(), DistributionChannel.direct);
    });

    test('Windows falls back to direct', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(resolveDistributionChannel(), DistributionChannel.direct);
    });

    test('Linux falls back to direct (even though unsupported, the '
        'resolver still classifies it as a desktop sideload build)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(resolveDistributionChannel(), DistributionChannel.direct);
    });

    test('Fuchsia falls back to direct', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      expect(resolveDistributionChannel(), DistributionChannel.direct);
    });

    test('returns the same instance on repeated calls (no per-call '
        'randomness, no stat reads)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final a = resolveDistributionChannel();
      final b = resolveDistributionChannel();
      expect(identical(a, b), isTrue);
    });
  });

  group('isDirectDistributionChannel', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('is false on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(isDirectDistributionChannel, isFalse);
    });

    test('is false on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(isDirectDistributionChannel, isFalse);
    });

    test('is true on Windows', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(isDirectDistributionChannel, isTrue);
    });

    test('is true on macOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(isDirectDistributionChannel, isTrue);
    });

    test('is true on Linux', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(isDirectDistributionChannel, isTrue);
    });
  });

  group('resolveDistributionChannel / isDirectDistributionChannel '
      'stay in lock-step', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('direct ↔ isDirect on Windows', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(
        resolveDistributionChannel() == DistributionChannel.direct,
        isDirectDistributionChannel,
      );
    });

    test('store ↔ !isDirect on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
        resolveDistributionChannel() == DistributionChannel.direct,
        isDirectDistributionChannel,
      );
    });
  });
}
