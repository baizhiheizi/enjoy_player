import 'dart:ui' show Size;

import 'package:enjoy_player/core/platform/device_form_factor.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveDeviceFormFactor', () {
    test('desktop platforms always return desktop', () {
      for (final platform in [
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        expect(
          resolveDeviceFormFactor(platform: platform, shortestSideLogical: 320),
          DeviceFormFactor.desktop,
        );
        expect(
          resolveDeviceFormFactor(
            platform: platform,
            shortestSideLogical: 1200,
          ),
          DeviceFormFactor.desktop,
        );
      }
    });

    test('mobile below 600 is phone', () {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        expect(
          resolveDeviceFormFactor(platform: platform, shortestSideLogical: 599),
          DeviceFormFactor.phone,
        );
        expect(
          resolveDeviceFormFactor(platform: platform, shortestSideLogical: 390),
          DeviceFormFactor.phone,
        );
      }
    });

    test('mobile at or above 600 is tablet', () {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        expect(
          resolveDeviceFormFactor(platform: platform, shortestSideLogical: 600),
          DeviceFormFactor.tablet,
        );
        expect(
          resolveDeviceFormFactor(platform: platform, shortestSideLogical: 768),
          DeviceFormFactor.tablet,
        );
      }
    });

    test('invalid shortest side returns null on mobile (defer lock)', () {
      expect(
        resolveDeviceFormFactor(
          platform: TargetPlatform.android,
          shortestSideLogical: 0,
        ),
        isNull,
      );
      expect(
        resolveDeviceFormFactor(
          platform: TargetPlatform.iOS,
          shortestSideLogical: double.nan,
        ),
        isNull,
      );
    });
  });

  group('preferredOrientationsFor', () {
    test('phone is portrait only', () {
      expect(preferredOrientationsFor(DeviceFormFactor.phone), [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    });

    test('tablet allows all orientations', () {
      expect(preferredOrientationsFor(DeviceFormFactor.tablet), [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });

    test('desktop returns null (do not call SystemChrome)', () {
      expect(preferredOrientationsFor(DeviceFormFactor.desktop), isNull);
    });
  });

  group('logicalShortestSideOf', () {
    test('returns min of width and height', () {
      expect(logicalShortestSideOf(const Size(390, 844)), 390);
      expect(logicalShortestSideOf(const Size(1024, 768)), 768);
      expect(logicalShortestSideOf(const Size(600, 600)), 600);
    });
  });

  group('applyPreferredOrientationsForFormFactor', () {
    test('desktop is a no-op (null orientations)', () async {
      // Manual SystemChrome verification is device-only; desktop path must
      // not throw and must not require a binding channel call.
      await applyPreferredOrientationsForFormFactor(DeviceFormFactor.desktop);
    });
  });
}
