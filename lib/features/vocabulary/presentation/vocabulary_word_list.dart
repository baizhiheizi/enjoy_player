/// All Words list: filters, search, delete.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_list_controller.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_relative_review.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_anki_export_dialog.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_l10n.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_empty_states.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class VocabularyWordList extends ConsumerStatefulWidget {
  const VocabularyWordList({super.key, required this.metrics});

  final EnjoyPageMetrics metrics;

  @override
  ConsumerState<VocabularyWordList> createState() => _VocabularyWordListState();
}

class _VocabularyWordListState extends ConsumerState<VocabularyWordList> {
  bool _filtersOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final itemsAsync = ref.watch(vocabularyItemsProvider);
    final filters = ref.watch(vocabularyListFiltersProvider);
    final gutter = widget.metrics.horizontalInset;
    final filtersActive = filters.status != null || filters.language != null;
    final showFilters = _filtersOpen || filtersActive;

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
              padding: EdgeInsets.fromLTRB(gutter, t.space4, gutter, 0),
              child: _SearchToolbar(
                filtersOpen: showFilters,
                filtersActive: filtersActive,
                onQueryChanged: (v) => ref
                    .read(vocabularyListFiltersProvider.notifier)
                    .setQuery(v),
                onToggleFilters: () =>
                    setState(() => _filtersOpen = !_filtersOpen),
                onExport: () => showVocabularyAnkiExportDialog(context),
              ),
            ),
            AnimatedSize(
              duration: t.motionStandard,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: showFilters
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        t.space8,
                        gutter,
                        t.space4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _LabeledDropdown<VocabularyStatus?>(
                              label: l10n.vocabularyFilterStatus,
                              value: filters.status,
                              entries: [
                                (null, l10n.vocabularyFilterAll),
                                for (final s in VocabularyStatus.values)
                                  (s, vocabularyStatusLabel(l10n, s)),
                              ],
                              onChanged: (v) => ref
                                  .read(vocabularyListFiltersProvider.notifier)
                                  .setStatus(v),
                            ),
                          ),
                          SizedBox(width: t.space8),
                          Expanded(
                            child: _LabeledDropdown<String?>(
                              label: l10n.vocabularyFilterLanguage,
                              value: filters.language,
                              entries: [
                                (null, l10n.vocabularyFilterAll),
                                for (final lang in languages) (lang, lang),
                              ],
                              onChanged: (v) => ref
                                  .read(vocabularyListFiltersProvider.notifier)
                                  .setLanguage(v),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: visible.isEmpty
                  ? const VocabularyEmptyState(
                      kind: VocabularyEmptyKind.noMatches,
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        t.space4,
                        gutter,
                        t.space24,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.18),
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

class _SearchToolbar extends StatelessWidget {
  const _SearchToolbar({
    required this.filtersOpen,
    required this.filtersActive,
    required this.onQueryChanged,
    required this.onToggleFilters,
    required this.onExport,
  });

  final bool filtersOpen;
  final bool filtersActive;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onToggleFilters;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final filterColor = filtersOpen || filtersActive
        ? cs.primary
        : cs.onSurfaceVariant;

    return Row(
      children: [
        Expanded(
          child: TextField(
            style: tt.bodyMedium,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.vocabularySearchPlaceholder,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: t.space12,
                vertical: t.space8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(t.radiusMd),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(t.radiusMd),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(t.radiusMd),
                borderSide: BorderSide(
                  color: cs.primary.withValues(alpha: 0.45),
                ),
              ),
            ),
            onChanged: onQueryChanged,
          ),
        ),
        SizedBox(width: t.space8),
        IconButton.filledTonal(
          tooltip: l10n.vocabularyFilters,
          onPressed: onToggleFilters,
          icon: Badge(
            isLabelVisible: filtersActive,
            smallSize: 8,
            child: Icon(Icons.filter_list_rounded, color: filterColor),
          ),
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: filtersOpen || filtersActive
                ? cs.primaryContainer.withValues(alpha: 0.55)
                : cs.surfaceContainerHighest.withValues(alpha: 0.45),
          ),
        ),
        SizedBox(width: t.space4),
        IconButton.filledTonal(
          tooltip: l10n.vocabularyExport,
          onPressed: onExport,
          icon: Icon(Icons.file_download_outlined, color: cs.onSurfaceVariant),
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.entries,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<(T, String)> entries;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final menuPad = EdgeInsets.symmetric(horizontal: t.space16);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: t.space12),
        child: Row(
          children: [
            Text(
              label,
              style: tt.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: t.space8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  isExpanded: true,
                  isDense: true,
                  borderRadius: BorderRadius.circular(t.radiusMd),
                  padding: EdgeInsets.symmetric(vertical: t.space8),
                  style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                  iconSize: 20,
                  menuMaxHeight: 320,
                  selectedItemBuilder: (context) => [
                    for (final entry in entries)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(entry.$2),
                      ),
                  ],
                  items: [
                    for (final entry in entries)
                      DropdownMenuItem<T>(
                        value: entry.$1,
                        child: Padding(padding: menuPad, child: Text(entry.$2)),
                      ),
                  ],
                  onChanged: onChanged,
                ),
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
    final metaLine = [
      l10n.vocabularyContextsCount(item.contextsCount),
      l10n.vocabularyReviewsCount(item.reviewsCount),
      vocabularyRelativeLabel(l10n, relative),
    ].join(' · ');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.space12),
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
                SizedBox(height: t.space4),
                Row(
                  children: [
                    _StatusChip(
                      label: vocabularyStatusLabel(l10n, item.status),
                    ),
                    SizedBox(width: t.space8),
                    Expanded(
                      child: Text(
                        metaLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: t.space8),
          Padding(
            padding: EdgeInsets.only(top: t.space4),
            child: Text(
              item.language,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(t.radiusMd),
            ),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(t.radiusFull),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: t.space8, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
