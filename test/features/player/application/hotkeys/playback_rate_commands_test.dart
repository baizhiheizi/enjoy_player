// Per-command unit tests for the playback-rate hotkey commands (issue #719).
//
// The rate clamps themselves are pinned by the D10 reducer tests in
// `test/features/player/transport_decisions_test.dart`; these tests cover the
// command shell — the session gate and the wiring from the live preference
// rate through `decidePlaybackRateStep` to `setPlaybackRate` — using a plain
// [ProviderContainer] (no widget tree).
import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/player/application/hotkeys/playback_rate_commands.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/domain/player_settings.dart'
    as player_settings;
import 'package:enjoy_player/features/player/domain/transport_decisions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePlayerController extends PlayerController {
  _FakePlayerController({this.sessionOverride});

  PlaybackSession? sessionOverride;

  @override
  PlaybackSession? build() => sessionOverride;
}

class _FakePlayerPreferencesCtrl extends PlayerPreferencesCtrl {
  _FakePlayerPreferencesCtrl({this._rate = 1.0});

  double _rate;
  final setPlaybackRateCalls = <double>[];

  @override
  player_settings.PlayerPreferences build() {
    return player_settings.PlayerPreferences(
      volume: 1.0,
      playbackRate: _rate,
      repeatMode: player_settings.RepeatMode.none,
      videoTranscriptSplitWidthPx: null,
    );
  }

  @override
  Future<void> setPlaybackRate(double r) async {
    setPlaybackRateCalls.add(r);
    _rate = r;
    state = state.copyWith(playbackRate: r);
  }
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
  ({ProviderContainer container, _FakePlayerPreferencesCtrl prefs}) harness({
    PlaybackSession? session,
    double rate = 1.0,
  }) {
    final prefs = _FakePlayerPreferencesCtrl(rate: rate);
    final player = _FakePlayerController(sessionOverride: session);
    final container = ProviderContainer(
      overrides: [
        playerControllerProvider.overrideWith(() => player),
        playerPreferencesCtrlProvider.overrideWith(() => prefs),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, prefs: prefs);
  }

  HotkeyCtx ctxFor(ProviderContainer container) =>
      HotkeyCtx(read: container.read, listenerContext: null);

  group('registry', () {
    test('exposes slowDown then speedUp in dispatch order', () {
      expect(playbackRateHotkeyCommands.map((c) => c.actionId).toList(), [
        'player.slowDown',
        'player.speedUp',
      ]);
    });

    test('nudges map to the D10 directions', () {
      expect(
        (playbackRateHotkeyCommands.first as PlaybackRateHotkeyCommand)
            .direction,
        PlaybackRateDirection.slower,
      );
      expect(
        (playbackRateHotkeyCommands.last as PlaybackRateHotkeyCommand)
            .direction,
        PlaybackRateDirection.faster,
      );
    });
  });

  group('player.slowDown', () {
    test('with a live session, applies one 0.05 step down', () {
      final h = harness(session: _videoSession(), rate: 1.0);
      const PlaybackRateHotkeyCommand(
        actionId: 'player.slowDown',
        direction: PlaybackRateDirection.slower,
      ).execute(ctxFor(h.container));
      expect(h.prefs.setPlaybackRateCalls, [0.95]);
    });

    test('at the floor, still applies the clamped 0.25 rate', () {
      final h = harness(session: _videoSession(), rate: 0.25);
      const PlaybackRateHotkeyCommand(
        actionId: 'player.slowDown',
        direction: PlaybackRateDirection.slower,
      ).execute(ctxFor(h.container));
      expect(h.prefs.setPlaybackRateCalls, [0.25]);
    });

    test('without a session, canExecute is false', () {
      final h = harness();
      const command = PlaybackRateHotkeyCommand(
        actionId: 'player.slowDown',
        direction: PlaybackRateDirection.slower,
      );
      expect(command.canExecute(ctxFor(h.container)), isFalse);
    });
  });

  group('player.speedUp', () {
    test('with a live session, applies one 0.05 step up', () {
      final h = harness(session: _videoSession(), rate: 1.0);
      const PlaybackRateHotkeyCommand(
        actionId: 'player.speedUp',
        direction: PlaybackRateDirection.faster,
      ).execute(ctxFor(h.container));
      expect(h.prefs.setPlaybackRateCalls, [1.05]);
    });

    test('at the ceiling, still applies the clamped 2.0 rate', () {
      final h = harness(session: _videoSession(), rate: 2.0);
      const PlaybackRateHotkeyCommand(
        actionId: 'player.speedUp',
        direction: PlaybackRateDirection.faster,
      ).execute(ctxFor(h.container));
      expect(h.prefs.setPlaybackRateCalls, [2.0]);
    });

    test('without a session, canExecute is false', () {
      final h = harness();
      const command = PlaybackRateHotkeyCommand(
        actionId: 'player.speedUp',
        direction: PlaybackRateDirection.faster,
      );
      expect(command.canExecute(ctxFor(h.container)), isFalse);
    });
  });
}
