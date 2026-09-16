/// Regression walls for the five invariants that must hold as
/// [YoutubeSession] becomes the single owner of Dart↔DOM playback truth
/// (issue #721). These tests pin the surface so subsequent refactors in this
/// area cannot silently regress the play-then-pause saga.
///
/// Coverage origins:
/// 1. One-shot completer/waiter semantics — `noteWebViewMounted` /
///    `noteWebViewUnmounted` / `closeStreams` interleave with awaits
///    (issue #661 push-vs-poll, issue #668 dispose ordering).
/// 2. Document-generation invariants — `_documentGen` /
///    `_volumeRestoredDocGen` keep the unmute-at-most-once-per-document
///    rule intact under reload + reset (issue #628).
/// 3. Episode-keyed budget retirement — `emitPlaying` →
///    [YouTubePlayRetryPolicy.notePlayingTransition] keeps the D8 budget
///    armed through the first playing and retires it only after the
///    expiry keyed to THAT episode (issue #665).
/// 4. D9 direction latch — [YouTubePlayRetryPolicy.classifyTransportToggle]
///    classifies from the DOM direction the atomic toggle script
///    returned, never from session `playing` (issue #665 / D9).
/// 5. Open-vs-warm invariant — [PlayerController] keeps the warm
///    [YoutubePlayerEngine] alive across a stale-open-in-flight
///    [abandonPendingOpen], because a speculative warm must not be
///    disposable by a later guard check (issue #657, follow-up to #720).
library;

import 'dart:async';

import 'package:enjoy_player/features/player/application/engines/youtube/youtube_monotonic_clock.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_play_retry_policy.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('1. one-shot completer/waiter semantics', () {
    // The mount waiters are push-from-the-event, not flag poll (issue
    // #661). Their semantics are load-bearing: a stale waiter left
    // dangling must not double-complete a fresh mount, and the
    // unmounted detector must arm BEFORE the unmount signal so a
    // microtask race between the controller and the host does not
    // collapse to a synchronous no-op.
    test('dispose-then-verb sequences are silent no-ops', () async {
      final session = YoutubeSession();
      await session.closeStreams();

      // Late verbs do not throw, do not emit, do not flip latches.
      var playingEvents = 0;
      var completedEvents = 0;
      final playingSub = session.playingStream.listen((_) => playingEvents++);
      final completedSub = session.completed.listen((_) => completedEvents++);
      addTearDown(() async {
        await playingSub.cancel();
        await completedSub.cancel();
      });

      session
        ..noteWebViewMounted()
        ..noteWebViewUnmounted()
        ..requestMount()
        ..bumpMountTick()
        ..scheduleMountTickBump()
        ..notePlayingConfirmed()
        ..notePauseConfirmed()
        ..noteEnded()
        ..noteUserPlayUnresolved()
        ..markCompleted()
        ..beginUserPlay()
        ..clearUserPlayInFlight()
        ..setPendingSeekSeconds(1.5);

      await Future<void>.delayed(Duration.zero);
      expect(playingEvents, 0);
      expect(completedEvents, 0);
      // Private flags stay where closeStreams put them.
      expect(session.disposed, isTrue);
      expect(session.webViewMounted, isFalse);
    });

    test(
      'awaitSurfaceDetached armed both before and after the unmount resolves',
      () async {
        final session = YoutubeSession()
          ..resetForOpen('abc12345678')
          ..noteWebViewMounted();

        // Arm the waiter BEFORE the unmount signal — the controller path.
        final pendingBefore = session.awaitSurfaceDetached();
        var beforeResolved = false;
        unawaited(pendingBefore.then((_) => beforeResolved = true));

        session.noteWebViewUnmounted();
        await pendingBefore;
        expect(beforeResolved, isTrue);

        // Arm AGAIN after the unmount — must resolve immediately
        // (nothing is mounted to detach).
        await session.awaitSurfaceDetached();
      },
    );

    test('double-mount with a stale waiter does not double-complete', () async {
      final session = YoutubeSession();

      // First mount cycle — arms a waiter, completes it, drops it.
      final firstWaiter = session.awaitWebViewMounted();
      var firstCompletions = 0;
      unawaited(firstWaiter.then((_) => firstCompletions++));

      session.noteWebViewMounted();
      session.noteWebViewMounted(); // second note — must not re-fire.
      await firstWaiter;
      expect(firstCompletions, 1);

      session.noteWebViewUnmounted();

      // Second mount cycle — a fresh waiter must not have been
      // poisoned by the first (already-completed) one.
      final secondWaiter = session.awaitWebViewMounted();
      var secondCompletions = 0;
      unawaited(secondWaiter.then((_) => secondCompletions++));
      await pumpEventQueue();
      expect(secondCompletions, 0, reason: 'the fresh waiter is still pending');

      session.noteWebViewMounted();
      await secondWaiter;
      expect(secondCompletions, 1);
    });
  });

  group('2. document-generation invariants', () {
    // The unmute-at-most-once-per-document rule is the play-then-pause
    // bug's defence (issue #628). Redundant programmatic unMutes are
    // pause triggers under Chromium's autoplay gesture lock, so the
    // pin must hold across document reloads and open/clear cycles.
    test('two noteWatchDocumentLoaded without noteVolumeRestored keeps '
        'needsVolumeRestore true', () {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      // After open the very first document needs restore.
      expect(session.needsVolumeRestore, isTrue);
      final firstGen = session.documentGen;

      session.noteWatchDocumentLoaded(); // ad-reload
      expect(session.documentGen, firstGen + 1);
      expect(session.needsVolumeRestore, isTrue);

      session.noteWatchDocumentLoaded(); // second reload
      expect(session.documentGen, firstGen + 2);
      expect(
        session.needsVolumeRestore,
        isTrue,
        reason:
            'unmute-at-most-once-per-document must remain unsatisfied '
            'without noteVolumeRestored — the guard is what keeps '
            'redundant unMutes from triggering the gesture lock',
      );
    });

    test('progressConfirmTicks is 2 — the volume-restore progress gate', () {
      // Pinned because [audible_policy_test] asserts against it; a
      // change here must move the test, not silently diverge.
      expect(YoutubeSession.progressConfirmTicks, 2);
    });

    test(
      'noteProgressForVolumeRestore re-bases the baseline on each advance',
      () {
        // A second confirmation only succeeds if BOTH samples are above
        // the previous baseline — the re-baseline prevents an oscillating
        // position from satisfying the gate by accident.
        final session = YoutubeSession()..resetForOpen('abc12345678');
        session.armVolumeRestorePending(baseline: Duration.zero);

        expect(
          session.noteProgressForVolumeRestore(
            const Duration(milliseconds: 50),
          ),
          isFalse,
        );
        expect(
          session.noteProgressForVolumeRestore(Duration.zero),
          isFalse,
          reason: 'equal to the new baseline — not an advance',
        );
        expect(
          session.noteProgressForVolumeRestore(
            const Duration(milliseconds: 100),
          ),
          isTrue,
          reason: 'two consecutive advances past the rebased baseline',
        );
      },
    );
  });

  group('3. episode-keyed budget retirement', () {
    // The D8 budget spans the WHOLE attempt: armed through the first
    // playing, retired only after the expiry window keyed to THAT
    // episode (issue #665). A page-UI resume the app never commanded
    // must not refresh the clock — only an episode that RESOLVED the
    // arming command starts the timer.
    test('budget armed through first playing, retires only after expiry '
        'keyed to THAT episode', () {
      final clock = FakeMonotonicClock();
      final session = YoutubeSession(
        playRetry: YouTubePlayRetryPolicy(
          clock: clock,
          playAttemptExpiry: const Duration(milliseconds: 500),
        ),
      )..resetForOpen('abc12345678');
      addTearDown(session.closeStreams);

      session.beginUserPlay();
      // Armed before playing — the page's post-playing correction
      // is exactly what D8 exists for.
      expect(session.userPlayInFlight, isTrue);

      session.emitPlaying(true);
      expect(
        session.userPlayInFlight,
        isTrue,
        reason:
            'arming survives the first playing — the latch is keyed '
            'to the resolving episode, not consumed by it',
      );

      // Half-window — still inside the episode.
      clock.advance(const Duration(milliseconds: 250));
      expect(session.userPlayInFlight, isTrue);

      // Past the window — armed but unfulfilled attempt retires.
      clock.advance(const Duration(milliseconds: 300));
      expect(
        session.userPlayInFlight,
        isFalse,
        reason:
            'a budget armed minutes ago must not be spendable by a '
            'pause after a page-UI resume the app never commanded',
      );
    });

    test('a later page-UI resume does not refresh the fulfilment clock', () {
      // The episode that resolved the arming command owns the budget's
      // lifetime. A later playing transition with no beginUserPlay in
      // between is a page-UI resume — the budget must stay retired.
      final clock = FakeMonotonicClock();
      final session = YoutubeSession(
        playRetry: YouTubePlayRetryPolicy(
          clock: clock,
          playAttemptExpiry: const Duration(milliseconds: 200),
        ),
      )..resetForOpen('abc12345678');
      addTearDown(session.closeStreams);

      session
        ..beginUserPlay()
        ..emitPlaying(true);
      clock.advance(const Duration(milliseconds: 200));
      expect(session.userPlayInFlight, isFalse);

      // Page-UI resume inside the immediate window — but no new arming.
      session.emitPlaying(false);
      session.emitPlaying(true);
      clock.advance(const Duration(milliseconds: 100));
      expect(
        session.userPlayInFlight,
        isFalse,
        reason:
            'a fresh playing transition without beginUserPlay is a '
            'page-UI resume and must not refresh the stale clock',
      );
    });
  });

  group('4. D9 direction latch', () {
    // The transport toggle classifies from the DOM direction the
    // atomic script returned, never from session `playing`. Session
    // `playing` lags DOM pauses by ~750 ms (pause confirmation
    // window), so classifying from it arms/consumes opposite to the
    // command really issued in exactly the windows that matter (D9).
    test('play direction arms the retry budget', () {
      final decision = YouTubePlayRetryPolicy().classifyTransportToggle(
        domDirection: 'play',
      );
      expect(decision, isA<ArmRetryBudget>());
    });

    test('pause direction consumes the retry budget', () {
      final decision = YouTubePlayRetryPolicy().classifyTransportToggle(
        domDirection: 'pause',
      );
      expect(decision, isA<ConsumeRetryBudget>());
    });

    test('no video element leaves the budget untouched — the attempt '
        'expiry bounds any stale arming', () {
      final decision = YouTubePlayRetryPolicy().classifyTransportToggle(
        domDirection: null,
      );
      expect(
        decision,
        isA<LeaveRetryBudget>(),
        reason:
            'a missing <video> means nothing was issued; the latch '
            'stays where it was so a fresh user play does not lose '
            'coverage to a no-op toggle',
      );
    });

    test('an unknown DOM direction leaves the latch untouched', () {
      final decision = YouTubePlayRetryPolicy().classifyTransportToggle(
        domDirection: 'something_else',
      );
      expect(decision, isA<LeaveRetryBudget>());
    });

    test('mirror race: a stale session.playing opposite to the DOM '
        'direction does not leak into the classification', () {
      // The engine classifies against session.playing in a comment
      // (issue #665 / youtube_player_engine.dart:246-263); if the
      // classifier ever reads that flag the latch flips opposite to
      // the command and either spends the budget on a deliberate
      // pause or arms one against a confirmed pause. The
      // classification API takes only domDirection — there is no
      // session.playing path.
      final policy = YouTubePlayRetryPolicy();

      // session.playing=true, DOM paused → must arm nothing.
      expect(
        policy.classifyTransportToggle(domDirection: 'pause'),
        isA<ConsumeRetryBudget>(),
        reason:
            'the latch must consume even when Dart believes playing — '
            'the consume path is what stops a stale-true from '
            'arming a budget against a confirmed pause',
      );
      expect(
        policy.classifyTransportToggle(domDirection: 'play'),
        isA<ArmRetryBudget>(),
        reason:
            'and the arm path must not depend on session state either — '
            'arming from stale-false would un-pause a confirmed pause',
      );
    });
  });
}
