import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, TargetPlatform;
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('MediaKitPlayerEngine on Linux', () {
    test('can be instantiated on Linux without throwing', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final engine = MediaKitPlayerEngine();
      expect(engine, isNotNull);
      // The engine is lazily initialized; constructing it should not allocate
      // the native player yet (per the constructor doc).
    });

    test('warmVideoSurface does not throw on Linux', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final engine = MediaKitPlayerEngine();
      expect(() => engine.warmVideoSurface(), returnsNormally);
    });

    test(
      'supportsVideoPosterCapture is true on Linux (same as other desks)',
      () {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        final engine = MediaKitPlayerEngine();
        expect(
          engine.supportsVideoPosterCapture,
          true,
          reason: 'media_kit screenshot works on Linux (libmpv frame capture).',
        );
      },
    );
  });
}
