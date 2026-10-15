/// Active-providers panel for the AI playground (rows, dividers, card).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_icon_tile.dart';
import 'package:enjoy_player/features/ai/application/ai_byok_error_mapping.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const double _rowLeadingSize = 30;
const double _rowLeadingGap = 12;
const double _rowHorizontalPadding = 12;

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
              PlaygroundGroupRow(
                icon: EnjoyIcons.robot,
                label: l10n.settingsAiProvidersModalityLlm,
                value: llmLabel,
              ),
              const PlaygroundRowDivider(),
              PlaygroundGroupRow(
                icon: EnjoyIcons.mic,
                label: l10n.settingsAiProvidersModalityAsr,
                value: asrLabel,
              ),
              const PlaygroundRowDivider(),
              PlaygroundGroupRow(
                icon: EnjoyIcons.speak,
                label: l10n.settingsAiProvidersModalityTts,
                value: ttsLabel,
              ),
              const PlaygroundRowDivider(),
              PlaygroundGroupRow(
                icon: EnjoyIcons.insights,
                label: l10n.settingsAiProvidersModalityAssessment,
                value: assessmentLabel,
              ),
              const PlaygroundRowDivider(),
              PlaygroundGroupRow(
                icon: EnjoyIcons.tune,
                label: l10n.settingsAiProvidersTileTitle,
                onTap: () => context.push(aiProvidersSettingsPath),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PlaygroundGroupRow extends StatelessWidget {
  const PlaygroundGroupRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final value = this.value;

    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _rowHorizontalPadding,
          vertical: t.space8,
        ),
        child: Row(
          children: [
            EnjoyIconTile(icon: icon, size: _rowLeadingSize),
            const SizedBox(width: _rowLeadingGap),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodyMedium,
              ),
            ),
            if (value != null) ...[
              SizedBox(width: t.space8),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ] else
              Icon(EnjoyIcons.chevronRight, size: 15, color: t.ink3),
          ],
        ),
      ),
    );

    if (onTap == null) return body;
    return EnjoyPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(t.radiusMd),
      pressedScale: 0.995,
      child: body,
    );
  }
}

class PlaygroundRowDivider extends StatelessWidget {
  const PlaygroundRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: _rowHorizontalPadding + _rowLeadingSize + _rowLeadingGap,
      endIndent: _rowHorizontalPadding,
      color: EnjoyThemeTokens.of(context).hairline,
    );
  }
}
