/// Ordered hotkey command registry + dispatch (issue #719).
///
/// Registration order IS dispatch priority — it preserves the total order of
/// the listener if-chain this replaces (modal.close → global nav → library
/// `/` → shadow-reading bus pulses → session-gated player keys), so two
/// rebound bindings can never flip behavior nondeterministically: the first
/// command (in this list's order) whose [HotkeyCommand.actionId] resolves to
/// the pressed binding and whose gate passes wins.
library;

import 'package:flutter/services.dart';

import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_chord.dart';
import 'package:enjoy_player/features/player/application/hotkeys/player_hotkey_commands.dart';

/// All registered commands, in dispatch (priority) order.
final List<HotkeyCommand> hotkeyCommands = [...playerHotkeyCommands];

/// Resolve [event] against [ctrl]'s effective bindings and run the first
/// command (in [commands] order, defaulting to [hotkeyCommands]) whose action
/// matches and passes its gate.
///
/// Returns whether the event was handled. A matched binding whose
/// `canExecute` gate fails does not stop the scan — later commands may still
/// claim the chord (the fall-through semantics of the old if-chain).
bool dispatchHotkey({
  required KeyEvent event,
  required HotkeysCtrl ctrl,
  required HotkeyCtx ctx,
  List<HotkeyCommand>? commands,
}) {
  for (final command in commands ?? hotkeyCommands) {
    final binding = ctrl.effectiveKeys(command.actionId);
    if (binding.isEmpty) continue;
    if (!hotkeyMatchesBinding(event, binding)) continue;
    if (!command.canExecute(ctx)) continue;
    command.execute(ctx);
    return true;
  }
  return false;
}
