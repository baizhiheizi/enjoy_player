/// Stats strip for the Vocabulary destination (total / due / statuses).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
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

    final cells = <(String, int)>[
      (l10n.vocabularyTotal, stats.total),
      (l10n.vocabularyDue, stats.due),
      (l10n.vocabularyStatusNew, stats.newCount),
      (l10n.vocabularyStatusLearning, stats.learningCount),
      (l10n.vocabularyStatusReviewing, stats.reviewingCount),
      (l10n.vocabularyStatusMastered, stats.masteredCount),
    ];

    return Wrap(
      spacing: t.space8,
      runSpacing: t.space8,
      children: [
        for (final (label, value) in cells)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: t.space12,
              vertical: t.space8,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(t.radiusMd),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: t.space4),
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
