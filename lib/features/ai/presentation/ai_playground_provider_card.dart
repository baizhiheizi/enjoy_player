/// Active-providers panel for the AI playground (rows, dividers, card).
library;

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/ai/application/ai_byok_error_mapping.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class AiPlaygroundProvidersCard extends StatelessWidget {
  const AiPlaygroundProvidersCard({
    required this.llmLabel,
    required this.asrLabel,
    required this.ttsLabel,
    required this.assessmentLabel,
    super.key,
  });

  final String llmLabel;
  final String asrLabel;
  final String ttsLabel;
  final String assessmentLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnjoySectionHeader(title: l10n.aiPlaygroundActiveProviders),
        SizedBox(height: t.space12),
        EnjoyCard(
          padding: EdgeInsets.symmetric(vertical: t.space4),
          child: Column(
            children: [
              SettingsRow(
                responsive: false,
                leadingIcon: EnjoyIcons.robot,
                title: l10n.settingsAiProvidersModalityLlm,
                trailing: _providerValue(context, llmLabel),
              ),
              const SettingsRowDivider(),
              SettingsRow(
                responsive: false,
                leadingIcon: EnjoyIcons.mic,
                title: l10n.settingsAiProvidersModalityAsr,
                trailing: _providerValue(context, asrLabel),
              ),
              const SettingsRowDivider(),
              SettingsRow(
                responsive: false,
                leadingIcon: EnjoyIcons.speak,
                title: l10n.settingsAiProvidersModalityTts,
                trailing: _providerValue(context, ttsLabel),
              ),
              const SettingsRowDivider(),
              SettingsRow(
                responsive: false,
                leadingIcon: EnjoyIcons.insights,
                title: l10n.settingsAiProvidersModalityAssessment,
                trailing: _providerValue(context, assessmentLabel),
              ),
              const SettingsRowDivider(),
              SettingsRow(
                responsive: false,
                leadingIcon: EnjoyIcons.tune,
                title: l10n.settingsAiProvidersTileTitle,
                onTap: () => context.push(aiProvidersSettingsPath),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _providerValue(BuildContext context, String value) {
  final t = EnjoyThemeTokens.of(context);
  final tt = Theme.of(context).textTheme;
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: kSettingsRowValueTextMaxWidth),
    child: Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: tt.bodySmall?.copyWith(fontSize: 13, color: t.ink3),
    ),
  );
}
