/// Vocabulary (the `Vocabulary` board): header with Export to Anki and
/// Review due, the due card beside the status breakdown, then All Words
/// (search, filters, word table) or Review (due card + custom review).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_segmented_control.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_anki_export_dialog.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_word_list.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_empty_states.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_review_launch.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_review_tab.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_stats_cards.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

enum _VocabularyTab { words, review }

const double _kPhoneBelow = 600;

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
              sliver: SliverToBoxAdapter(
                child: VocabularyStatsRow(stats: stats),
              ),
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
                sliver: SliverToBoxAdapter(
                  child: VocabularyReviewTab(stats: stats),
                ),
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
