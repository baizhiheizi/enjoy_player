import 'package:flutter/foundation.dart';
import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_host.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_video_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _stage(YoutubePlayerEngine engine, {VoidCallback? onWatchdogStarted}) {
  return MaterialApp(
    home: Scaffold(
      body: YoutubeVideoStage(
        engine: engine,
        maxWidth: 320,
        maxHeight: 180,
        debugOnWatchdogStarted: onWatchdogStarted,
      ),
    ),
  );
}

Future<void> _withPlayableEngine(
  TargetPlatform platform,
  Future<void> Function(YoutubePlayerEngine engine) body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  final engine = YoutubePlayerEngine(availability: const YouTubeAvailable());
  try {
    await body(engine);
  } finally {
    await engine.dispose();
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  for (final platform in TargetPlatform.values) {
    testWidgets(
      'the WebView host mounts on $platform once playback requested a mount',
      (tester) async {
        await _withPlayableEngine(platform, (engine) async {
          engine.session.requestMount();

          await tester.pumpWidget(_stage(engine));

          expect(find.byType(YoutubeWebViewHost), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      },
    );
  }

  testWidgets('the WebView host stays unmounted when the engine cannot play', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final engine = YoutubePlayerEngine(
      availability: const YouTubeUnavailable(
        YouTubeUnavailableReason.runtimeMissing,
      ),
    );
    try {
      engine.session.requestMount();

      await tester.pumpWidget(_stage(engine));
      await tester.pump();

      expect(find.byType(YoutubeWebViewHost), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      await engine.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the WebView host stays unmounted until a mount is requested', (
    tester,
  ) async {
    await _withPlayableEngine(TargetPlatform.macOS, (engine) async {
      await tester.pumpWidget(_stage(engine));
      await tester.pump();

      expect(find.byType(YoutubeWebViewHost), findsNothing);
      expect(tester.takeException(), isNull);

      engine.session.requestMount();
      await tester.pump();

      expect(find.byType(YoutubeWebViewHost), findsOneWidget);
    });
  });

  testWidgets('the frame-stall probe starts on Linux after first playing', (
    tester,
  ) async {
    await _withPlayableEngine(TargetPlatform.linux, (engine) async {
      var watchdogStarts = 0;
      engine.session
        ..resetForOpen('abc12345678')
        ..markFirstPlayingLogged()
        ..requestMount();

      await tester.pumpWidget(
        _stage(engine, onWatchdogStarted: () => watchdogStarts++),
      );

      expect(watchdogStarts, 1);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  for (final platform in TargetPlatform.values.where(
    (platform) => platform != TargetPlatform.linux,
  )) {
    testWidgets('the frame-stall probe never starts on $platform', (
      tester,
    ) async {
      await _withPlayableEngine(platform, (engine) async {
        var watchdogStarts = 0;
        engine.session
          ..resetForOpen('abc12345678')
          ..markFirstPlayingLogged()
          ..requestMount();

        await tester.pumpWidget(
          _stage(engine, onWatchdogStarted: () => watchdogStarts++),
        );
        await tester.pump(const Duration(seconds: 2));

        expect(watchdogStarts, 0);
        expect(find.byType(YoutubeWebViewHost), findsOneWidget);
      });
    });
  }
}
