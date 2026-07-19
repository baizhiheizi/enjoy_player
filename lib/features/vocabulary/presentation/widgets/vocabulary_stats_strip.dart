/// Vocabulary book stats breakdown (shown in a sheet, not a persistent banner).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_stats.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Opens Total / Due / status counts in an adaptive sheet.
Future<void> showVocabularyStatsSheet(
  BuildContext context,
  VocabularyStats stats,
) {
  final l10n = AppLocalizations.of(context)!;
  return showEnjoyAdaptiveSheet<void>(
    context: context,
    builder: (ctx) {
      final t = EnjoyThemeTokens.of(ctx);
      return Padding(
        padding: EdgeInsets.fromLTRB(
          t.space24,
          t.space16,
          t.space24,
          t.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.vocabularyTitle,
              style: Theme.of(
                ctx,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: t.space16),
            VocabularyStatsBreakdown(stats: stats),
          ],
        ),
      );
    },
  );
}

/// Compact metrics grid for the stats sheet (and widget tests).
class VocabularyStatsBreakdown extends StatelessWidget {
  const VocabularyStatsBreakdown({super.key, required this.stats});

  final VocabularyStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    final cells = <(String, int, bool)>[
      (l10n.vocabularyTotal, stats.total, false),
      (l10n.vocabularyDue, stats.due, stats.due > 0),
      (l10n.vocabularyStatusNew, stats.newCount, false),
      (l10n.vocabularyStatusLearning, stats.learningCount, false),
      (l10n.vocabularyStatusReviewing, stats.reviewingCount, false),
      (l10n.vocabularyStatusMastered, stats.masteredCount, false),
    ];

    return Wrap(
      spacing: t.space12,
      runSpacing: t.space12,
      children: [
        for (final cell in cells)
          SizedBox(
            width: 96,
            child: _StatCell(
              label: cell.$1,
              value: cell.$2,
              emphasize: cell.$3,
            ),
          ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final int value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final valueColor = emphasize ? cs.primary : cs.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: emphasize
                ? cs.primary.withValues(alpha: 0.85)
                : cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
