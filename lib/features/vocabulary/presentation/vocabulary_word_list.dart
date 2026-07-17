/// All Words list: filters, search, delete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/interaction/enjoy_tappable.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_list_controller.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_relative_review.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_l10n.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_empty_states.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class VocabularyWordList extends ConsumerWidget {
  const VocabularyWordList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final itemsAsync = ref.watch(vocabularyItemsProvider);
    final filters = ref.watch(vocabularyListFiltersProvider);

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (items) {
        if (items.isEmpty) {
          return const VocabularyEmptyState(kind: VocabularyEmptyKind.noWords);
        }

        final languages = items.map((i) => i.language).toSet().toList()..sort();
        final visible = filterVocabularyItems(items, filters);

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(t.space16, t.space8, t.space16, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.vocabularySearchPlaceholder,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => ref
                    .read(vocabularyListFiltersProvider.notifier)
                    .setQuery(v),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: t.space16,
                vertical: t.space8,
              ),
              child: Wrap(
                spacing: t.space8,
                runSpacing: t.space8,
                children: [
                  DropdownButton<VocabularyStatus?>(
                    value: filters.status,
                    hint: Text(l10n.vocabularyFilterStatus),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(l10n.vocabularyFilterAll),
                      ),
                      for (final s in VocabularyStatus.values)
                        DropdownMenuItem(
                          value: s,
                          child: Text(vocabularyStatusLabel(l10n, s)),
                        ),
                    ],
                    onChanged: (v) => ref
                        .read(vocabularyListFiltersProvider.notifier)
                        .setStatus(v),
                  ),
                  DropdownButton<String?>(
                    value: filters.language,
                    hint: Text(l10n.vocabularyFilterLanguage),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(l10n.vocabularyFilterAll),
                      ),
                      for (final lang in languages)
                        DropdownMenuItem(value: lang, child: Text(lang)),
                    ],
                    onChanged: (v) => ref
                        .read(vocabularyListFiltersProvider.notifier)
                        .setLanguage(v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? const VocabularyEmptyState(
                      kind: VocabularyEmptyKind.noMatches,
                    )
                  : ListView.separated(
                      padding: EdgeInsets.only(bottom: t.space24),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = visible[index];
                        return _WordRow(item: item);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _WordRow extends ConsumerWidget {
  const _WordRow({required this.item});

  final VocabularyItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final relative = relativeNextReviewLabel(
      nextReviewAt: item.nextReviewAt,
      now: DateTime.now(),
    );

    return ListTile(
      title: Text(item.word),
      subtitle: Text(
        [
          vocabularyStatusLabel(l10n, item.status),
          l10n.vocabularyContextsCount(item.contextsCount),
          l10n.vocabularyReviewsCount(item.reviewsCount),
          vocabularyRelativeLabel(l10n, relative),
          item.language,
        ].join(' · '),
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      trailing: EnjoyTappableIcon(
        icon: Icons.delete_outline,
        tooltip: l10n.vocabularyDelete,
        onPressed: () => _confirmDelete(context, ref),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: t.space16),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showEnjoyAlertDialog<bool>(
      context: context,
      title: Text(l10n.vocabularyConfirmDeleteTitle),
      content: Text(l10n.vocabularyConfirmDeleteBody),
      actionsBuilder: (ctx) => [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.vocabularyCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.vocabularyDelete),
        ),
      ],
    );
    if (confirmed != true) return;
    await ref.read(vocabularyRepositoryProvider).deleteItem(item.id);
  }
}
