/// Vocabulary destination: stats + Review / All Words tabs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_review_options.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_word_list.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_empty_states.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_stats_strip.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class VocabularyScreen extends ConsumerWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final stats = ref.watch(vocabularyStatsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.vocabularyTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.vocabularyReview),
              Tab(text: l10n.vocabularyAllWords),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(t.space16, t.space16, t.space16, 0),
              child: VocabularyStatsStrip(stats: stats),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ReviewTab(total: stats.total, due: stats.due),
                  const VocabularyWordList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTab extends ConsumerWidget {
  const _ReviewTab({required this.total, required this.due});

  final int total;
  final int due;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    if (total == 0) {
      return const VocabularyEmptyState(kind: VocabularyEmptyKind.noWords);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(t.space24, t.space16, t.space24, t.space24),
      child: Column(
        children: [
          Expanded(
            child: due == 0
                ? const VocabularyEmptyState(kind: VocabularyEmptyKind.noDue)
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$due',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          SizedBox(height: t.space8),
                          Text(
                            l10n.vocabularyDue,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: SizedBox(
              width: double.infinity,
              child: EnjoyButton.primary(
                onPressed: () => _startReview(context, ref),
                child: Text(l10n.vocabularyStartReview),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startReview(BuildContext context, WidgetRef ref) async {
    final options = await showVocabularyReviewOptions(context);
    if (options == null || !context.mounted) return;
    final started = await ref
        .read(vocabularyReviewSessionProvider.notifier)
        .start(options);
    if (!context.mounted) return;
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.vocabularyEmptyQueue),
        ),
      );
      return;
    }
    await context.push('/vocabulary/review');
  }
}
