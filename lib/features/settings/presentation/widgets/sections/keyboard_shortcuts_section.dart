/// Keyboard shortcuts row body — cheatsheet + customize rows (desktop only).
///
/// Desktop-only visibility (FR-006) is enforced by the caller
/// (`SettingsLayoutSingleColumn`/`SettingsLayoutTwoPane`), not this widget.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_help_dialog.dart';
import 'package:enjoy_player/features/hotkeys/presentation/widgets/kbd_chip.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class KeyboardShortcutsSectionBody extends ConsumerWidget {
  const KeyboardShortcutsSectionBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(hotkeysCtrlProvider);
    final keys = ref
        .read(hotkeysCtrlProvider.notifier)
        .effectiveKeys('global.help');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsRow(
          leadingIcon: Icons.help_outline_rounded,
          title: l10n.settingsKeyboardOpenCheatsheet,
          subtitle: l10n.settingsKeyboardOpenCheatsheetSubtitle,
          trailing: KbdChordRow(binding: keys, compact: true),
          showChevron: false,
          onTap: () => showHotkeysHelpDialog(context),
        ),
        const SettingsRowDivider(),
        SettingsRow(
          leadingIcon: Icons.tune_rounded,
          title: l10n.settingsKeyboardCustomizeTitle,
          subtitle: l10n.hotkeysSectionKeyboardHint,
          onTap: () => context.push('/settings/keyboard'),
        ),
      ],
    );
  }
}
