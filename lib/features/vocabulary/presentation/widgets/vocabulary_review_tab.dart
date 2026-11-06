import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_stats.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_review_options.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_review_launch.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_stats_cards.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class VocabularyReviewTab extends ConsumerWidget {
  const VocabularyReviewTab({super.key, required this.stats});

  final VocabularyStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custom = EnjoyCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        child: VocabularyCustomReview(
          onStart: (options) => startVocabularyReview(context, ref, options),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final due = _DueReviewCard(stats: stats);
        if (constraints.maxWidth < vocabularyStatsSplitMinWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [due, const SizedBox(height: 16), custom],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 10, child: due),
            const SizedBox(width: 20),
            Expanded(flex: 12, child: custom),
          ],
        );
      },
    );
  }
}

class _DueReviewCard extends ConsumerWidget {
  const _DueReviewCard({required this.stats});

  final VocabularyStats stats;

  static const int _kPreviewWords = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final items = ref.watch(vocabularyItemsProvider).valueOrNull ?? const [];
    final dueWords = buildVocabularySessionQueue(
      items: items,
      options: const ReviewSelectionOptions(mode: VocabularyReviewMode.due),
      now: DateTime.now(),
    ).map((i) => i.word).toList();
    final hasDue = dueWords.isNotEmpty;

    Widget chip(String text) => Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      alignment: Alignment.center,
      decoration: ShapeDecoration(color: t.sunk, shape: const StadiumBorder()),
      child: Text(
        text,
        style: enjoyDisplayStyle(context, size: 15, color: t.ink, height: 1),
      ),
    );

    return EnjoyCard(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            EnjoyOverline(l10n.vocabularyReviewDueItems, color: t.brandInk),
            const SizedBox(height: 14),
            Text(
              hasDue
                  ? l10n.vocabularyDueWaiting(dueWords.length)
                  : l10n.vocabularyNoDueItems,
              style: enjoyDisplayStyle(
                context,
                size: 34,
                color: t.ink,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasDue
                  ? l10n.vocabularyDueReviewBody
                  : l10n.vocabularyNoDueItemsDescription,
              style: tt.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.55,
                color: t.ink2,
              ),
            ),
            if (hasDue) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final word in dueWords.take(_kPreviewWords)) chip(word),
                  if (dueWords.length > _kPreviewWords)
                    chip('+${dueWords.length - _kPreviewWords}'),
                ],
              ),
              const SizedBox(height: 22),
              EnjoyButton.brand(
                onPressed: () => startVocabularyReview(
                  context,
                  ref,
                  const ReviewSelectionOptions(mode: VocabularyReviewMode.due),
                ),
                child: Text(l10n.vocabularyStartReview),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
