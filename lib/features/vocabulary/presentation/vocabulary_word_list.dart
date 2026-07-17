/// All Words list: filters, search, delete.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_list_controller.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_relative_review.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_anki_export_dialog.dart';
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
      error: (_, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: l10n.vocabularyListLoadFailed,
        subtitle: l10n.vocabularyAiFetchFailed,
        action: () => ref.invalidate(vocabularyItemsProvider),
        actionLabel: l10n.retry,
      ),
      data: (items) {
        if (items.isEmpty) {
          return const VocabularyEmptyState(kind: VocabularyEmptyKind.noWords);
        }

        final languages = items.map((i) => i.language).toSet().toList()..sort();
        final visible = filterVocabularyItems(items, filters);

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(t.space24, t.space8, t.space24, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 520;
                  final search = TextField(
                    decoration: InputDecoration(
                      hintText: l10n.vocabularySearchPlaceholder,
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(t.radiusMd),
                      ),
                    ),
                    onChanged: (v) => ref
                        .read(vocabularyListFiltersProvider.notifier)
                        .setQuery(v),
                  );
                  final export = EnjoyButton.ghost(
                    icon: Icons.file_download_outlined,
                    onPressed: () => showVocabularyAnkiExportDialog(context),
                    child: Text(l10n.vocabularyExport),
                  );
                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        search,
                        SizedBox(height: t.space8),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: export,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: search),
                      SizedBox(width: t.space8),
                      export,
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                t.space24,
                t.space12,
                t.space24,
                t.space8,
              ),
              child: Wrap(
                spacing: t.space12,
                runSpacing: t.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _LabeledDropdown<VocabularyStatus?>(
                    label: l10n.vocabularyFilterStatus,
                    value: filters.status,
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
                  _LabeledDropdown<String?>(
                    label: l10n.vocabularyFilterLanguage,
                    value: filters.language,
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
                      padding: EdgeInsets.fromLTRB(
                        t.space16,
                        0,
                        t.space16,
                        t.space24,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.22),
                      ),
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

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(t.radiusMd),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: t.space12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: t.space8),
            DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                borderRadius: BorderRadius.circular(t.radiusMd),
              ),
            ),
          ],
        ),
      ),
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
    final tt = Theme.of(context).textTheme;
    final relative = relativeNextReviewLabel(
      nextReviewAt: item.nextReviewAt,
      now: DateTime.now(),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.space8, horizontal: t.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.word,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: t.space8),
                Wrap(
                  spacing: t.space8,
                  runSpacing: t.space4,
                  children: [
                    _MetaChip(label: vocabularyStatusLabel(l10n, item.status)),
                    _MetaChip(
                      label: l10n.vocabularyContextsCount(item.contextsCount),
                    ),
                    _MetaChip(
                      label: l10n.vocabularyReviewsCount(item.reviewsCount),
                    ),
                    _MetaChip(label: vocabularyRelativeLabel(l10n, relative)),
                    _MetaChip(label: item.language),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            onSelected: (value) {
              if (value == 'delete') {
                unawaited(_confirmDelete(context, ref));
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  l10n.vocabularyDelete,
                  style: TextStyle(color: cs.error),
                ),
              ),
            ],
          ),
        ],
      ),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(t.radiusFull),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: t.space8, vertical: t.space4),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}
