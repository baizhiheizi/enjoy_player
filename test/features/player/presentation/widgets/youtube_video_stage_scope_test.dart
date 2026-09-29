import 'package:flutter/foundation.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_session.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_bridge.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_video_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The stage root [Stack] — the outermost of the two (root + buffering leaf).
/// It is not const, so its widget instance is replaced only when the stage
/// root itself rebuilds.
Stack _stageRootStack(WidgetTester tester) =>
    tester.widgetList<Stack>(find.byType(Stack)).first;

void main() {
  testWidgets('a buffering flip leaves the stage root subtree untouched', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final session = YoutubeSession()..resetForOpen('abc12345678');
    final engine = YoutubePlayerEngine(session: session);
    try {
      engine.setPosterUrl('https://example.com/thumb.jpg');

      Future<void> settle() async {
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump();
      }

      Future<void> mount() async {
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
        await settle();
      }

      await mount();

      session.notePlayingConfirmed();
      session.markFirstPlayingLogged();
      session.emitBuffering(false);
      await settle();
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final stageRootBefore = _stageRootStack(tester);

      session.emitBuffering(true);
      await settle();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        _stageRootStack(tester),
        same(stageRootBefore),
        reason:
            'A buffering flip must not rebuild the stage root (issue #663 A)',
      );

      session.emitBuffering(false);
      await settle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        _stageRootStack(tester),
        same(stageRootBefore),
        reason:
            'A buffering flip must not rebuild the stage root (issue #663 A)',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
    await engine.dispose();
  });

  test('player WebView settings are a cached instance', () {
    expect(
      identical(
        YoutubeWebViewSettings.forPlayer(),
        YoutubeWebViewSettings.forPlayer(),
      ),
      isTrue,
    );
  });
}
