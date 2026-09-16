import 'package:enjoy_player/features/player/domain/player_settings.dart';
import 'package:enjoy_player/features/player/domain/transport_decisions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // D1 — decideSeekRouting
  // ---------------------------------------------------------------------------
  group('decideSeekRouting', () {
    test('routes through echo when active', () {
      expect(decideSeekRouting(echoActive: true), isTrue);
    });

    test('routes directly when echo inactive', () {
      expect(decideSeekRouting(echoActive: false), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // D3 — decideReplayTarget
  // ---------------------------------------------------------------------------
  group('decideReplayTarget', () {
    test('returns echo start when echo active', () {
      final d = decideReplayTarget(
        echoActive: true,
        echoStartTimeSeconds: 5.0,
        activeLineStartSeconds: 10.0,
      );
      expect(d, isA<ReplayToEchoStart>());
      expect((d as ReplayToEchoStart).timeSeconds, 5.0);
    });

    test('returns line start when echo inactive', () {
      final d = decideReplayTarget(
        echoActive: false,
        echoStartTimeSeconds: 5.0,
        activeLineStartSeconds: 10.0,
      );
      expect(d, isA<ReplayToLineStart>());
      expect((d as ReplayToLineStart).timeSeconds, 10.0);
    });
  });

  // ---------------------------------------------------------------------------
  // D4 — decideProgressSeekTime
  // ---------------------------------------------------------------------------
  group('decideProgressSeekTime', () {
    test('invalid when duration is zero', () {
      expect(decideProgressSeekTime(fraction: 0.5, durationSeconds: 0), isNull);
    });

    test('invalid when duration is negative', () {
      expect(
        decideProgressSeekTime(fraction: 0.5, durationSeconds: -1),
        isNull,
      );
    });

    test('seeks to middle', () {
      expect(decideProgressSeekTime(fraction: 0.5, durationSeconds: 100), 50);
    });

    test('clamps fraction below zero', () {
      expect(decideProgressSeekTime(fraction: -0.5, durationSeconds: 100), 0);
    });

    test('clamps fraction above one', () {
      expect(decideProgressSeekTime(fraction: 1.5, durationSeconds: 100), 100);
    });

    test('target is clamped to duration', () {
      expect(decideProgressSeekTime(fraction: 1.0, durationSeconds: 100), 100);
    });
  });

  // ---------------------------------------------------------------------------
  // D5 — decideYouTubePlayRestart
  // ---------------------------------------------------------------------------
  group('decideYouTubePlayRestart', () {
    test('restarts when playback completed', () {
      expect(decideYouTubePlayRestart(playbackCompleted: true), isTrue);
    });

    test('resumes when playback not completed', () {
      expect(decideYouTubePlayRestart(playbackCompleted: false), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // D6 — decidePollTransition
  // ---------------------------------------------------------------------------
  group('decidePollTransition', () {
    final playing = true;
    final notPlaying = false;
    final jsEnded = true;
    final jsNotEnded = false;
    final jsPaused = true;
    final jsNotPaused = false;
    const threshold = 3;

    test('media ended', () {
      final d = decidePollTransition(
        jsEnded: jsEnded,
        jsPaused: jsNotPaused,
        playing: playing,
        pausedPollStreak: 0,
        pauseConfirmThreshold: threshold,
        playbackCompleted: false,
      );
      expect(d, isA<MediaJustEnded>());
    });

    test('media ended when already marked completed is idle', () {
      final d = decidePollTransition(
        jsEnded: jsEnded,
        jsPaused: jsNotPaused,
        playing: notPlaying,
        pausedPollStreak: 0,
        pauseConfirmThreshold: threshold,
        playbackCompleted: true,
      );
      expect(d, isA<PollIdleTick>());
    });

    test('pause streaking — not yet confirmed', () {
      final d = decidePollTransition(
        jsEnded: jsNotEnded,
        jsPaused: jsPaused,
        playing: playing,
        pausedPollStreak: 0,
        pauseConfirmThreshold: threshold,
        playbackCompleted: false,
      );
      expect(d, isA<PauseStreaking>());
      final p = d as PauseStreaking;
      expect(p.confirmed, false);
      expect(p.newStreak, 1);
    });

    test('pause streaking — confirmed', () {
      final d = decidePollTransition(
        jsEnded: jsNotEnded,
        jsPaused: jsPaused,
        playing: playing,
        pausedPollStreak: threshold - 1,
        pauseConfirmThreshold: threshold,
        playbackCompleted: false,
      );
      expect(d, isA<PauseStreaking>());
      final p = d as PauseStreaking;
      expect(p.confirmed, true);
      expect(p.newStreak, threshold);
    });

    test('returns PollPlaying when JS says playing and not ended', () {
      final d = decidePollTransition(
        jsEnded: jsNotEnded,
        jsPaused: jsNotPaused,
        playing: playing,
        pausedPollStreak: 0,
        pauseConfirmThreshold: threshold,
        playbackCompleted: false,
      );
      expect(d, isA<PollPlaying>());
    });

    test('pause streaking ignored when not client-playing', () {
      final d = decidePollTransition(
        jsEnded: jsNotEnded,
        jsPaused: jsPaused,
        playing: notPlaying,
        pausedPollStreak: 0,
        pauseConfirmThreshold: threshold,
        playbackCompleted: false,
      );
      expect(d, isA<PollIdleTick>());
    });
  });

  // ---------------------------------------------------------------------------
  // D7 — decideOnMediaEnd
  // ---------------------------------------------------------------------------
  group('decideOnMediaEnd', () {
    test('RepeatMode.none stops', () {
      final d = decideOnMediaEnd(repeatMode: RepeatMode.none);
      expect(d, isA<StopAtEnd>());
    });

    test('RepeatMode.single loops', () {
      final d = decideOnMediaEnd(repeatMode: RepeatMode.single);
      expect(d, isA<LoopMedia>());
    });

    test('RepeatMode.segment does segment loop', () {
      final d = decideOnMediaEnd(repeatMode: RepeatMode.segment);
      expect(d, isA<LoopSegment>());
    });
  });

  // D8 (immediate-pause retry) and D9 (transport-toggle latch) moved to
  // youtube_play_retry_policy_test.dart with the protocol they decide about
  // (issue #665).

  // ---------------------------------------------------------------------------
  // D10 — decidePlaybackRateStep (player.slowDown / player.speedUp)
  // ---------------------------------------------------------------------------
  group('decidePlaybackRateStep', () {
    test('slower steps down by 0.05 inside the range', () {
      final d = decidePlaybackRateStep(
        rate: 1.0,
        direction: PlaybackRateDirection.slower,
      );
      expect(d, isA<ValidRateStep>());
      expect(d.rate, 0.95);
    });

    test('faster steps up by 0.05 inside the range', () {
      final d = decidePlaybackRateStep(
        rate: 1.0,
        direction: PlaybackRateDirection.faster,
      );
      expect(d, isA<ValidRateStep>());
      expect(d.rate, 1.05);
    });

    test('slower clamps at the 0.25 floor', () {
      final d = decidePlaybackRateStep(
        rate: 0.25,
        direction: PlaybackRateDirection.slower,
      );
      expect(d, isA<FloorRateStep>());
      expect(d.rate, kPlaybackRateMin);
    });

    test('slower landing exactly on 0.25 is the floor', () {
      final d = decidePlaybackRateStep(
        rate: 0.3,
        direction: PlaybackRateDirection.slower,
      );
      expect(d, isA<FloorRateStep>());
      expect(d.rate, kPlaybackRateMin);
    });

    test('faster clamps at the 2.0 ceiling', () {
      final d = decidePlaybackRateStep(
        rate: 2.0,
        direction: PlaybackRateDirection.faster,
      );
      expect(d, isA<CeilingRateStep>());
      expect(d.rate, kPlaybackRateMax);
    });

    test('faster landing exactly on 2.0 is the ceiling', () {
      final d = decidePlaybackRateStep(
        rate: 1.95,
        direction: PlaybackRateDirection.faster,
      );
      expect(d, isA<CeilingRateStep>());
      expect(d.rate, kPlaybackRateMax);
    });

    test('floor / ceiling still apply the rate (no further movement)', () {
      // The pre-reducer hotkey always called setPlaybackRate with the clamped
      // value; the decision keeps that contract via `rate`.
      final floor = decidePlaybackRateStep(
        rate: 0.26,
        direction: PlaybackRateDirection.slower,
      );
      expect(floor.rate, kPlaybackRateMin);
      final ceiling = decidePlaybackRateStep(
        rate: 1.99,
        direction: PlaybackRateDirection.faster,
      );
      expect(ceiling.rate, kPlaybackRateMax);
    });
  });
}
