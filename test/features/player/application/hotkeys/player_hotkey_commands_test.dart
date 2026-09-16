// Per-command unit tests for the session-gated player hotkey commands
// (issue #719) — togglePlay, toggleFullscreen, and the PlayerInteractions
// line / echo commands — using a plain [ProviderContainer] (no widget tree).
//
// `player.toggleExpand`'s execution arms stay covered end-to-end in
// `test/features/hotkeys/app_hotkeys_keyboard_listener_test.dart`: both arms
// navigate through mounted contexts (collapse pops the router stack; the
// open arm intentionally uses the listener's own context above the router).
// The playback-rate commands have their own suite
// (`playback_rate_commands_test.dart`).
import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/player/application/hotkeys/player_hotkey_commands.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePlayerController extends PlayerController {
  PlaybackSession? sessionOverride;
  var togglePlayCalls = 0;

  @override
  PlaybackSession? build() => sessionOverride;

  @override
  Future<void> togglePlay() async {
    togglePlayCalls++;
  }
}

class _FakeWindowFullscreen extends WindowFullscreen {
  _FakeWindowFullscreen({required bool fullscreen})
    : _isFullscreen = fullscreen;

  // ignore: unused_field
  bool _isFullscreen;
  var toggleCalls = 0;

  @override
  bool build() => _isFullscreen;

  @override
  Future<void> setFullscreen(bool value) async {
    _isFullscreen = value;
    state = value;
  }

  @override
  Future<void> toggle() async {
    toggleCalls++;
    await setFullscreen(!state);
  }
}

class _FakePlayerInteractions extends PlayerInteractions {
  _FakePlayerInteractions(super.ref);

  var prevLineCalls = 0;
  var nextLineCalls = 0;
  var replayLineCalls = 0;
  var toggleEchoCalls = 0;
  var toggleBlurCalls = 0;
  var expandEchoBackwardCalls = 0;
  var expandEchoForwardCalls = 0;
  var shrinkEchoBackwardCalls = 0;
  var shrinkEchoForwardCalls = 0;

  @override
  Future<void> prevLine() async {
    prevLineCalls++;
  }

  @override
  Future<void> nextLine() async {
    nextLineCalls++;
  }

  @override
  Future<void> replayLine() async {
    replayLineCalls++;
  }

  @override
  Future<void> toggleEcho() async {
    toggleEchoCalls++;
  }

  @override
  Future<void> toggleBlur() async {
    toggleBlurCalls++;
  }

  @override
  Future<void> expandEchoBackward() async {
    expandEchoBackwardCalls++;
  }

  @override
  Future<void> expandEchoForward() async {
    expandEchoForwardCalls++;
  }

  @override
  Future<void> shrinkEchoBackward() async {
    shrinkEchoBackwardCalls++;
  }

  @override
  Future<void> shrinkEchoForward() async {
    shrinkEchoForwardCalls++;
  }
}

PlaybackSession _session({required String mediaType}) => PlaybackSession(
  mediaId: 'm1',
  dexieTargetType: mediaType == 'video' ? 'Video' : 'Audio',
  mediaType: mediaType,
  mediaTitle: 'Test',
  durationSeconds: 60,
  currentTimeSeconds: 0,
  currentSegmentIndex: 0,
  language: 'en',
  startedAt: DateTime(2026),
  lastActiveAt: DateTime(2026),
);

void main() {
  late _FakePlayerController player;
  late _FakeWindowFullscreen fullscreen;
  late _FakePlayerInteractions interactions;
  late ProviderContainer container;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    player = _FakePlayerController();
    fullscreen = _FakeWindowFullscreen(fullscreen: false);
    container = ProviderContainer(
      overrides: [
        playerControllerProvider.overrideWith(() => player),
        windowFullscreenProvider.overrideWith(() => fullscreen),
        playerInteractionsProvider.overrideWith(
          (ref) => interactions = _FakePlayerInteractions(ref),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    // Initialize the interactions provider so the override has run.
    container.read(playerInteractionsProvider);
  });

  HotkeyCtx ctx() => HotkeyCtx(read: container.read, listenerContext: null);

  group('registry', () {
    test('keeps the old session-block chain order', () {
      expect(playerHotkeyCommands.map((c) => c.actionId).toList(), [
        'player.togglePlay',
        'player.toggleExpand',
        'player.toggleFullscreen',
        'player.prevLine',
        'player.nextLine',
        'player.replayLine',
        'player.toggleEchoMode',
        'player.toggleBlurPractice',
        'player.slowDown',
        'player.speedUp',
        'player.expandEchoBackward',
        'player.expandEchoForward',
        'player.shrinkEchoBackward',
        'player.shrinkEchoForward',
      ]);
    });
  });

  group('player.togglePlay', () {
    test('with a live session, toggles playback', () {
      player.sessionOverride = _session(mediaType: 'video');
      const TogglePlayHotkeyCommand().execute(ctx());
      expect(player.togglePlayCalls, 1);
    });

    test('without a session, canExecute is false', () {
      expect(const TogglePlayHotkeyCommand().canExecute(ctx()), isFalse);
    });
  });

  group('player.toggleExpand', () {
    test('without a session, canExecute is false', () {
      expect(const ToggleExpandHotkeyCommand().canExecute(ctx()), isFalse);
    });
  });

  group('player.toggleFullscreen', () {
    test('video session on desktop toggles fullscreen', () {
      player.sessionOverride = _session(mediaType: 'video');
      expect(const ToggleFullscreenHotkeyCommand().canExecute(ctx()), isTrue);
      const ToggleFullscreenHotkeyCommand().execute(ctx());
      expect(fullscreen.toggleCalls, 1);
    });

    test('audio session does not toggle', () {
      player.sessionOverride = _session(mediaType: 'audio');
      expect(const ToggleFullscreenHotkeyCommand().canExecute(ctx()), isFalse);
    });

    test('non-desktop does not toggle', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      player.sessionOverride = _session(mediaType: 'video');
      expect(const ToggleFullscreenHotkeyCommand().canExecute(ctx()), isFalse);
    });

    test('without a session, canExecute is false', () {
      expect(const ToggleFullscreenHotkeyCommand().canExecute(ctx()), isFalse);
    });
  });

  group('player interactions commands', () {
    void expectInvoked(HotkeyCommand command, int Function() calls) {
      player.sessionOverride = _session(mediaType: 'video');
      command.execute(ctx());
      expect(calls(), 1);
    }

    test('prevLine', () {
      expectInvoked(
        playerHotkeyCommands
            .where((c) => c.actionId == 'player.prevLine')
            .first,
        () => interactions.prevLineCalls,
      );
    });

    test('nextLine', () {
      expectInvoked(
        playerHotkeyCommands
            .where((c) => c.actionId == 'player.nextLine')
            .first,
        () => interactions.nextLineCalls,
      );
    });

    test('replayLine', () {
      expectInvoked(
        playerHotkeyCommands
            .where((c) => c.actionId == 'player.replayLine')
            .first,
        () => interactions.replayLineCalls,
      );
    });

    test('toggleEchoMode', () {
      expectInvoked(
        playerHotkeyCommands
            .where((c) => c.actionId == 'player.toggleEchoMode')
            .first,
        () => interactions.toggleEchoCalls,
      );
    });

    test('toggleBlurPractice', () {
      expectInvoked(
        playerHotkeyCommands
            .where((c) => c.actionId == 'player.toggleBlurPractice')
            .first,
        () => interactions.toggleBlurCalls,
      );
    });

    test('expandEchoBackward', () {
      expectInvoked(
        playerHotkeyCommands
            .where((c) => c.actionId == 'player.expandEchoBackward')
            .first,
        () => interactions.expandEchoBackwardCalls,
      );
    });

    test('expandEchoForward', () {
      expectInvoked(
        playerHotkeyCommands
            .where((c) => c.actionId == 'player.expandEchoForward')
            .first,
        () => interactions.expandEchoForwardCalls,
      );
    });

    test('shrinkEchoBackward', () {
      expectInvoked(
        playerHotkeyCommands
            .where((c) => c.actionId == 'player.shrinkEchoBackward')
            .first,
        () => interactions.shrinkEchoBackwardCalls,
      );
    });

    test('shrinkEchoForward', () {
      expectInvoked(
        playerHotkeyCommands
            .where((c) => c.actionId == 'player.shrinkEchoForward')
            .first,
        () => interactions.shrinkEchoForwardCalls,
      );
    });

    test('line hotkeys without a session are gated off', () {
      for (final command in playerHotkeyCommands) {
        expect(command.canExecute(ctx()), isFalse, reason: command.actionId);
      }
    });
  });
}
