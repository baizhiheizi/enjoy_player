/// Dialog to capture one key chord for shortcut customization.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_chord.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class HotkeyCaptureDialog extends StatefulWidget {
  const HotkeyCaptureDialog({super.key});

  @override
  State<HotkeyCaptureDialog> createState() => _HotkeyCaptureDialogState();
}

class _HotkeyCaptureDialogState extends State<HotkeyCaptureDialog> {
  final FocusNode _focus = FocusNode(debugLabel: 'hotkey-capture');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop<String>(null);
      return KeyEventResult.handled;
    }
    final serialized = serializeChordFromKeyEvent(event);
    if (serialized != null && isValidHotkeyBindingString(serialized)) {
      Navigator.of(context).pop<String>(serialized);
      return KeyEventResult.handled;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.hotkeysCaptureTitle),
      content: Focus(
        autofocus: true,
        focusNode: _focus,
        onKeyEvent: _onKey,
        child: Text(l10n.hotkeysCaptureHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<String>(null),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}
