// Per-command unit tests for the shadow-reading hotkey bus commands
// (issue #719) — R / G / P / V pulse the shared bus, gated by
// `shadowReadingBusHotkeysEnabled` (player session or vocabulary echo
// practice). Uses a plain [ProviderContainer] with the REAL bus so the
// asserted ticks are the state consumers observe.
import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_commands.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_review_practice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePlayerController extends PlayerController {
  PlaybackSession? sessionOverride;

  @override
  PlaybackSession? build() => sessionOverride;
}

class _FakeVocabularyReviewSession extends VocabularyReviewSession {
  _FakeVocabularyReviewSession({ReviewSessionState? initial})
    : _seed = initial ?? const ReviewSessionState(queue: []);

  final ReviewSessionState _seed;

  @override
  ReviewSessionState build() => _seed;
}

PlaybackSession _videoSession() => PlaybackSession(
  mediaId: 'm1',
  dexieTargetType: 'Video',
  mediaType: 'video',
  mediaTitle: 'Test',
  durationSeconds: 60,
  currentTimeSeconds: 0,
  currentSegmentIndex: 0,
  language: 'en',
  startedAt: DateTime(2026),
  lastActiveAt: DateTime(2026),
);

void main() {
  test('registry maps the four bus pulses in dispatch order', () {
    expect(
      shadowReadingHotkeyCommands.map((c) => c.actionId).toList(),
      [
        'player.toggleRecording',
        'player.playRecording',
        'player.togglePitchContour',
        'player.toggleAssessment',
      ],
    );
  });

  ({ProviderContainer container}) harness({
    PlaybackSession? session,
    ReviewSessionState? vocabState,
  }) {
    final container = ProviderContainer(
      overrides: [
        playerControllerProvider.overrideWith(
          () => _FakePlayerController()..sessionOverride = session,
        ),
        vocabularyReviewSessionProvider.overrideWith(
          () => _FakeVocabularyReviewSession(initial: vocabState),
        ),
      ],
    );
    addTearDown(container.dispose);
    return (container: container);
  }

  HotkeyCommand commandFor(String actionId) =>
      shadowReadingHotkeyCommands.where((c) => c.actionId == actionId).first;

  group('with an active player session', () {
    test('toggleRecording pulses recording', () {
      final h = harness(session: _videoSession());
      commandFor('player.toggleRecording').execute(
        HotkeyCtx(read: h.container.read, listenerContext: null),
      );
      expect(
        h.container.read(shadowReadingHotkeyBusProvider).recording,
        1,
      );
    });

    test('playRecording pulses playback', () {
      final h = harness(session: _videoSession());
      commandFor('player.playRecording').execute(
        HotkeyCtx(read: h.container.read, listenerContext: null),
      );
      expect(
        h.container.read(shadowReadingHotkeyBusProvider).playback,
        1,
      );
    });

    test('togglePitchContour pulses pitchContour', () {
      final h = harness(session: _videoSession());
      commandFor('player.togglePitchContour').execute(
        HotkeyCtx(read: h.container.read, listenerContext: null),
      );
      expect(
        h.container.read(shadowReadingHotkeyBusProvider).pitchContour,
        1,
      );
    });

    test('toggleAssessment pulses assessment', () {
      final h = harness(session: _videoSession());
      commandFor('player.toggleAssessment').execute(
        HotkeyCtx(read: h.container.read, listenerContext: null),
      );
      expect(
        h.container.read(shadowReadingHotkeyBusProvider).assessment,
        1,
      );
    });
  });

  group('gates', () {
    test('echo practice without a player session still pulses', () {
      final h = harness(
        vocabState: const ReviewSessionState(
          queue: [],
          practicePhase: ReviewPracticePhase.echo,
        ),
      );
      final ctx = HotkeyCtx(read: h.container.read, listenerContext: null);
      final command = commandFor('player.toggleRecording');
      expect(command.canExecute(ctx), isTrue);
      command.execute(ctx);
      expect(
        h.container.read(shadowReadingHotkeyBusProvider).recording,
        1,
      );
    });

    test('no session and no echo practice → canExecute false, no pulse', () {
      final h = harness();
      final ctx = HotkeyCtx(read: h.container.read, listenerContext: null);
      for (final command in shadowReadingHotkeyCommands) {
        expect(command.canExecute(ctx), isFalse, reason: command.actionId);
      }
      expect(
        h.container.read(shadowReadingHotkeyBusProvider),
        ShadowReadingHotkeyTicks.initial,
      );
    });
  });
}
