import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_logo.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_stats.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_l10n.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_word_list.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const int _kSecondsPerCard = 15;
const double vocabularyStatsSplitMinWidth = 856;

int _vocabularyReviewMinutes(int due) =>
    due <= 0 ? 0 : (due * _kSecondsPerCard / 60).ceil();

class VocabularyStatsRow extends StatelessWidget {
  const VocabularyStatsRow({super.key, required this.stats});

  final VocabularyStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final due = _DueCard(stats: stats);
        final breakdown = _StatusCard(stats: stats);
        if (constraints.maxWidth < vocabularyStatsSplitMinWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [due, const SizedBox(height: 16), breakdown],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 12, child: due),
              const SizedBox(width: 20),
              Expanded(flex: 20, child: breakdown),
            ],
          ),
        );
      },
    );
  }
}

class _DueCard extends StatelessWidget {
  const _DueCard({required this.stats});

  final VocabularyStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    return EnjoyCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Row(
          children: [
            const EnjoyLogoMark(size: 76),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${stats.due} ',
                          style: enjoyDisplayStyle(
                            context,
                            size: 44,
                            color: t.ink,
                            height: 1,
                            letterSpacing: -0.88,
                          ),
                        ),
                        TextSpan(
                          text: l10n.vocabularyDueToday,
                          style: tt.bodyMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: t.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.vocabularyDueEstimate(
                      _vocabularyReviewMinutes(stats.due),
                    ),
                    style: tt.bodySmall?.copyWith(fontSize: 13, color: t.ink3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.stats});

  final VocabularyStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final parts = [
      (VocabularyStatus.new_, stats.newCount),
      (VocabularyStatus.learning, stats.learningCount),
      (VocabularyStatus.reviewing, stats.reviewingCount),
      (VocabularyStatus.mastered, stats.masteredCount),
    ];
    return EnjoyCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: EnjoyOverline(l10n.vocabularyQueueCount(stats.total)),
                ),
                Text(
                  l10n.vocabularyByStatus,
                  style: tt.bodySmall?.copyWith(fontSize: 12.5, color: t.ink3),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    for (final (i, (status, count)) in parts.indexed)
                      if (count > 0) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Expanded(
                          flex: count,
                          child: ColoredBox(
                            color: vocabularyStatusColor(t, status),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final (status, count) in parts)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: vocabularyStatusColor(t, status),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                vocabularyStatusLabel(l10n, status),
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodySmall?.copyWith(
                                  fontSize: 12.5,
                                  color: t.ink2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$count',
                          style: enjoyDisplayStyle(
                            context,
                            size: 24,
                            color: t.ink,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
