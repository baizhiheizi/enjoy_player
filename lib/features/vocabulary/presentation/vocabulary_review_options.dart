/// Custom review panel (the `Vocabulary` board's Review tab): pick a review
/// mode — due / all / status / language / random — then start.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_l10n.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const int _kMinRandomCount = 1;
const int _kMaxRandomCount = 200;

class VocabularyCustomReview extends ConsumerStatefulWidget {
  const VocabularyCustomReview({super.key, required this.onStart});

  /// Called with a selection whose queue is non-empty.
  final ValueChanged<ReviewSelectionOptions> onStart;

  @override
  ConsumerState<VocabularyCustomReview> createState() =>
      _VocabularyCustomReviewState();
}

class _VocabularyCustomReviewState
    extends ConsumerState<VocabularyCustomReview> {
  VocabularyReviewMode _mode = VocabularyReviewMode.due;
  VocabularyStatus _status = VocabularyStatus.new_;
  String? _language;
  int _randomCount = 20;
  String? _error;

  ReviewSelectionOptions _options(
    VocabularyReviewMode mode,
    String? language,
  ) => ReviewSelectionOptions(
    mode: mode,
    status: mode == VocabularyReviewMode.byStatus ? _status : null,
    language: mode == VocabularyReviewMode.byLanguage ? language : null,
    randomCount: _randomCount,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final items = ref.watch(vocabularyItemsProvider).valueOrNull ?? const [];
    final languages = items.map((i) => i.language).toSet().toList()..sort();
    final selectedLanguage =
        _language ?? (languages.isEmpty ? null : languages.first);
    final now = DateTime.now();
    int queueLength(VocabularyReviewMode mode) => buildVocabularySessionQueue(
      items: items,
      options: _options(mode, selectedLanguage),
      now: now,
    ).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                l10n.vocabularyCustomReview,
                style: enjoyDisplayStyle(context, size: 21, color: t.ink),
              ),
            ),
            Text(
              l10n.vocabularySelectReviewItems,
              style: tt.bodySmall?.copyWith(fontSize: 12.5, color: t.ink3),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final mode in VocabularyReviewMode.values) ...[
          _ModeTile(
            selected: _mode == mode,
            title: _titleFor(l10n, mode),
            subtitle: _hintFor(l10n, mode),
            count: switch (mode) {
              VocabularyReviewMode.due ||
              VocabularyReviewMode.all => queueLength(mode),
              _ => null,
            },
            onTap: () => setState(() {
              _mode = mode;
              _error = null;
            }),
          ),
          const SizedBox(height: 8),
        ],
        if (_mode == VocabularyReviewMode.byStatus)
          _ChoiceRow<VocabularyStatus>(
            label: l10n.vocabularyFilterStatus,
            value: _status,
            entries: [
              for (final s in VocabularyStatus.values)
                (s, vocabularyStatusLabel(l10n, s)),
            ],
            onChanged: (v) => setState(() => _status = v),
          ),
        if (_mode == VocabularyReviewMode.byLanguage &&
            selectedLanguage != null)
          _ChoiceRow<String>(
            label: l10n.vocabularyFilterLanguage,
            value: selectedLanguage,
            entries: [for (final lang in languages) (lang, lang)],
            onChanged: (v) => setState(() => _language = v),
          ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!, style: tt.bodySmall?.copyWith(color: t.danger)),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            if (_mode == VocabularyReviewMode.random) ...[
              Text(
                l10n.vocabularyNumberOfWords,
                style: tt.bodyMedium?.copyWith(fontSize: 13.5, color: t.ink2),
              ),
              const SizedBox(width: 10),
              _CountStepper(
                value: _randomCount,
                onChanged: (v) => setState(() => _randomCount = v),
              ),
            ],
            const Spacer(),
            EnjoyButton.secondary(
              onPressed: () {
                final options = _options(_mode, selectedLanguage);
                final queue = buildVocabularySessionQueue(
                  items: items,
                  options: options,
                  now: DateTime.now(),
                );
                if (queue.isEmpty) {
                  setState(() => _error = l10n.vocabularyEmptyQueue);
                  return;
                }
                widget.onStart(options);
              },
              child: Text(l10n.vocabularyStartReview),
            ),
          ],
        ),
      ],
    );
  }

  String _titleFor(AppLocalizations l10n, VocabularyReviewMode mode) =>
      switch (mode) {
        VocabularyReviewMode.due => l10n.vocabularyReviewDueItems,
        VocabularyReviewMode.all => l10n.vocabularyReviewAll,
        VocabularyReviewMode.byStatus => l10n.vocabularyReviewByStatus,
        VocabularyReviewMode.byLanguage => l10n.vocabularyReviewByLanguage,
        VocabularyReviewMode.random => l10n.vocabularyReviewRandom,
      };

  String _hintFor(AppLocalizations l10n, VocabularyReviewMode mode) =>
      switch (mode) {
        VocabularyReviewMode.due => l10n.vocabularyReviewDueHint,
        VocabularyReviewMode.all => l10n.vocabularyReviewAllHint,
        VocabularyReviewMode.byStatus => l10n.vocabularyReviewByStatusHint,
        VocabularyReviewMode.byLanguage => l10n.vocabularyReviewByLanguageHint,
        VocabularyReviewMode.random => l10n.vocabularyReviewRandomHint,
      };
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(t.radiusTile);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: EnjoyPressable(
        onTap: onTap,
        borderRadius: radius,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: selected ? t.brandSoft : Colors.transparent,
            shape: RoundedSuperellipseBorder(
              borderRadius: radius,
              side: BorderSide(color: selected ? t.brandInk : t.line),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? t.brandInk : t.line,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t.brandInk,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: tt.titleSmall?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: t.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: tt.bodySmall?.copyWith(
                          fontSize: 12.5,
                          color: t.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: enjoyMonoStyle(context, size: 12.5, color: t.ink3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
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
    final t = EnjoyThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, isDense: true),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            isDense: true,
            value: value,
            borderRadius: BorderRadius.circular(t.radiusControl),
            items: [
              for (final entry in entries)
                DropdownMenuItem<T>(value: entry.$1, child: Text(entry.$2)),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    Widget step(String label, String glyph, int next) {
      final enabled = next >= _kMinRandomCount && next <= _kMaxRandomCount;
      return Semantics(
        button: true,
        label: label,
        enabled: enabled,
        excludeSemantics: true,
        child: EnjoyPressable(
          onTap: enabled ? () => onChanged(next) : null,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Center(
              child: Text(
                glyph,
                style: TextStyle(
                  fontSize: 16,
                  color: enabled ? t.ink2 : t.ink3,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(11),
          side: BorderSide(color: t.line),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          step(l10n.vocabularyFewer, '−', value - 1),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: enjoyMonoStyle(context, size: 13.5, color: t.ink),
            ),
          ),
          step(l10n.vocabularyMore, '+', value + 1),
        ],
      ),
    );
  }
}
