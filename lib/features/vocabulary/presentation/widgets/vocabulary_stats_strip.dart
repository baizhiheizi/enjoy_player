/// Stats strip for the Vocabulary destination (total / due / statuses).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_tappable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_stats.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class VocabularyStatsStrip extends StatefulWidget {
  const VocabularyStatsStrip({super.key, required this.stats});

  final VocabularyStats stats;

  @override
  State<VocabularyStatsStrip> createState() => _VocabularyStatsStripState();
}

class _VocabularyStatsStripState extends State<VocabularyStatsStrip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final stats = widget.stats;

    final statusCells = <(String, int)>[
      (l10n.vocabularyStatusNew, stats.newCount),
      (l10n.vocabularyStatusLearning, stats.learningCount),
      (l10n.vocabularyStatusReviewing, stats.reviewingCount),
      (l10n.vocabularyStatusMastered, stats.masteredCount),
    ];

    return EnjoyCard(
      padding: EdgeInsets.symmetric(horizontal: t.space12, vertical: t.space8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: l10n.vocabularyTotal,
                  value: stats.total,
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: cs.outlineVariant.withValues(alpha: 0.25),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: l10n.vocabularyDue,
                  value: stats.due,
                  emphasize: stats.due > 0,
                ),
              ),
              EnjoyTappableIcon(
                icon: _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                tooltip: _expanded
                    ? l10n.vocabularyStatsCollapse
                    : l10n.vocabularyStatsExpand,
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ],
          ),
          AnimatedSize(
            duration: t.motionStandard,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: EdgeInsets.only(top: t.space8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 560;
                        if (wide) {
                          return Row(
                            children: [
                              for (var i = 0; i < statusCells.length; i++) ...[
                                if (i > 0)
                                  Container(
                                    width: 1,
                                    height: 28,
                                    color: cs.outlineVariant.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                Expanded(
                                  child: _StatusMetric(
                                    label: statusCells[i].$1,
                                    value: statusCells[i].$2,
                                  ),
                                ),
                              ],
                            ],
                          );
                        }
                        return Wrap(
                          spacing: t.space8,
                          runSpacing: t.space4,
                          children: [
                            for (final cell in statusCells)
                              SizedBox(
                                width: (constraints.maxWidth - t.space8) / 2,
                                child: _StatusMetric(
                                  label: cell.$1,
                                  value: cell.$2,
                                  alignStart: true,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final int value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final valueColor = emphasize ? cs.primary : cs.onSurface;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space8),
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
          const SizedBox(height: 2),
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
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({
    required this.label,
    required this.value,
    this.alignStart = false,
  });

  final String label;
  final int value;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final align = alignStart
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space8, vertical: t.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: align,
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: alignStart ? TextAlign.start : TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
