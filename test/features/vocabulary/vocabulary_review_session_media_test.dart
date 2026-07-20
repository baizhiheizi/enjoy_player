import 'package:enjoy_player/features/player/domain/echo_window.dart';
import 'package:enjoy_player/features/player/domain/player_launch_request.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_media.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('clip open vs restored position', () {
    test('echo enforcer pause-rewinds when position is past clip window', () {
      // Documents why playVocabularyClip must seek before echo.activate:
      // openMedia restores ~lesson position; activating the clip window first
      // yields pauseAndRewind and aborts HTML5 play().
      const window = (start: 10.0, end: 15.0);
      final decision = decideEchoPlaybackTime(712.0, window);
      expect(decision, isA<EchoPauseAndRewind>());
    });

    test('inside clip window after seek is EchoOk', () {
      const window = (start: 10.0, end: 15.0);
      expect(decideEchoPlaybackTime(12.0, window), isA<EchoOk>());
    });
  });

  group('mediaLocatorWindow', () {
    test('converts ms locator to seconds', () {
      const locator = MediaLocator(start: 1500, duration: 2500);
      final window = mediaLocatorWindow(locator);
      expect(window.startSec, 1.5);
      expect(window.endSec, 4.0);
    });
  });

  group('vocabularyContextSupportsMediaActions', () {
    test('requires media locator and video/audio source', () {
      final media = VocabularyContext(
        id: 'c1',
        vocabularyItemId: 'i1',
        text: 'hi',
        sourceType: VocabularySourceType.video,
        sourceId: 'v1',
        locator: const MediaLocator(start: 0, duration: 1000),
        createdAt: DateTime.utc(2020),
        updatedAt: DateTime.utc(2020),
      );
      expect(vocabularyContextSupportsMediaActions(media), isTrue);

      final ebook = VocabularyContext(
        id: 'c2',
        vocabularyItemId: 'i1',
        text: 'hi',
        sourceType: VocabularySourceType.ebook,
        sourceId: 'e1',
        locator: null,
        createdAt: DateTime.utc(2020),
        updatedAt: DateTime.utc(2020),
      );
      expect(vocabularyContextSupportsMediaActions(ebook), isFalse);
    });
  });

  group('PlayerLaunchRequest.vocabularyOpenSource', () {
    test('encodes expanded open with the locator echo window', () {
      final req = PlayerLaunchRequest.vocabularyOpenSource(
        mediaId: 'media-42',
        startSec: 3.0,
        endSec: 5.0,
      );
      expect(req.autoplay, isTrue);
      expect(req.activateClipWindow, isTrue);
      expect(req.isExplicitLaunch, isTrue);
      expect(
        req.location,
        '/player/media-42?start=3&end=5&autoplay=1&clip=1&norestore=1',
      );

      final parsed = PlayerLaunchRequest.fromUri(
        Uri.parse(req.location),
        mediaId: 'media-42',
      );
      expect(parsed.startSec, 3.0);
      expect(parsed.endSec, 5.0);
      expect(parsed.autoplay, isTrue);
      expect(parsed.activateClipWindow, isTrue);
      expect(parsed.isExplicitLaunch, isTrue);
    });
  });
}
