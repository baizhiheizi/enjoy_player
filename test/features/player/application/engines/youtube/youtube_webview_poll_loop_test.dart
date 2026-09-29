import 'dart:async';

import 'package:enjoy_player/features/player/application/engines/youtube/youtube_js_channel.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_monotonic_clock.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_play_retry_policy.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_session.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_poll_loop.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _ResultFn =
    void Function({
      required Duration position,
      Duration? newDuration,
      required bool jsPaused,
      required bool jsEnded,
    });

class _FakePollDriver {
  _ResultFn? latest;
  int calls = 0;

  Future<void> poll({
    required bool disposed,
    required YoutubeJsChannel? channel,
    required void Function({
      required Duration position,
      Duration? newDuration,
      required bool jsPaused,
      required bool jsEnded,
    })
    onResult,
  }) async {
    calls++;
    latest = onResult;
  }

  void emit({
    Duration position = Duration.zero,
    Duration? newDuration,
    required bool jsPaused,
    bool jsEnded = false,
  }) {
    latest?.call(
      position: position,
      newDuration: newDuration,
      jsPaused: jsPaused,
      jsEnded: jsEnded,
    );
  }
}

/// Poll double whose reads never resolve on their own: the test settles them
/// one at a time and chooses the ORDER. That order is exactly what the real
/// loop cannot control — a read that outlives a tick resolves after a later
/// one (issue #655).
class _GatedPollDriver {
  final List<_ResultFn> reads = [];
  final List<Completer<void>> _gates = [];

  Future<void> poll({
    required bool disposed,
    required YoutubeJsChannel? channel,
    required _ResultFn onResult,
  }) async {
    reads.add(onResult);
    final gate = Completer<void>();
    _gates.add(gate);
    await gate.future;
  }

  /// Applies DOM [state] through the read issued at index [call] (issue
  /// order) and lets that poll future settle.
  void settle(
    int call, {
    Duration position = Duration.zero,
    Duration? newDuration,
    bool jsPaused = false,
    bool jsEnded = false,
  }) {
    reads[call](
      position: position,
      newDuration: newDuration,
      jsPaused: jsPaused,
      jsEnded: jsEnded,
    );
    _gates[call].complete();
  }
}

void main() {
  group('YoutubeWebViewPollLoop', () {
    late YoutubeSession session;

    setUp(() {
      session = YoutubeSession();
    });

    tearDown(() async {
      await session.closeStreams();
    });

    test('scheduleKick defers start by ~500ms (timer cancellation)', () async {
      var firstPlayingCalls = 0;
      final loop = YoutubeWebViewPollLoop(
        session: session,
        jsChannel: () => null,
        onFirstPlaying: () => firstPlayingCalls++,
      );

      loop.scheduleKick();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(firstPlayingCalls, 0);

      loop.stop();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(firstPlayingCalls, 0);
    });

    test('start() is idempotent: second call does not double the timer', () {
      var firstPlayingCalls = 0;
      final loop = YoutubeWebViewPollLoop(
        session: session,
        jsChannel: () => null,
        onFirstPlaying: () => firstPlayingCalls++,
      );

      loop.start();
      loop.start();
      loop.stop();
      expect(firstPlayingCalls, 0);
    });

    test('stop() is safe to call without start()', () {
      final loop = YoutubeWebViewPollLoop(
        session: session,
        jsChannel: () => null,
        onFirstPlaying: () {},
      );
      loop.stop();
      loop.stop();
    });

    test('scheduleKick then stop cancels the pending kick', () async {
      var firstPlayingCalls = 0;
      final loop = YoutubeWebViewPollLoop(
        session: session,
        jsChannel: () => null,
        onFirstPlaying: () => firstPlayingCalls++,
      );

      loop.scheduleKick();
      loop.stop();
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(firstPlayingCalls, 0);
    });

    test(
      'media end stops polling and surfaces completion (ADR-0044)',
      () async {
        final driver = _FakePollDriver();
        final completedEvents = <void>[];
        final sub = session.completed.listen(completedEvents.add);
        session.emitPlaying(true);

        final loop = YoutubeWebViewPollLoop(
          session: session,
          jsChannel: () => null,
          onFirstPlaying: () {},
          pollFn: driver.poll,
        );

        loop.start();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        driver.emit(
          position: const Duration(seconds: 60),
          jsPaused: true,
          jsEnded: true,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(session.playbackCompleted, isTrue);
        expect(completedEvents, hasLength(1));
        expect(session.playing, isFalse);
        expect(session.buffering, isFalse);
        expect(loop.isRunning, isFalse);

        await sub.cancel();
        loop.stop();
      },
    );

    test('skips the tick while a poll is still in flight', () async {
      final driver = _GatedPollDriver();
      var firstPlayingCalls = 0;
      final loop = YoutubeWebViewPollLoop(
        session: session,
        jsChannel: () => null,
        onFirstPlaying: () => firstPlayingCalls++,
        pollFn: driver.poll,
      );

      loop.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(
        driver.reads,
        hasLength(1),
        reason: 'the overlapping tick must not issue a second read',
      );
      expect(firstPlayingCalls, 0);

      driver.settle(0, position: const Duration(milliseconds: 250));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(session.playing, isTrue);
      expect(firstPlayingCalls, 1);

      loop.stop();
    });

    test('a late read cannot resurrect playing after end-of-media', () async {
      final driver = _GatedPollDriver();
      var completedFired = false;
      var playingTrueAfterCompleted = 0;
      final completedSub = session.completed.listen((_) {
        completedFired = true;
      });
      final playingSub = session.playingStream.listen((v) {
        if (completedFired && v) playingTrueAfterCompleted++;
      });
      session.emitPlaying(true);

      final loop = YoutubeWebViewPollLoop(
        session: session,
        jsChannel: () => null,
        onFirstPlaying: () {},
        pollFn: driver.poll,
      );

      loop.start();
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(
        driver.reads,
        hasLength(1),
        reason:
            'no second read may be issued — a second read is what let a '
            'stale snapshot apply after the end-of-media one',
      );

      driver.settle(
        0,
        position: const Duration(seconds: 60),
        jsPaused: true,
        jsEnded: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(session.playbackCompleted, isTrue);
      expect(session.playing, isFalse);
      expect(playingTrueAfterCompleted, 0);
      expect(loop.isRunning, isFalse);

      await completedSub.cancel();
      await playingSub.cancel();
      loop.stop();
    });

    test('does not start the poll timer when session is disposed', () async {
      var firstPlayingCalls = 0;
      final loop = YoutubeWebViewPollLoop(
        session: session,
        jsChannel: () => null,
        onFirstPlaying: () => firstPlayingCalls++,
      );

      unawaited(session.closeStreams());
      loop.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(firstPlayingCalls, 0);
      loop.stop();
    });

    test('resets pausedPollStreak to 0 on start()', () {
      session.notePauseStreak(5);
      final loop = YoutubeWebViewPollLoop(
        session: session,
        jsChannel: () => null,
        onFirstPlaying: () {},
      );

      loop.start();
      expect(session.pausedPollStreak, 0);
      loop.stop();
    });

    test('confirms pause after streak and keeps polling', () async {
      final driver = _FakePollDriver();
      session.emitPlaying(true);
      session.markExplicitPlayAttempt();

      final loop = YoutubeWebViewPollLoop(
        session: session,
        jsChannel: () => null,
        onFirstPlaying: () {},
        pollFn: driver.poll,
      );

      loop.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(driver.latest, isNotNull);

      for (var i = 0; i < YoutubeSession.pauseConfirmPollTicks; i++) {
        driver.emit(position: Duration(milliseconds: i * 10), jsPaused: true);
      }

      expect(session.playing, isFalse);
      expect(session.buffering, isFalse);
      expect(loop.isRunning, isTrue);

      loop.stop();
    });

    test('PollPlaying clears buffering and reports first playing', () async {
      final driver = _FakePollDriver();
      var firstPlaying = 0;
      session.emitBuffering(true);

      final loop = YoutubeWebViewPollLoop(
        session: session,
        jsChannel: () => null,
        onFirstPlaying: () => firstPlaying++,
        pollFn: driver.poll,
      );

      loop.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      driver.emit(position: const Duration(milliseconds: 250), jsPaused: false);

      expect(session.playing, isTrue);
      expect(session.buffering, isFalse);
      expect(firstPlaying, 1);

      loop.stop();
    });

    test('forwards progress while playing for volume restore', () async {
      final driver = _FakePollDriver();
      final progress = <Duration>[];

      final loop = YoutubeWebViewPollLoop(
        session: session,
        jsChannel: () => null,
        onFirstPlaying: () {},
        onPlaybackProgress: progress.add,
        pollFn: driver.poll,
      );

      loop.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      driver.emit(position: const Duration(milliseconds: 100), jsPaused: false);
      driver.emit(position: const Duration(milliseconds: 200), jsPaused: true);

      expect(progress, [const Duration(milliseconds: 100)]);

      loop.stop();
    });

    test(
      'play → playing → page pauses again: retries once (production order)',
      () async {
        final driver = _FakePollDriver();
        var retryCalls = 0;
        session.beginUserPlay();
        session.notePlayingConfirmed();

        final loop = YoutubeWebViewPollLoop(
          session: session,
          jsChannel: () => null,
          onFirstPlaying: () {},
          pollFn: driver.poll,
          retryPlay: (_) async => retryCalls++,
        );

        loop.start();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        for (var i = 0; i < YoutubeSession.pauseConfirmPollTicks; i++) {
          driver.emit(position: Duration(milliseconds: i * 10), jsPaused: true);
        }

        expect(retryCalls, 1);
        expect(session.userPlayInFlight, isFalse);
        expect(session.playing, isFalse);

        loop.stop();
      },
    );

    test(
      'deliberate user pause within the immediate window is not retried',
      () async {
        final driver = _FakePollDriver();
        var retryCalls = 0;
        session.beginUserPlay();
        session.notePlayingConfirmed();
        session.noteUserPauseCommand();

        final loop = YoutubeWebViewPollLoop(
          session: session,
          jsChannel: () => null,
          onFirstPlaying: () {},
          pollFn: driver.poll,
          retryPlay: (_) async => retryCalls++,
        );

        loop.start();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        for (var i = 0; i < YoutubeSession.pauseConfirmPollTicks; i++) {
          driver.emit(position: Duration(milliseconds: i * 10), jsPaused: true);
        }

        expect(retryCalls, 0);
        expect(session.playing, isFalse);

        loop.stop();
      },
    );

    test('second immediate pause is not retried (one-shot budget)', () async {
      final driver = _FakePollDriver();
      var retryCalls = 0;
      session.beginUserPlay();
      session.notePlayingConfirmed();

      final loop = YoutubeWebViewPollLoop(
        session: session,
        jsChannel: () => null,
        onFirstPlaying: () {},
        pollFn: driver.poll,
        retryPlay: (_) async => retryCalls++,
      );

      loop.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      for (var round = 0; round < 2; round++) {
        for (var i = 0; i < YoutubeSession.pauseConfirmPollTicks; i++) {
          driver.emit(
            position: Duration(milliseconds: round * 100 + i * 10),
            jsPaused: true,
          );
        }
      }

      expect(retryCalls, 1);
      expect(session.playing, isFalse);

      loop.stop();
    });

    test(
      'echo wedge: escalation retries the retried episode, capped',
      () async {
        final driver = _FakePollDriver();
        var retryCalls = 0;
        session.beginUserPlay();
        session.notePlayingConfirmed();

        final loop = YoutubeWebViewPollLoop(
          session: session,
          jsChannel: () => null,
          onFirstPlaying: () {},
          pollFn: driver.poll,
          retryPlay: (_) async => retryCalls++,
        );

        loop.start();
        await Future<void>.delayed(const Duration(milliseconds: 300));

        void confirmPause() {
          for (var i = 0; i < YoutubeSession.pauseConfirmPollTicks; i++) {
            driver.emit(
              position: Duration(milliseconds: i * 10),
              jsPaused: true,
            );
          }
        }

        confirmPause();
        expect(retryCalls, 1);
        session.notePlayingConfirmed();
        driver.emit(
          position: const Duration(milliseconds: 400),
          jsPaused: false,
        );
        session.notePlayingConfirmed();
        confirmPause();
        expect(retryCalls, 2);
        session.notePlayingConfirmed();
        confirmPause();
        expect(retryCalls, 2);

        loop.stop();
      },
    );

    test('deliberate pause command stops the escalation chain', () async {
      final driver = _FakePollDriver();
      var retryCalls = 0;
      session.beginUserPlay();
      session.notePlayingConfirmed();

      final loop = YoutubeWebViewPollLoop(
        session: session,
        jsChannel: () => null,
        onFirstPlaying: () {},
        pollFn: driver.poll,
        retryPlay: (_) async => retryCalls++,
      );

      loop.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      for (var i = 0; i < YoutubeSession.pauseConfirmPollTicks; i++) {
        driver.emit(position: Duration(milliseconds: i * 10), jsPaused: true);
      }
      expect(retryCalls, 1);
      session.notePlayingConfirmed();
      session.noteUserPauseCommand();

      for (var i = 0; i < YoutubeSession.pauseConfirmPollTicks; i++) {
        driver.emit(position: Duration(milliseconds: i * 10), jsPaused: true);
      }
      expect(retryCalls, 1);

      loop.stop();
    });

    test(
      'failed retry surfaces a warning instead of an unhandled rejection',
      () async {
        final driver = _FakePollDriver();
        session.beginUserPlay();
        session.notePlayingConfirmed();

        final loop = YoutubeWebViewPollLoop(
          session: session,
          jsChannel: () => null,
          onFirstPlaying: () {},
          pollFn: driver.poll,
          retryPlay: (_) async => throw StateError('renderer gone'),
        );

        loop.start();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        for (var i = 0; i < YoutubeSession.pauseConfirmPollTicks; i++) {
          driver.emit(position: Duration(milliseconds: i * 10), jsPaused: true);
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(session.playing, isFalse);
        expect(session.playRetry.autoRetriesIssued, 1);

        loop.stop();
      },
    );

    test('budget expires once playback outlives the attempt window', () async {
      final clock = FakeMonotonicClock();
      final fastSession = YoutubeSession(
        playRetry: YouTubePlayRetryPolicy(
          clock: clock,
          playAttemptExpiry: const Duration(milliseconds: 200),
        ),
      )..resetForOpen('abc12345678');
      addTearDown(fastSession.closeStreams);
      final driver = _FakePollDriver();
      var retryCalls = 0;
      fastSession.beginUserPlay();
      fastSession.notePlayingConfirmed();

      final loop = YoutubeWebViewPollLoop(
        session: fastSession,
        jsChannel: () => null,
        onFirstPlaying: () {},
        pollFn: driver.poll,
        retryPlay: (_) async => retryCalls++,
      );

      loop.start();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      clock.advance(const Duration(milliseconds: 400));
      expect(fastSession.userPlayInFlight, isFalse);

      fastSession.emitPlaying(false);
      fastSession.notePlayingConfirmed();
      for (var i = 0; i < YoutubeSession.pauseConfirmPollTicks; i++) {
        driver.emit(position: Duration(milliseconds: i * 10), jsPaused: true);
      }
      expect(retryCalls, 0);

      loop.stop();
    });

    test(
      'immediate pause without in-flight user play does not retry',
      () async {
        final driver = _FakePollDriver();
        var retryCalls = 0;
        session.emitPlaying(true);

        final loop = YoutubeWebViewPollLoop(
          session: session,
          jsChannel: () => null,
          onFirstPlaying: () {},
          pollFn: driver.poll,
          retryPlay: (_) async => retryCalls++,
        );

        loop.start();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        for (var i = 0; i < YoutubeSession.pauseConfirmPollTicks; i++) {
          driver.emit(position: Duration(milliseconds: i * 10), jsPaused: true);
        }

        expect(retryCalls, 0);

        loop.stop();
      },
    );

    group('cadence (issue #662)', () {
      YoutubeWebViewPollLoop buildLoop(_FakePollDriver driver) {
        return YoutubeWebViewPollLoop(
          session: session,
          jsChannel: () => null,
          onFirstPlaying: session.markFirstPlayingLogged,
          pollFn: driver.poll,
        );
      }

      /// Advances fake time [window] in 50 ms steps and returns how many poll
      /// reads the loop issued. 50 ms < pollTick, so the step size can never
      /// skip a tick, and every cadence used here is a multiple of the step.
      Future<int> readsOver(
        WidgetTester tester,
        _FakePollDriver driver,
        Duration window,
      ) async {
        final start = driver.calls;
        var elapsed = Duration.zero;
        while (elapsed < window) {
          await tester.pump(const Duration(milliseconds: 50));
          await tester.idle();
          elapsed += const Duration(milliseconds: 50);
        }
        return driver.calls - start;
      }

      testWidgets('playing is sampled every pollTick', (tester) async {
        final driver = _FakePollDriver();
        final loop = buildLoop(driver);
        session.emitPlaying(true);

        loop.start();
        for (var i = 1; i <= 4; i++) {
          await tester.pump(loop.pollTick);
          await tester.idle();
          driver.emit(
            position: Duration(milliseconds: 250 * i),
            jsPaused: false,
          );
        }

        expect(driver.calls, 4, reason: 'one read per 250 ms while playing');
        expect(session.loggedFirstPlaying, isTrue);

        loop.stop();
      });

      testWidgets('a document that never played is NOT backed off', (
        tester,
      ) async {
        final driver = _FakePollDriver();
        final loop = buildLoop(driver);

        loop.start();
        final reads = await readsOver(
          tester,
          driver,
          const Duration(seconds: 2),
        );
        driver.emit(position: Duration.zero, jsPaused: true);

        expect(reads, 8, reason: '250 ms cadence before any confirmed pause');
        expect(session.playing, isFalse);
        expect(session.loggedFirstPlaying, isFalse);

        loop.stop();
      });

      testWidgets(
        'a confirmed quiet pause backs off to ~1/s; a play intent restores '
        'the fast cadence immediately',
        (tester) async {
          final driver = _FakePollDriver();
          final loop = buildLoop(driver);
          const position = Duration(seconds: 30);
          session.emitPlaying(true);

          loop.start();
          for (var i = 1; i <= 4; i++) {
            await tester.pump(loop.pollTick);
            await tester.idle();
            driver.emit(
              position: Duration(milliseconds: 250 * i),
              jsPaused: false,
            );
          }
          for (var i = 0; i < YoutubeSession.pauseConfirmPollTicks; i++) {
            await tester.pump(loop.pollTick);
            await tester.idle();
            driver.emit(position: position, jsPaused: true);
          }
          expect(session.playing, isFalse);

          await tester.pump(loop.pollTick);
          await tester.idle();

          expect(
            await readsOver(tester, driver, const Duration(seconds: 2)),
            2,
            reason: 'a confirmed quiet pause is sampled about once a second',
          );
          expect(
            await readsOver(tester, driver, const Duration(seconds: 2)),
            2,
            reason: 'the backoff holds while nothing changes',
          );

          loop.start();
          expect(
            await readsOver(tester, driver, loop.pollTick),
            1,
            reason: 'start() re-arms at pollTick',
          );
          expect(
            await readsOver(tester, driver, const Duration(seconds: 1)),
            4,
            reason: 'the fast cadence is back',
          );

          loop.stop();
        },
      );

      testWidgets(
        'a seek while paused un-quiets the loop, then it re-settles',
        (tester) async {
          final driver = _FakePollDriver();
          final loop = buildLoop(driver);
          session.emitPlaying(true);

          loop.start();
          for (var i = 1; i <= 2; i++) {
            await tester.pump(loop.pollTick);
            await tester.idle();
            driver.emit(
              position: Duration(milliseconds: 250 * i),
              jsPaused: false,
            );
          }
          for (var i = 0; i < YoutubeSession.pauseConfirmPollTicks; i++) {
            await tester.pump(loop.pollTick);
            await tester.idle();
            driver.emit(position: const Duration(seconds: 30), jsPaused: true);
          }
          await tester.pump(loop.pollTick);
          await tester.idle();
          expect(
            await readsOver(tester, driver, const Duration(seconds: 1)),
            1,
            reason: 'precondition: backed off',
          );

          driver.emit(position: const Duration(seconds: 45), jsPaused: true);
          expect(
            await readsOver(tester, driver, loop.pausedPollBackoff),
            1,
            reason: 'the arming predates the moved position',
          );
          expect(
            await readsOver(tester, driver, loop.pollTick),
            1,
            reason: 'a moving position is live state — pollTick cadence',
          );

          driver.emit(position: const Duration(seconds: 45), jsPaused: true);
          expect(
            await readsOver(tester, driver, const Duration(seconds: 1)),
            1,
            reason: 'the backoff resumes once the position is quiet',
          );

          loop.stop();
        },
      );
    });
  });
}
