import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, TargetPlatform;
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('YoutubePlayerEngine on Linux', () {
    test('open throws UnsupportedError on Linux (YouTube not yet available '
        'per ADR-0044)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final engine = YoutubePlayerEngine();

      await expectLater(
        () => engine.open(const YoutubePlayableSource('dQw4w9WgXcQ')),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('YouTube is not yet available on Linux'),
          ),
        ),
      );
    });

    test('youtubeEngineAvailableOnLinux is false (v1 opt-out)', () {
      expect(
        youtubeEngineAvailableOnLinux,
        false,
        reason:
            'YouTube engine is not available on Linux for v1 per ADR-0044 '
            '(webview2gtk-4.0 dependency).',
      );
    });
  });
}
