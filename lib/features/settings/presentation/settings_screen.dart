/// Settings with grouped sections (modern minimal layout).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_settings_section.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _SectionLabel(text: l10n.settingsSectionAppearance),
          ListTile(
            leading: Icon(Icons.palette_outlined, color: cs.primary),
            title: Text(l10n.settingsThemeRowTitle, style: tt.titleMedium),
            subtitle: Text(
              l10n.settingsThemeDarkLocked,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          SizedBox(height: t.space8),
          _SectionLabel(text: l10n.hotkeysSectionKeyboard),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.space16),
            child: const HotkeysSettingsSection(),
          ),
          SizedBox(height: t.space8),
          _SectionLabel(text: l10n.settingsSectionAbout),
          ListTile(
            leading: Icon(Icons.info_outline_rounded, color: cs.primary),
            title: Text(l10n.appTitle, style: tt.titleMedium),
            subtitle: Text(
              l10n.settingsAboutSubtitle,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(t.space16, t.space24, t.space16, 0),
            child: Text(
              l10n.settingsPlaceholder,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(t.space16, t.space24, t.space16, t.space8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.05,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
