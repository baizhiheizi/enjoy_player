import 'package:flutter/foundation.dart';
import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_host.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_video_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final platforms = <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.macOS,
    TargetPlatform.linux,
    TargetPlatform.windows,
  ];

  for (final platform in platforms) {
    testWidgets(
      'the WebView host mounts on $platform when the engine can play',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        final engine = YoutubePlayerEngine(
          availability: const YouTubeAvailable(),
        );
        try {
          engine.session.requestMount();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: YoutubeVideoStage(
                  engine: engine,
                  maxWidth: 320,
                  maxHeight: 180,
                ),
              ),
            ),
          );
          await tester.pump();

          expect(find.byType(YoutubeWebViewHost), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
          await engine.dispose();
        }
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YoutubeVideoStage(
              engine: engine,
              maxWidth: 320,
              maxHeight: 180,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(YoutubeWebViewHost), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      await engine.dispose();
    }
  });

  testWidgets('the WebView host stays unmounted until a mount is requested', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final engine = YoutubePlayerEngine(availability: const YouTubeAvailable());
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YoutubeVideoStage(
              engine: engine,
              maxWidth: 320,
              maxHeight: 180,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(YoutubeWebViewHost), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      await engine.dispose();
    }
  });
}
