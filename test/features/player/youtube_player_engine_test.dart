import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YoutubePlayerEngine mount lifecycle', () {
    test(
      'ensureWebViewAttached sets shouldMountWebView without duplicate hosts',
      () async {
        final engine = YoutubePlayerEngine();
        expect(engine.shouldMountWebView, isFalse);
        expect(engine.webViewMounted, isFalse);

        engine.ensureWebViewAttached();
        expect(engine.shouldMountWebView, isTrue);
        expect(engine.webViewMounted, isFalse);

        await engine.idleAfterClear();
        expect(engine.shouldMountWebView, isFalse);
        expect(engine.currentVideoId, isEmpty);
      },
    );

    test('open requests mount and sets video id', () async {
      final engine = YoutubePlayerEngine();
      await engine.open(const YoutubePlayableSource('abc12345678'));
      expect(engine.currentVideoId, 'abc12345678');
      expect(engine.shouldMountWebView, isTrue);
    });

    test(
      'warmVideoSurface only requests mount (no redundant idle navigation)',
      () {
        final engine = YoutubePlayerEngine();
        engine.warmVideoSurface();
        expect(engine.shouldMountWebView, isTrue);
        expect(engine.currentVideoId, isEmpty);
      },
    );
  });
}
