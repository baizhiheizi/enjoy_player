import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:enjoy_player/features/player/domain/youtube_playback_unavailable_exception.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_stage_resolver.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_host.dart';
import 'package:flutter/material.dart' show MaterialApp, Scaffold;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YoutubePlayerEngine with an unavailable runtime (specs/047)', () {
    const unavailable = YouTubeUnavailable(
      YouTubeUnavailableReason.runtimeMissing,
    );

    test(
      'open throws the typed unavailable exception carrying the watch URL',
      () async {
        final engine = YoutubePlayerEngine(availability: unavailable);

        await expectLater(
          () => engine.open(const YoutubePlayableSource('dQw4w9WgXcQ')),
          throwsA(
            isA<YouTubePlaybackUnavailableException>()
                .having((e) => e.message, 'message', contains('runtimeMissing'))
                .having(
                  (e) => e.youtubeUrl,
                  'youtubeUrl',
                  'https://m.youtube.com/watch?v=dQw4w9WgXcQ',
                ),
          ),
        );
        await engine.dispose();
      },
    );

    test('awaitSurfaceReady resolves promptly without a mount', () async {
      final engine = YoutubePlayerEngine(availability: unavailable);

      await expectLater(
        engine.awaitSurfaceReady().timeout(const Duration(seconds: 1)),
        completes,
      );
      await engine.dispose();
    });

    test('warmVideoSurface never requests a mount', () {
      final engine = YoutubePlayerEngine(availability: unavailable);

      engine.warmVideoSurface();

      expect(engine.session.shouldMountWebView, isFalse);
      expect(engine.availability.canPlay, isFalse);
    });

    testWidgets(
      'the video stage never mounts the WebView host when unavailable',
      (tester) async {
        final engine = YoutubePlayerEngine(availability: unavailable);
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

        expect(find.byType(YoutubeWebViewHost), findsNothing);
        expect(tester.takeException(), isNull);
        await engine.dispose();
      },
    );
  });

  group('YoutubePlayerEngine kill-switch mapping', () {
    test('disabledByBuild maps onto the linuxOptedOut exception', () async {
      final engine = YoutubePlayerEngine(
        availability: const YouTubeUnavailable(
          YouTubeUnavailableReason.disabledByBuild,
        ),
      );

      await expectLater(
        () => engine.open(const YoutubePlayableSource('abc123')),
        throwsA(
          isA<YouTubePlaybackUnavailableException>().having(
            (e) => e.youtubeUrl,
            'youtubeUrl',
            'https://m.youtube.com/watch?v=abc123',
          ),
        ),
      );
      await engine.dispose();
    });
  });
}
