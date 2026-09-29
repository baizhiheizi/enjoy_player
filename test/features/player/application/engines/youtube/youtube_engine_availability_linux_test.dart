import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:enjoy_player/features/player/domain/youtube_playback_unavailable_exception.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_stage_resolver.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, TargetPlatform;
import 'package:flutter/material.dart' show MaterialApp, Scaffold;
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('YoutubePlayerEngine on Linux', () {
    test(
      'open throws the typed unavailable exception on Linux (ADR-0048)',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        final engine = YoutubePlayerEngine();

        await expectLater(
          () => engine.open(const YoutubePlayableSource('dQw4w9WgXcQ')),
          throwsA(
            isA<YouTubePlaybackUnavailableException>().having(
              (e) => e.message,
              'message',
              contains('YouTube is not yet available on Linux'),
            ),
          ),
        );
        await engine.dispose();
      },
    );

    test('youtubeEngineAvailableOnLinux is false (v1 opt-out)', () {
      expect(
        youtubeEngineAvailableOnLinux,
        false,
        reason:
            'YouTube engine is not available on Linux for v1 per ADR-0048 '
            '(webview2gtk-4.0 dependency).',
      );
    });

    test(
      'awaitSurfaceReady resolves promptly on Linux instead of polling 8s',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        final engine = YoutubePlayerEngine();

        await expectLater(
          engine.awaitSurfaceReady().timeout(const Duration(seconds: 1)),
          completes,
        );
        await engine.dispose();
      },
    );

    testWidgets(
      'warmVideoSurface + the video stage never mount the WebView host on Linux',
      (tester) async {
        final engine = YoutubePlayerEngine();
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          engine.warmVideoSurface();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: buildPlayerVideoStage(
                  engine,
                  maxWidth: 400,
                  maxHeight: 300,
                ),
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
        await engine.dispose();
      },
    );
  });
}
