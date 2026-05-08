/// Read-only list of shortcuts (web `HotkeysHelpModal` parity).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definition.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_format.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_description.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class HotkeysHelpDialog extends ConsumerWidget {
  const HotkeysHelpDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(hotkeysCtrlProvider);
    final ctrl = ref.read(hotkeysCtrlProvider.notifier);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.keyboard_outlined, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.hotkeysTitle)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final scope in HotkeyScope.values) ...[
                if (_definitionsFor(scope).isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      hotkeysScopeLabel(l10n, scope),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  for (final def in _definitionsFor(scope))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              hotkeyDescription(l10n, def),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Wrap(
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (ctrl.hasCustomBinding(def.id))
                                Chip(
                                  label: Text(
                                    l10n.hotkeysCustomizedBadge,
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                                ),
                              Text(
                                formatHotkeyForDisplay(ctrl.effectiveKeys(def.id)),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ],
              const SizedBox(height: 12),
              Text(
                l10n.hotkeysHintFooter,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }

  static List<HotkeyDefinition> _definitionsFor(HotkeyScope scope) =>
      hotkeyDefinitions.where((d) => d.scope == scope).toList();
}
