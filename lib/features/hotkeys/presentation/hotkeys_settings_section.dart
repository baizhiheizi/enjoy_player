/// Settings rows for customizing shortcuts (Drift-backed via [HotkeysCtrl]).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_capture_dialog.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_format.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_description.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class HotkeysSettingsSection extends ConsumerWidget {
  const HotkeysSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(hotkeysCtrlProvider);
    final ctrl = ref.read(hotkeysCtrlProvider.notifier);

    Future<void> editBinding(String id) async {
      final chord = await showDialog<String>(
        context: context,
        builder: (ctx) => const HotkeyCaptureDialog(),
      );
      if (chord == null || !context.mounted) return;
      final ok = await ctrl.setBinding(id, chord);
      if (!context.mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.hotkeysConflictError)),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              await ctrl.resetAllBindings();
            },
            child: Text(l10n.hotkeysResetAll),
          ),
        ),
        const SizedBox(height: 8),
        for (final def in hotkeyDefinitions.where((d) => d.customizable))
          ListTile(
            title: Text(hotkeyDescription(l10n, def)),
            subtitle: Text(formatHotkeyForDisplay(ctrl.effectiveKeys(def.id))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => ctrl.resetBinding(def.id),
                  child: Text(l10n.hotkeysResetBinding),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            onTap: () => editBinding(def.id),
          ),
      ],
    );
  }
}
