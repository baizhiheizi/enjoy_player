/// Vocabulary destination: stats + Review / All Words tabs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: EnjoyPage(
        kind: EnjoyPageKind.hub,
        title: l10n.vocabularyTitle,
        showBack: true,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/profile');
          }
        },
        body: (context, metrics) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: metrics.padding(top: t.space12),
              child: VocabularyStatsStrip(stats: stats),
            ),
            Padding(
              padding: metrics.padding(top: t.space12, bottom: t.space8),
              child: Material(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(t.radiusMd),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(t.radiusSm),
                  ),
                  labelColor: cs.onSurface,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  labelStyle: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: tt.labelLarge,
                  tabs: [
                    Tab(height: 40, text: l10n.vocabularyReview),
                    Tab(height: 40, text: l10n.vocabularyAllWords),
                  ],
                ),
              ),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (total == 0) {
      return const VocabularyEmptyState(kind: VocabularyEmptyKind.noWords);
    }

    if (due == 0) {
      return VocabularyEmptyState(
        kind: VocabularyEmptyKind.noDue,
        action: () => _startReview(context, ref),
        actionLabel: l10n.vocabularyCustomReview,
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(t.space24),
        child: EnjoyCard(
          padding: EdgeInsets.all(t.space32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$due',
                  style: tt.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    color: cs.primary,
                  ),
                ),
                SizedBox(height: t.space8),
                Text(
                  l10n.vocabularyDue,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: t.space24),
                SizedBox(
                  width: double.infinity,
                  child: EnjoyButton.primary(
                    onPressed: () => _startReview(context, ref),
                    child: Text(l10n.vocabularyStartReview),
                  ),
                ),
              ],
            ),
          ),
        ),
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
