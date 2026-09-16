/// `player.slowDown` / `player.speedUp` hotkey commands (issue #719).
///
/// Session-gated rate nudges. The clamp itself is the pure D10 reducer
/// `decidePlaybackRateStep` in `domain/transport_decisions.dart`; this file is
/// its single imperative consumer.
library;

import 'dart:async';

import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/domain/transport_decisions.dart';

/// Nudges the playback rate by one D10 step when a playback session is live.
class PlaybackRateHotkeyCommand extends HotkeyCommand {
  const PlaybackRateHotkeyCommand({
    required this.actionId,
    required this.direction,
  });

  @override
  final String actionId;

  /// Which way the nudge goes (`player.slowDown` → [PlaybackRateDirection.slower]).
  final PlaybackRateDirection direction;

  @override
  bool canExecute(HotkeyCtx ctx) => ctx.read(playerControllerProvider) != null;

  @override
  void execute(HotkeyCtx ctx) {
    final rate = ctx.read(playerPreferencesCtrlProvider).playbackRate;
    final next = decidePlaybackRateStep(rate: rate, direction: direction);
    unawaited(
      ctx
          .read(playerPreferencesCtrlProvider.notifier)
          .setPlaybackRate(next.rate),
    );
  }
}

/// Rate commands in dispatch order (their position inside the old
/// session-gated block of the listener chain: after the line hotkeys, before
/// the echo brackets).
final List<HotkeyCommand> playbackRateHotkeyCommands = [
  const PlaybackRateHotkeyCommand(
    actionId: 'player.slowDown',
    direction: PlaybackRateDirection.slower,
  ),
  const PlaybackRateHotkeyCommand(
    actionId: 'player.speedUp',
    direction: PlaybackRateDirection.faster,
  ),
];
