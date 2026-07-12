import 'package:enjoy_player/features/player/application/engines/youtube/youtube_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YoutubeSession.markCompleted (ADR-0044)', () {
    late YoutubeSession session;

    setUp(() {
      session = YoutubeSession();
    });

    tearDown(() async {
      await session.closeStreams();
    });

    test('emits on the completed stream on first transition', () async {
      final events = <void>[];
      final sub = session.completed.listen(events.add);

      session.markCompleted();
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(session.playbackCompleted, isTrue);
      await sub.cancel();
    });

    test('is idempotent — second call does not emit again', () async {
      final events = <void>[];
      final sub = session.completed.listen(events.add);

      session.markCompleted();
      session.markCompleted();
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      await sub.cancel();
    });

    test(
      'resetForOpen re-arms the emission for the next end-of-media',
      () async {
        final events = <void>[];
        final sub = session.completed.listen(events.add);

        session.markCompleted();
        await Future<void>.delayed(Duration.zero);

        session.resetForOpen('newVideoId');
        session.markCompleted();
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(2));
        await sub.cancel();
      },
    );
  });
}
