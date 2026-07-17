/// Stats strip for the Vocabulary destination (total / due / statuses).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_stats.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class VocabularyStatsStrip extends StatelessWidget {
  const VocabularyStatsStrip({super.key, required this.stats});

  final VocabularyStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    final cells = <(String, int, bool)>[
      (l10n.vocabularyTotal, stats.total, false),
      (l10n.vocabularyDue, stats.due, stats.due > 0),
      (l10n.vocabularyStatusNew, stats.newCount, false),
      (l10n.vocabularyStatusLearning, stats.learningCount, false),
      (l10n.vocabularyStatusReviewing, stats.reviewingCount, false),
      (l10n.vocabularyStatusMastered, stats.masteredCount, false),
    ];

    return EnjoyCard(
      padding: EdgeInsets.all(t.space12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          if (compact) {
            return Wrap(
              spacing: t.space8,
              runSpacing: t.space8,
              children: [
                for (final cell in cells)
                  SizedBox(
                    width: (constraints.maxWidth - t.space8) / 2,
                    child: _StatCell(
                      label: cell.$1,
                      value: cell.$2,
                      emphasize: cell.$3,
                      bordered: true,
                    ),
                  ),
              ],
            );
          }

          return Row(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 36,
                    color: cs.outlineVariant.withValues(alpha: 0.25),
                  ),
                Expanded(
                  child: _StatCell(
                    label: cells[i].$1,
                    value: cells[i].$2,
                    emphasize: cells[i].$3,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.emphasize,
    this.bordered = false,
  });

  final String label;
  final int value;
  final bool emphasize;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final valueColor = emphasize ? cs.primary : cs.onSurface;

    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: t.space8,
        vertical: bordered ? t.space8 : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: t.space4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: emphasize
                  ? cs.primary.withValues(alpha: 0.85)
                  : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    if (!bordered) return content;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(t.radiusSm),
      ),
      child: content,
    );
  }
}
