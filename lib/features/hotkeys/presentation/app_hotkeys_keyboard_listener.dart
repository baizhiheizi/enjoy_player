/// Global keyboard shortcuts (web hotkeys parity).
///
/// The listener is deliberately thin: early returns (KeyUp, editable-text
/// focus) plus one dispatch through the ordered command registry — see
/// `application/hotkey_commands.dart`. Every action's gate and execution live
/// in its [HotkeyCommand], next to the logic it calls.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_commands.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_focus_policy.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';

class AppHotkeysKeyboardListener extends ConsumerStatefulWidget {
  const AppHotkeysKeyboardListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppHotkeysKeyboardListener> createState() =>
      _AppHotkeysKeyboardListenerState();
}

class _AppHotkeysKeyboardListenerState
    extends ConsumerState<AppHotkeysKeyboardListener> {
  late final bool Function(KeyEvent event) _handler = _onKey;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handler);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handler);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (!mounted) return false;
    if (event is! KeyDownEvent) return false;
    if (primaryFocusBlocksGlobalHotkeys()) return false;

    return dispatchHotkey(
      event: event,
      ctrl: ref.read(hotkeysCtrlProvider.notifier),
      // The listener's own context sits above `MaterialApp.router`'s
      // Navigator (it is built in the router's `builder`), so commands
      // navigate through the router keys on [HotkeyCtx], not this context —
      // see [HotkeyCtx.listenerContext] for the one intentional exception.
      ctx: HotkeyCtx(read: ref.read, listenerContext: context),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
