/// All Words (the `Vocabulary` board): search + status / language filters
/// and the word table — word, its first context, status chip, next review,
/// language, delete.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/presentation/language_labels.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_list_controller.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_relative_review.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_l10n.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const double _kSearchWidth = 280;
const double _kToolbarHeight = 36;
const double _kCompactRowBelow = 600;

Color vocabularyStatusColor(EnjoyThemeTokens t, VocabularyStatus status) =>
    switch (status) {
      VocabularyStatus.new_ => t.vocabNew,
      VocabularyStatus.learning => t.vocabLearning,
      VocabularyStatus.reviewing => t.vocabReviewing,
      VocabularyStatus.mastered => t.vocabMastered,
    };

/// Search field and the Status / Language filter buttons.
class VocabularyWordToolbar extends ConsumerWidget {
  const VocabularyWordToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final filters = ref.watch(vocabularyListFiltersProvider);
    final languages = ref.watch(vocabularyListLanguagesProvider);
    final ctrl = ref.read(vocabularyListFiltersProvider.notifier);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: _kSearchWidth,
          height: _kToolbarHeight,
          child: TextField(
            style: tt.bodyMedium?.copyWith(fontSize: 14, color: t.ink),
            textInputAction: TextInputAction.search,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: l10n.vocabularySearchPlaceholder,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              prefixIcon: Icon(EnjoyIcons.search, size: 16, color: t.ink3),
              prefixIconConstraints: const BoxConstraints(minWidth: 36),
            ),
            onChanged: ctrl.setQuery,
          ),
        ),
        _FilterMenu<VocabularyStatus?>(
          label: l10n.vocabularyFilterStatus,
          value: filters.status,
          entries: [
            (null, l10n.vocabularyFilterAll),
            for (final s in VocabularyStatus.values)
              (s, vocabularyStatusLabel(l10n, s)),
          ],
          onChanged: ctrl.setStatus,
        ),
        _FilterMenu<String?>(
          label: l10n.vocabularyFilterLanguage,
          value: filters.language,
          entries: [
            (null, l10n.vocabularyFilterAll),
            for (final lang in languages) (lang, languageCodeLabel(lang)),
          ],
          onChanged: ctrl.setLanguage,
        ),
      ],
    );
  }
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.entries,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<(T, String)> entries;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final current = entries
        .firstWhere((e) => e.$1 == value, orElse: () => entries.first)
        .$2;
    return MenuAnchor(
      menuChildren: [
        for (final entry in entries)
          MenuItemButton(
            onPressed: () => onChanged(entry.$1),
            child: Text(entry.$2),
          ),
      ],
      builder: (context, controller, _) => EnjoyPressable(
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: _kToolbarHeight,
          padding: const EdgeInsets.only(left: 12, right: 9),
          decoration: ShapeDecoration(
            color: t.paper,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(11),
              side: BorderSide(color: t.line),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.vocabularyFilterValue(label, current),
                style: tt.labelMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.ink2,
                ),
              ),
              const SizedBox(width: 6),
              Icon(EnjoyIcons.chevronDown, size: 14, color: t.ink3),
            ],
          ),
        ),
      ),
    );
  }
}

class VocabularyWordRow extends ConsumerWidget {
  const VocabularyWordRow({super.key, required this.item, this.last = false});

  final VocabularyItem item;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final context0 = ref.watch(vocabularyFirstContextProvider(item.id)).value;
    final relative = relativeNextReviewLabel(
      nextReviewAt: item.nextReviewAt,
      now: DateTime.now(),
    );
    final urgent =
        relative is RelativeNextReviewOverdue ||
        relative is RelativeNextReviewToday;

    final word = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.word,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: enjoyDisplayStyle(
            context,
            size: 20,
            color: t.ink,
            height: 1.2,
          ),
        ),
        if (context0 != null && context0.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            context0,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(fontSize: 13, color: t.ink3),
          ),
        ],
      ],
    );
    final due = Text(
      vocabularyRelativeLabel(l10n, relative),
      style: tt.bodySmall?.copyWith(
        fontSize: 13,
        color: relative is RelativeNextReviewOverdue
            ? t.youInk
            : urgent
            ? t.ink
            : t.ink3,
        fontWeight: urgent ? FontWeight.w600 : FontWeight.w400,
      ),
    );
    final delete = Tooltip(
      message: l10n.vocabularyDelete,
      child: EnjoyPressable(
        onTap: () => unawaited(_confirmDelete(context, ref)),
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(EnjoyIcons.delete, size: 17, color: t.ink3),
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: t.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 16, 14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < _kCompactRowBelow) {
              return Row(
                children: [
                  Expanded(child: word),
                  const SizedBox(width: 16),
                  due,
                  delete,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: word),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _StatusChip(status: item.status),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(width: 110, child: due),
                const SizedBox(width: 16),
                SizedBox(
                  width: 54,
                  child: Text(
                    languageCodeLabel(item.language),
                    style: enjoyMonoStyle(
                      context,
                      size: 11,
                      weight: FontWeight.w600,
                      color: t.ink3,
                    ),
                  ),
                ),
                delete,
              ],
            );
          },
        ),
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
        EnjoyButton.ghost(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.vocabularyCancel),
        ),
        EnjoyButton.destructive(
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
  const _StatusChip({required this.status});

  final VocabularyStatus status;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: ShapeDecoration(color: t.sunk, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: vocabularyStatusColor(t, status),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            vocabularyStatusLabel(l10n, status),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: t.ink2,
            ),
          ),
        ],
      ),
    );
  }
}
