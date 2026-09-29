import 'dart:async';

import 'package:enjoy_player/features/player/application/engines/youtube/youtube_audible_playback_policy.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_session.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_events.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_video_stage.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YoutubePlayerEngine contract surface', () {
    test('open sets the video id and arms buffering transport', () async {
      final engine = YoutubePlayerEngine();
      await engine.open(const YoutubePlayableSource('abc12345678'));
      expect(engine.currentVideoId, 'abc12345678');
      expect(engine.transportSnapshot.buffering, isTrue);
      await engine.dispose();
    });

    test('teardownAfterClear idles the engine', () async {
      final engine = YoutubePlayerEngine();
      await engine.open(const YoutubePlayableSource('abc12345678'));

      await engine.teardownAfterClear(keepSurfaceMounted: false);

      expect(engine.currentVideoId, isEmpty);
      expect(engine.transportSnapshot.playing, isFalse);
      expect(engine.transportSnapshot.buffering, isFalse);
      await engine.dispose();
    });

    test('warmVideoSurface does not throw and keeps no video open', () {
      final engine = YoutubePlayerEngine();
      engine.warmVideoSurface();
      expect(engine.currentVideoId, isEmpty);
    });
  });

  group('YoutubeSession mount lifecycle', () {
    test('requestMount arms the mount without duplicate host ticks', () {
      final session = YoutubeSession();
      expect(session.shouldMountWebView, isFalse);
      expect(session.webViewMounted, isFalse);

      session.requestMount();
      final tickAfterFirst = session.mountTick.value;
      session.requestMount();
      session.requestMount();

      expect(session.shouldMountWebView, isTrue);
      expect(session.mountTick.value, tickAfterFirst);
      expect(session.webViewMounted, isFalse);
    });

    test('awaitSurfaceDetached completes when the WebView unmounts', () async {
      final session = YoutubeSession();
      session.noteWebViewMounted();
      final pending = session.awaitSurfaceDetached();
      var completed = false;
      unawaited(pending.then((_) => completed = true));
      await pumpEventQueue();
      expect(completed, isFalse);

      session.noteWebViewUnmounted();
      await pending;
      expect(completed, isTrue);
    });

    test('awaitSurfaceDetached is a no-op when already unmounted', () async {
      final session = YoutubeSession();
      await session.awaitSurfaceDetached();
    });

    test('resetForClear unmounts unless asked to keep the host', () {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      session.requestMount();

      session.resetForClear();
      expect(session.shouldMountWebView, isFalse);
      expect(session.videoId, isEmpty);

      session.resetForOpen('abc12345678');
      session.requestMount();
      session.resetForClear(keepMounted: true);
      expect(session.shouldMountWebView, isTrue);
      expect(session.videoId, isEmpty);
    });

    test('awaitWebViewMounted resolves immediately when already mounted', () {
      final session = YoutubeSession()..noteWebViewMounted();
      expect(session.awaitWebViewMounted(), completes);
    });

    test('awaitWebViewMounted resolves on the mount signal', () async {
      final session = YoutubeSession();
      final waiter = session.awaitWebViewMounted();
      var completed = false;
      unawaited(waiter.then((_) => completed = true));
      await pumpEventQueue();
      expect(completed, isFalse, reason: 'still waiting for the mount');

      session.noteWebViewMounted();
      await pumpEventQueue();
      expect(completed, isTrue);
      expect(session.webViewMounted, isTrue);
    });

    test(
      'a second mount note is a no-op, and a remount arms a new waiter',
      () async {
        final session = YoutubeSession();
        final first = session.awaitWebViewMounted();

        session.noteWebViewMounted();
        session.noteWebViewMounted();
        await expectLater(first, completes);

        session.noteWebViewUnmounted();
        expect(session.webViewMounted, isFalse);

        final second = session.awaitWebViewMounted();
        var secondCompleted = false;
        unawaited(second.then((_) => secondCompleted = true));
        await pumpEventQueue();
        expect(secondCompleted, isFalse);

        session.noteWebViewMounted();
        await expectLater(second, completes);
      },
    );
  });

  group('YoutubePlayerEngine mount wait (issue #661)', () {
    testWidgets('a mount resolves awaitSurfaceReady with no poll tick', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final session = YoutubeSession();
      final engine = YoutubePlayerEngine(session: session);
      try {
        var resolved = false;
        unawaited(engine.awaitSurfaceReady().then((_) => resolved = true));
        session.noteWebViewMounted();

        await tester.pump(const Duration(milliseconds: 1));
        expect(resolved, isTrue);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
      await engine.dispose();
    });

    testWidgets('a surface that never mounts still resolves via the timeout', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final session = YoutubeSession();
      final engine = YoutubePlayerEngine(session: session);
      try {
        var resolved = false;
        unawaited(engine.awaitSurfaceReady().then((_) => resolved = true));
        await tester.pump();

        await tester.pump(const Duration(seconds: 8, milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 1));
        expect(resolved, isTrue);
        expect(session.webViewMounted, isFalse);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
      await engine.dispose();
    });
  });

  group('YoutubeWebViewEvents playback state', () {
    YoutubeAudiblePlaybackPolicy buildPolicy(
      YoutubeSession session, {
      required Future<void> Function() reapplyVolume,
      Duration? volumeRestoreDelay,
      Duration? volumeRestoreFallback,
      Duration? postRestoreHealDelay,
      Future<void> Function()? healPlay,
    }) {
      return YoutubeAudiblePlaybackPolicy(
        session: session,
        reapplyVolume: reapplyVolume,
        healPlay: healPlay ?? () async {},
        volumeRestoreDelay: volumeRestoreDelay,
        volumeRestoreFallback: volumeRestoreFallback,
        postRestoreHealDelay: postRestoreHealDelay,
      );
    }

    YoutubeWebViewEvents buildEvents(
      YoutubeSession session, {
      required void Function() onFirstPlaying,
      required void Function() startPolling,
      required void Function() stopPolling,
      required Future<void> Function() reapplyVolume,
      Duration? volumeRestoreDelay,
      Duration? volumeRestoreFallback,
      Duration? postRestoreHealDelay,
      Future<void> Function()? healPlay,
    }) {
      final audibility = buildPolicy(
        session,
        reapplyVolume: reapplyVolume,
        volumeRestoreDelay: volumeRestoreDelay,
        volumeRestoreFallback: volumeRestoreFallback,
        postRestoreHealDelay: postRestoreHealDelay,
        healPlay: healPlay,
      );
      return YoutubeWebViewEvents(
        session: session,
        jsChannel: () => null,
        onFirstPlaying: onFirstPlaying,
        startPolling: startPolling,
        stopPolling: stopPolling,
        seekTo: (_) async {},
        audibility: audibility,
      );
    }

    test('does not report playing from the optimistic play event', () async {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      var firstPlayingCalls = 0;
      var pollStartCalls = 0;
      var volumeRestoreCalls = 0;
      final events = buildEvents(
        session,
        onFirstPlaying: () => firstPlayingCalls++,
        startPolling: () => pollStartCalls++,
        stopPolling: () {},
        reapplyVolume: () async {
          volumeRestoreCalls++;
        },
      );

      events.handle(['play']);

      expect(session.playing, isFalse);
      expect(firstPlayingCalls, 0);
      expect(pollStartCalls, 0);
      expect(volumeRestoreCalls, 0);

      events.handle(['playing']);

      expect(session.playing, isTrue);
      expect(firstPlayingCalls, 1);
      expect(pollStartCalls, 1);
      expect(volumeRestoreCalls, 0);
      expect(session.volumeRestorePending, isTrue);

      await session.closeStreams();
    });

    test('play rejection rolls back state and volume restore', () async {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      var volumeRestoreCalls = 0;
      var pollStartCalls = 0;
      final events = buildEvents(
        session,
        onFirstPlaying: () {},
        startPolling: () => pollStartCalls++,
        stopPolling: () {},
        reapplyVolume: () async {
          volumeRestoreCalls++;
        },
        volumeRestoreFallback: const Duration(milliseconds: 80),
      );

      events.handle(['playing']);
      session.emitBuffering(true);
      events.handle(['playRejected', 'NotAllowedError']);
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(session.playing, isFalse);
      expect(session.buffering, isFalse);
      expect(volumeRestoreCalls, 0);
      expect(pollStartCalls, greaterThanOrEqualTo(1));

      await session.closeStreams();
    });

    test(
      'pause cancels pending volume restore without resetting streak',
      () async {
        final session = YoutubeSession()..resetForOpen('abc12345678');
        var volumeRestoreCalls = 0;
        final events = buildEvents(
          session,
          onFirstPlaying: () {},
          startPolling: () {},
          stopPolling: () {},
          reapplyVolume: () async {
            volumeRestoreCalls++;
          },
          volumeRestoreFallback: const Duration(milliseconds: 80),
        );

        events.handle(['playing']);
        session.notePauseStreak(2);
        events.handle(['pause']);

        expect(session.pausedPollStreak, 2);
        expect(session.volumeRestorePending, isFalse);
        await Future<void>.delayed(const Duration(milliseconds: 120));
        expect(volumeRestoreCalls, 0);

        await session.closeStreams();
      },
    );

    test('pause does not clear session.playing (poll confirms)', () async {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      final events = buildEvents(
        session,
        onFirstPlaying: () {},
        startPolling: () {},
        stopPolling: () {},
        reapplyVolume: () async {},
      );

      events.handle(['playing']);
      events.handle(['pause']);
      expect(session.playing, isTrue);

      await session.closeStreams();
    });

    test('error clears playing and buffering', () async {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      final events = buildEvents(
        session,
        onFirstPlaying: () {},
        startPolling: () {},
        stopPolling: () {},
        reapplyVolume: () async {},
      );

      events.handle(['playing']);
      session.emitBuffering(true);
      events.handle(['error']);

      expect(session.playing, isFalse);
      expect(session.buffering, isFalse);

      await session.closeStreams();
    });

    test(
      'playing keeps an in-flight user play armed; playRejected resolves it',
      () async {
        final session = YoutubeSession()..resetForOpen('abc12345678');
        final events = buildEvents(
          session,
          onFirstPlaying: () {},
          startPolling: () {},
          stopPolling: () {},
          reapplyVolume: () async {},
        );

        session.beginUserPlay();
        events.handle(['playing']);
        expect(session.userPlayInFlight, isTrue);

        events.handle(['playRejected', 'NotAllowedError']);
        expect(session.userPlayInFlight, isFalse);

        await session.closeStreams();
      },
    );

    test('resetForOpen and resetForClear reset userPlayInFlight', () {
      final session = YoutubeSession()..resetForOpen('abc12345678');
      session.beginUserPlay();
      session.noteAutoPlayRetry();
      session.resetForOpen('other123456');
      expect(session.userPlayInFlight, isFalse);
      expect(
        session.playRetry.recentAutoRetryWithin(const Duration(minutes: 1)),
        isFalse,
      );

      session.beginUserPlay();
      session.noteAutoPlayRetry();
      session.resetForClear();
      expect(session.userPlayInFlight, isFalse);
      expect(
        session.playRetry.recentAutoRetryWithin(const Duration(minutes: 1)),
        isFalse,
      );
    });
  });

  group('YoutubePlayerEngine video stage poster gating (issue #662)', () {
    Future<void> pumpStage(
      WidgetTester tester,
      YoutubePlayerEngine engine,
    ) async {
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
      await tester.pump(const Duration(milliseconds: 250));
    }

    testWidgets('buffers before first playing onto the poster', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final session = YoutubeSession();
      final engine = YoutubePlayerEngine(session: session);
      try {
        session.resetForOpen('abc12345678');
        engine.setPosterUrl('https://example.com/thumb.jpg');
        await pumpStage(tester, engine);

        expect(find.byType(Image), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
      await engine.dispose();
    });

    testWidgets('a mid-playback stall shows a spinner, never the poster', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final session = YoutubeSession();
      final engine = YoutubePlayerEngine(session: session);
      try {
        session.resetForOpen('abc12345678');
        engine.setPosterUrl('https://example.com/thumb.jpg');
        await pumpStage(tester, engine);
        expect(find.byType(Image), findsOneWidget);

        session.notePlayingConfirmed();
        session.markFirstPlayingLogged();
        session.emitBuffering(false);
        await pumpStage(tester, engine);
        expect(find.byType(Image), findsNothing);

        session.emitBuffering(true);
        await pumpStage(tester, engine);

        expect(find.byType(Image), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
      await engine.dispose();
    });
  });

  group('YoutubeSession volume restore progress', () {
    test('noteProgressForVolumeRestore requires consecutive advances', () {
      final session = YoutubeSession()..resetForOpen('vid');
      session.armVolumeRestorePending(baseline: Duration.zero);
      expect(session.noteProgressForVolumeRestore(Duration.zero), isFalse);
      expect(
        session.noteProgressForVolumeRestore(const Duration(milliseconds: 50)),
        isFalse,
      );
      expect(
        session.noteProgressForVolumeRestore(const Duration(milliseconds: 100)),
        isTrue,
      );
    });

    test(
      'isImmediatePause tracks the playing episode on the protocol clock',
      () {
        final session = YoutubeSession()..resetForOpen('vid');
        expect(session.isImmediatePause(), isFalse);
        session.emitPlaying(true);
        expect(session.isImmediatePause(), isTrue);
      },
    );

    test('emitBuffering false then true then false bumps mountTick once', () {
      final session = YoutubeSession()..resetForOpen('vid');
      final tickAfterOpen = session.mountTick.value;
      session.emitBuffering(false);
      final tickAfterFirstOff = session.mountTick.value;
      expect(tickAfterFirstOff, greaterThan(tickAfterOpen));
      session.emitBuffering(true);
      session.emitBuffering(false);
      expect(session.mountTick.value, tickAfterFirstOff);
    });
  });
}
