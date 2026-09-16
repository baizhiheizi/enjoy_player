/// Shadow-reading hotkey bus pulse commands (issue #719).
///
/// `R` / `G` / `P` / `V` pulse the shared [ShadowReadingHotkeyBus] consumed by
/// `ShadowReadingPanel` / `PitchContourSection`; the commands live here, next
/// to the bus they pulse.
library;

import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/hotkeys/application/shadow_reading_hotkey_policy.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_review_practice.dart';

/// Pulses one shadow-reading bus tick. Enabled during an active player
/// session (expanded / mini player echo) or vocabulary echo practice, which is
/// recorder-only and has no player session — see
/// [shadowReadingBusHotkeysEnabled].
class ShadowReadingBusHotkeyCommand extends HotkeyCommand {
  const ShadowReadingBusHotkeyCommand(this.actionId, this.pulse);

  @override
  final String actionId;

  final void Function(ShadowReadingHotkeyBus bus) pulse;

  @override
  bool canExecute(HotkeyCtx ctx) {
    return shadowReadingBusHotkeysEnabled(
      hasPlayerSession: ctx.read(playerControllerProvider) != null,
      vocabularyEchoPracticeOpen:
          ctx.read(vocabularyReviewSessionProvider).practiceMode ==
          ReviewPracticeMode.echo,
    );
  }

  @override
  void execute(HotkeyCtx ctx) {
    pulse(ctx.read(shadowReadingHotkeyBusProvider.notifier));
  }
}

/// Bus pulse commands in dispatch order (the old listener chain's bus block).
final List<HotkeyCommand> shadowReadingHotkeyCommands = [
  ShadowReadingBusHotkeyCommand(
    'player.toggleRecording',
    (bus) => bus.pulseRecording(),
  ),
  ShadowReadingBusHotkeyCommand(
    'player.playRecording',
    (bus) => bus.pulsePlayback(),
  ),
  ShadowReadingBusHotkeyCommand(
    'player.togglePitchContour',
    (bus) => bus.pulsePitchContour(),
  ),
  ShadowReadingBusHotkeyCommand(
    'player.toggleAssessment',
    (bus) => bus.pulseAssessment(),
  ),
];
