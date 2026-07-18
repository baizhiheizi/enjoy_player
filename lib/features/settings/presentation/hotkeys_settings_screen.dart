/// Full-screen keyboard shortcut customization (desktop).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_format.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_reset_all.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_settings_section.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class HotkeysSettingsScreen extends ConsumerWidget {
  const HotkeysSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    ref.watch(hotkeysCtrlProvider);
    final ctrl = ref.read(hotkeysCtrlProvider.notifier);
    final helpKeyLabel = formatHotkeyForDisplay(
      ctrl.effectiveKeys('global.help'),
    );

    return EnjoyPage(
      kind: EnjoyPageKind.hub,
      title: l10n.hotkeysSectionKeyboard,
      showBack: true,
      actions: [
        TextButton(
          onPressed: () async {
            if (!await confirmHotkeysResetAll(context)) return;
            if (!context.mounted) return;
            await ctrl.resetAllBindings();
          },
          child: Text(l10n.hotkeysResetAll),
        ),
      ],
      body: (context, metrics) => ListView(
        padding: metrics.padding(top: t.space16, bottom: t.space32),
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: t.space8,
              right: t.space8,
              bottom: t.space16,
            ),
            child: Text(
              l10n.hotkeysSettingsSubtitle(helpKeyLabel),
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
          EnjoyCard(
            padding: EdgeInsets.all(t.space16),
            child: const HotkeysSettingsSection(),
          ),
        ],
      ),
    );
  }
}
