/// Vocabulary (the `Vocabulary` board): header with Export to Anki and
/// Review due, the due card beside the status breakdown, then All Words
/// (search, filters, word table) or Review (due card + custom review).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_logo.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_segmented_control.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_stats.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_anki_export_dialog.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_l10n.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_review_options.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_word_list.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_empty_states.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

enum _VocabularyTab { words, review }

const int _kSecondsPerCard = 15;
const double _kStatsSplitMinWidth = 856;
const double _kPhoneBelow = 600;

int vocabularyReviewMinutes(int due) =>
    due <= 0 ? 0 : (due * _kSecondsPerCard / 60).ceil();

Future<void> startVocabularyReview(
  BuildContext context,
  WidgetRef ref,
  ReviewSelectionOptions options,
) async {
  final started = await ref
      .read(vocabularyReviewSessionProvider.notifier)
      .start(options);
  if (!context.mounted) return;
  if (!started) {
    AppNotice.info(context, AppLocalizations.of(context)!.vocabularyEmptyQueue);
    return;
  }
  await context.push('/vocabulary/review');
}

class VocabularyScreen extends ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  _VocabularyTab _tab = _VocabularyTab.words;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = ref.watch(vocabularyStatsProvider);
    final itemsAsync = ref.watch(vocabularyItemsProvider);

    return EnjoyPage(
      kind: EnjoyPageKind.browse,
      body: (context, metrics) {
        final inset = metrics.horizontalInset;
        final phone = metrics.paneWidth < _kPhoneBelow;
        final visible = ref.watch(vocabularyVisibleItemsProvider);

        final List<Widget> content;
        if (itemsAsync.isLoading && itemsAsync.valueOrNull == null) {
          content = const [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          ];
        } else if (stats.total == 0) {
          content = const [
            SliverFillRemaining(
              hasScrollBody: false,
              child: VocabularyEmptyState(kind: VocabularyEmptyKind.noWords),
            ),
          ];
        } else {
          content = [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, 30, inset, 0),
              sliver: SliverToBoxAdapter(child: _StatsRow(stats: stats)),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, 32, inset, 16),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    EnjoySegmentedControl<_VocabularyTab>(
                      segments: [
                        EnjoySegment(
                          value: _VocabularyTab.words,
                          label: l10n.vocabularyAllWords,
                        ),
                        EnjoySegment(
                          value: _VocabularyTab.review,
                          label: l10n.vocabularyReview,
                        ),
                      ],
                      value: _tab,
                      onChanged: (v) => setState(() => _tab = v),
                    ),
                    if (_tab == _VocabularyTab.words)
                      const VocabularyWordToolbar(),
                  ],
                ),
              ),
            ),
            if (_tab == _VocabularyTab.words)
              ..._wordSlivers(visible, inset)
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: inset),
                sliver: SliverToBoxAdapter(child: _ReviewTab(stats: stats)),
              ),
          ];
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: EditorialHeader(
                widthMode: EditorialHeaderWidthMode.browse,
                overline: l10n.vocabularyOverline,
                title: l10n.vocabularyTitle,
                trailing: _HeaderActions(due: stats.due, compact: phone),
              ),
            ),
            ...content,
            const SliverToBoxAdapter(child: SizedBox(height: 72)),
          ],
        );
      },
    );
  }

  List<Widget> _wordSlivers(List<VocabularyItem> visible, double inset) {
    if (visible.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 320,
            child: VocabularyEmptyState(kind: VocabularyEmptyKind.noMatches),
          ),
        ),
      ];
    }
    final t = EnjoyThemeTokens.of(context);
    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: inset),
        sliver: DecoratedSliver(
          decoration: ShapeDecoration(
            color: t.paper,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(t.radiusCard),
              side: BorderSide(color: t.line),
            ),
          ),
          sliver: SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) => VocabularyWordRow(
              key: ValueKey<String>('vocab-${visible[index].id}'),
              item: visible[index],
              last: index == visible.length - 1,
            ),
          ),
        ),
      ),
    ];
  }
}

class _HeaderActions extends ConsumerWidget {
  const _HeaderActions({required this.due, required this.compact});

  final int due;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          EnjoyButton.secondary(
            icon: EnjoyIcons.download,
            onPressed: () => showVocabularyAnkiExportDialog(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.vocabularyExportToAnki),
                const SizedBox(width: 8),
                Container(
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    gradient: t.brand,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    l10n.vocabularyProBadge,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (due > 0)
          EnjoyButton.brand(
            onPressed: () => startVocabularyReview(
              context,
              ref,
              const ReviewSelectionOptions(mode: VocabularyReviewMode.due),
            ),
            child: Text(l10n.vocabularyReviewDueAction(due)),
          ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final VocabularyStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final due = _DueCard(stats: stats);
        final breakdown = _StatusCard(stats: stats);
        if (constraints.maxWidth < _kStatsSplitMinWidth) {
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
                      vocabularyReviewMinutes(stats.due),
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

class _ReviewTab extends ConsumerWidget {
  const _ReviewTab({required this.stats});

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
        if (constraints.maxWidth < _kStatsSplitMinWidth) {
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
