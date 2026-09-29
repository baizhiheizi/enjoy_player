import 'package:enjoy_player/features/player/application/engines/youtube/youtube_monotonic_clock.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_play_retry_policy.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Transition-rule coverage for the encapsulated [YoutubeSession] latches
/// (issue #627). No WebView, no poll loop — the verbs are the test surface.
void main() {
  group('user-play in-flight invariant', () {
    test('every consuming transition clears the in-flight latch', () {
      final consumers = <String, void Function(YoutubeSession)>{
        'play rejected': (s) => s.noteUserPlayUnresolved(),
        'element error': (s) => s.noteUserPlayUnresolved(),
        'user pause command': (s) => s.noteUserPauseCommand(),
        'ended': (s) => s.noteEnded(),
        'reset for open': (s) => s.resetForOpen('next1234567'),
        'reset for clear': (s) => s.resetForClear(),
      };
      for (final entry in consumers.entries) {
        final session = YoutubeSession()..resetForOpen('abc12345678');
        session.beginUserPlay();
        session.notePlayingConfirmed();
        expect(session.userPlayInFlight, isTrue, reason: 'seed: ${entry.key}');
        entry.value(session);
        expect(
          session.userPlayInFlight,
          isFalse,
          reason: '${entry.key} must consume the in-flight play',
        );
      }
    });

    test(
      'notePlayingConfirmed keeps the latch armed (play not yet fulfilled)',
      () {
        final session = YoutubeSession()..resetForOpen('abc12345678');
        session.beginUserPlay();
        session.notePlayingConfirmed();
        expect(
          session.userPlayInFlight,
          isTrue,
          reason:
              'the D8 retry must remain reachable for the page correcting a '
              'fresh start back to paused — clearing here made it dead code',
        );
      },
    );

    test('beginUserPlay clears stale buffering while not playing', () {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      expect(session.buffering, isTrue);
      session.beginUserPlay();
      expect(session.userPlayInFlight, isTrue);
      expect(session.buffering, isFalse);
    });

    test('clearUserPlayInFlight consumes the one-shot retry budget', () {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      session.beginUserPlay();
      session.clearUserPlayInFlight();
      expect(session.userPlayInFlight, isFalse);
    });

    test('budget expires once playback outlives the attempt window', () {
      final clock = FakeMonotonicClock();
      final session = YoutubeSession(
        playRetry: YouTubePlayRetryPolicy(
          clock: clock,
          playAttemptExpiry: const Duration(milliseconds: 200),
        ),
      )..resetForOpen('abc12345678');
      addTearDown(session.closeStreams);
      session.beginUserPlay();
      session.notePlayingConfirmed();
      expect(session.userPlayInFlight, isTrue, reason: 'still inside');

      clock.advance(const Duration(milliseconds: 400));
      expect(session.userPlayInFlight, isFalse, reason: 'expired');
    });

    test('noteAutoPlayRetry stamps a recent retry, reset retires it', () {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      expect(
        session.playRetry.recentAutoRetryWithin(const Duration(minutes: 1)),
        isFalse,
      );

      session.noteAutoPlayRetry();
      expect(
        session.playRetry.recentAutoRetryWithin(const Duration(minutes: 1)),
        isTrue,
      );

      session.resetForOpen('next1234567');
      expect(
        session.playRetry.recentAutoRetryWithin(const Duration(minutes: 1)),
        isFalse,
      );
    });

    test('auto-retry attribution marks only its own playing episode', () {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      session.beginUserPlay();
      session.notePlayingConfirmed();
      expect(session.playRetry.lastPlayingFromAutoRetry, isFalse);

      session.noteAutoPlayRetry();
      expect(session.playRetry.autoRetriesIssued, 1);
      session.notePauseConfirmed();
      session.notePlayingConfirmed();
      expect(session.playRetry.lastPlayingFromAutoRetry, isTrue);

      session.noteUserPauseCommand();
      expect(session.playRetry.lastPlayingFromAutoRetry, isFalse);

      session.beginUserPlay();
      expect(session.playRetry.autoRetriesIssued, 0);
      expect(session.playRetry.lastPlayingFromAutoRetry, isFalse);
    });

    test(
      'poll-tick re-confirmations do not erase the attribution (round-5 bug)',
      () {
        final session = YoutubeSession()..resetForOpen('abc12345678');
        session.beginUserPlay();
        session.notePlayingConfirmed();
        session.noteAutoPlayRetry();
        session.notePauseConfirmed();

        session.notePlayingConfirmed();
        session.notePlayingConfirmed();
        session.notePlayingConfirmed();
        expect(
          session.playRetry.lastPlayingFromAutoRetry,
          isTrue,
          reason: 're-confirmation ticks must not erase the latch',
        );
      },
    );
  });

  group('notePlayingConfirmed', () {
    test(
      'clears streak and completion latch, keeps in-flight; emits playing',
      () async {
        final session = YoutubeSession()..resetForOpen('abc12345678');
        session
          ..notePauseStreak(2)
          ..markCompleted()
          ..beginUserPlay();

        final playingEvents = <bool>[];
        final sub = session.playingStream.listen(playingEvents.add);
        addTearDown(sub.cancel);

        session.notePlayingConfirmed();
        await Future<void>.delayed(Duration.zero);

        expect(session.playing, isTrue);
        expect(session.pausedPollStreak, 0);
        expect(session.playbackCompleted, isFalse);
        expect(session.userPlayInFlight, isTrue);
        expect(playingEvents, [true]);
      },
    );
  });

  group('noteEnded', () {
    test('emits completed exactly once and clears transport latches', () async {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      session
        ..emitPlaying(true)
        ..notePauseStreak(1)
        ..beginUserPlay();

      final completedEvents = <void>[];
      final sub = session.completed.listen(completedEvents.add);
      addTearDown(sub.cancel);

      session.noteEnded();
      session.noteEnded();
      await Future<void>.delayed(Duration.zero);

      expect(completedEvents, hasLength(1));
      expect(session.playbackCompleted, isTrue);
      expect(session.playing, isFalse);
      expect(session.buffering, isFalse);
      expect(session.userPlayInFlight, isFalse);
      expect(session.pausedPollStreak, 0);
    });

    test('notePlayingConfirmed after end re-arms the completion latch', () {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      session.noteEnded();
      expect(session.playbackCompleted, isTrue);
      session.notePlayingConfirmed();
      expect(session.playbackCompleted, isFalse);
    });

    test(
      'resetCompletionFlag lets markCompleted emit again (ADR-0044)',
      () async {
        final session = YoutubeSession()..resetForOpen('abc12345678');
        session.noteEnded();
        final completedEvents = <void>[];
        final sub = session.completed.listen(completedEvents.add);
        addTearDown(sub.cancel);

        session.resetCompletionFlag();
        session.noteEnded();
        await Future<void>.delayed(Duration.zero);
        expect(completedEvents, hasLength(1));
      },
    );
  });

  group('noteUserPlayUnresolved / notePauseConfirmed', () {
    test('unresolved settles as not playing, not buffering', () {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      session
        ..emitPlaying(true)
        ..beginUserPlay();
      session.noteUserPlayUnresolved();
      expect(session.playing, isFalse);
      expect(session.buffering, isFalse);
      expect(session.userPlayInFlight, isFalse);
    });

    test('pause confirmation resets the streak and stops transport', () {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      session
        ..emitPlaying(true)
        ..notePauseStreak(3);
      session.notePauseConfirmed();
      expect(session.pausedPollStreak, 0);
      expect(session.playing, isFalse);
      expect(session.buffering, isFalse);
    });
  });

  group('watch-page expectations', () {
    test(
      'noteWatchPageLoaded records the stop and clears recovery latches',
      () {
        final session = YoutubeSession()..resetForOpen('abc12345678');
        session
          ..noteAwaitingColdInitialNavigation()
          ..scheduleNonWatchRecovery();

        session.noteWatchPageLoaded();

        expect(session.watchPageLoadStopReceived, isTrue);
        expect(session.awaitingColdInitialNavigation, isFalse);
        expect(session.nonWatchRecoveryScheduled, isFalse);
      },
    );

    test(
      'resetWatchPageExpectations clears latches; firstPlaying optional',
      () {
        final session = YoutubeSession()
          ..resetForOpen('abc12345678')
          ..markFirstPlayingLogged()
          ..noteWatchPageLoaded();

        session.resetWatchPageExpectations(firstPlaying: false);
        expect(session.loggedFirstPlaying, isTrue);
        expect(session.watchPageLoadStopReceived, isFalse);

        session.resetWatchPageExpectations(firstPlaying: true);
        expect(session.loggedFirstPlaying, isFalse);
      },
    );

    test('clearAwaitingColdInitialNavigation leaves sibling latches alone', () {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      session
        ..noteAwaitingColdInitialNavigation()
        ..noteWatchPageLoaded()
        ..noteAwaitingColdInitialNavigation();

      session.clearAwaitingColdInitialNavigation();

      expect(session.awaitingColdInitialNavigation, isFalse);
      expect(session.watchPageLoadStopReceived, isTrue);
    });
  });

  group('pending seek + volume', () {
    test('takePendingSeekSeconds claims and clears', () {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      expect(session.takePendingSeekSeconds(), isNull);

      session.setPendingSeekSeconds(12.5);
      expect(session.takePendingSeekSeconds(), 12.5);
      expect(session.takePendingSeekSeconds(), isNull);
    });

    test('storeVolumeNormalized clamps into 0..1', () {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      expect(session.storeVolumeNormalized(1.7), 1.0);
      expect(session.storeVolumeNormalized(-0.3), 0.0);
      expect(session.storeVolumeNormalized(0.4), 0.4);
      expect(session.volumeNormalized, 0.4);
    });
  });

  group('mount state', () {
    test('mount tick notifies exactly once per mount request', () {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      var ticks = 0;
      void onTick() => ticks++;
      session.mountTick.addListener(onTick);
      addTearDown(() => session.mountTick.removeListener(onTick));

      session.requestMount();
      final afterFirst = ticks;
      session.requestMount();
      expect(ticks, afterFirst);
      expect(session.shouldMountWebView, isTrue);

      session.noteWebViewMounted();
      expect(session.webViewMounted, isTrue);
      session.noteWebViewUnmounted();
      expect(session.webViewMounted, isFalse);
      expect(session.shouldMountWebView, isTrue);
    });
  });
}
