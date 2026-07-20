/// Review options sheet: due / all / status / language / random.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_l10n.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Shows review options; returns selected [ReviewSelectionOptions] or null.
Future<ReviewSelectionOptions?> showVocabularyReviewOptions(
  BuildContext context,
) {
  return showEnjoySheet<ReviewSelectionOptions>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const VocabularyReviewOptionsSheet(),
  );
}

class VocabularyReviewOptionsSheet extends ConsumerStatefulWidget {
  const VocabularyReviewOptionsSheet({super.key});

  @override
  ConsumerState<VocabularyReviewOptionsSheet> createState() =>
      _VocabularyReviewOptionsSheetState();
}

class _VocabularyReviewOptionsSheetState
    extends ConsumerState<VocabularyReviewOptionsSheet> {
  VocabularyReviewMode _mode = VocabularyReviewMode.due;
  VocabularyStatus _status = VocabularyStatus.new_;
  String? _language;
  int _randomCount = 20;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final items = ref.watch(vocabularyItemsProvider).valueOrNull ?? const [];
    final languages = items.map((i) => i.language).toSet().toList()..sort();
    final selectedLanguage =
        _language ?? (languages.isEmpty ? null : languages.first);

    final previewCount = buildVocabularySessionQueue(
      items: items,
      options: ReviewSelectionOptions(
        mode: _mode,
        status: _mode == VocabularyReviewMode.byStatus ? _status : null,
        language: _mode == VocabularyReviewMode.byLanguage
            ? selectedLanguage
            : null,
        randomCount: _randomCount,
      ),
      now: DateTime.now(),
    ).length;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        t.space24,
        t.space16,
        t.space24,
        t.space24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.vocabularySelectReviewItems,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: t.space4),
            Text(
              l10n.vocabularyQueueCount(previewCount),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            SizedBox(height: t.space16),
            for (final mode in VocabularyReviewMode.values) ...[
              _ModeTile(
                selected: _mode == mode,
                title: _titleFor(l10n, mode),
                subtitle: _hintFor(l10n, mode),
                onTap: () => setState(() {
                  _mode = mode;
                  _error = null;
                }),
              ),
              SizedBox(height: t.space8),
            ],
            if (_mode == VocabularyReviewMode.byStatus) ...[
              InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.vocabularyFilterStatus,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(t.radiusMd),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<VocabularyStatus>(
                    isExpanded: true,
                    value: _status,
                    items: [
                      for (final s in VocabularyStatus.values)
                        DropdownMenuItem(
                          value: s,
                          child: Text(vocabularyStatusLabel(l10n, s)),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _status = v);
                    },
                  ),
                ),
              ),
              SizedBox(height: t.space12),
            ],
            if (_mode == VocabularyReviewMode.byLanguage &&
                selectedLanguage != null) ...[
              InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.vocabularyFilterLanguage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(t.radiusMd),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedLanguage,
                    items: [
                      for (final lang in languages)
                        DropdownMenuItem(value: lang, child: Text(lang)),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _language = v);
                    },
                  ),
                ),
              ),
              SizedBox(height: t.space12),
            ],
            if (_mode == VocabularyReviewMode.random) ...[
              TextFormField(
                initialValue: '$_randomCount',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.vocabularyNumberOfWords,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(t.radiusMd),
                  ),
                ),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n > 0) {
                    setState(() => _randomCount = n);
                  }
                },
              ),
              SizedBox(height: t.space12),
            ],
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: cs.error)),
              SizedBox(height: t.space8),
            ],
            SizedBox(
              height: 48,
              child: EnjoyButton.primary(
                onPressed: () {
                  final options = ReviewSelectionOptions(
                    mode: _mode,
                    status: _mode == VocabularyReviewMode.byStatus
                        ? _status
                        : null,
                    language: _mode == VocabularyReviewMode.byLanguage
                        ? selectedLanguage
                        : null,
                    randomCount: _randomCount,
                  );
                  final queue = buildVocabularySessionQueue(
                    items: items,
                    options: options,
                    now: DateTime.now(),
                  );
                  if (queue.isEmpty) {
                    setState(() => _error = l10n.vocabularyEmptyQueue);
                    return;
                  }
                  Navigator.of(context).pop(options);
                },
                child: Text(l10n.vocabularyStartReview),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleFor(AppLocalizations l10n, VocabularyReviewMode mode) {
    return switch (mode) {
      VocabularyReviewMode.due => l10n.vocabularyReviewDueItems,
      VocabularyReviewMode.all => l10n.vocabularyReviewAll,
      VocabularyReviewMode.byStatus => l10n.vocabularyReviewByStatus,
      VocabularyReviewMode.byLanguage => l10n.vocabularyReviewByLanguage,
      VocabularyReviewMode.random => l10n.vocabularyReviewRandom,
    };
  }

  String _hintFor(AppLocalizations l10n, VocabularyReviewMode mode) {
    return switch (mode) {
      VocabularyReviewMode.due => l10n.vocabularyReviewDueHint,
      VocabularyReviewMode.all => l10n.vocabularyReviewAllHint,
      VocabularyReviewMode.byStatus => l10n.vocabularyReviewByStatusHint,
      VocabularyReviewMode.byLanguage => l10n.vocabularyReviewByLanguageHint,
      VocabularyReviewMode.random => l10n.vocabularyReviewRandomHint,
    };
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? cs.primaryContainer.withValues(alpha: 0.45)
          : cs.surfaceContainerHighest.withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusMd),
        side: BorderSide(
          color: selected
              ? cs.primary.withValues(alpha: 0.55)
              : cs.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(t.space16),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              SizedBox(width: t.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: t.space4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
