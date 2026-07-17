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
    final items = ref.watch(vocabularyItemsProvider).valueOrNull ?? const [];
    final languages = items.map((i) => i.language).toSet().toList()..sort();
    final selectedLanguage =
        _language ?? (languages.isEmpty ? null : languages.first);

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
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: t.space8),
            RadioGroup<VocabularyReviewMode>(
              groupValue: _mode,
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _mode = v;
                  _error = null;
                });
              },
              child: Column(
                children: [
                  RadioListTile<VocabularyReviewMode>(
                    value: VocabularyReviewMode.due,
                    title: Text(l10n.vocabularyReviewDueItems),
                  ),
                  RadioListTile<VocabularyReviewMode>(
                    value: VocabularyReviewMode.all,
                    title: Text(l10n.vocabularyReviewAll),
                  ),
                  RadioListTile<VocabularyReviewMode>(
                    value: VocabularyReviewMode.byStatus,
                    title: Text(l10n.vocabularyReviewByStatus),
                  ),
                  RadioListTile<VocabularyReviewMode>(
                    value: VocabularyReviewMode.byLanguage,
                    title: Text(l10n.vocabularyReviewByLanguage),
                  ),
                  RadioListTile<VocabularyReviewMode>(
                    value: VocabularyReviewMode.random,
                    title: Text(l10n.vocabularyReviewRandom),
                  ),
                ],
              ),
            ),
            if (_mode == VocabularyReviewMode.byStatus) ...[
              SizedBox(height: t.space8),
              DropdownButton<VocabularyStatus>(
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
            ],
            if (_mode == VocabularyReviewMode.byLanguage &&
                selectedLanguage != null) ...[
              SizedBox(height: t.space8),
              DropdownButton<String>(
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
            ],
            if (_mode == VocabularyReviewMode.random) ...[
              SizedBox(height: t.space8),
              Row(
                children: [
                  Expanded(child: Text(l10n.vocabularyNumberOfWords)),
                  SizedBox(
                    width: 72,
                    child: TextFormField(
                      initialValue: '$_randomCount',
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null && n > 0) {
                          setState(() => _randomCount = n);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              SizedBox(height: t.space8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            SizedBox(height: t.space16),
            EnjoyButton.primary(
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
          ],
        ),
      ),
    );
  }
}
