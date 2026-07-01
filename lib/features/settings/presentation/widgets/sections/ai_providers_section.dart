/// AI providers row body — single navigation row into the AI providers screen.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class AiProvidersSectionBody extends StatelessWidget {
  const AiProvidersSectionBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsRow(
      leadingIcon: Icons.tune_outlined,
      title: l10n.settingsAiProvidersTileTitle,
      subtitle: l10n.settingsAiProvidersTileSubtitle,
      onTap: () => context.push('/settings/ai-providers'),
    );
  }
}
