/// Flashcard front/back with Context / Dictionary / Notes tabs.
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_tappable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class VocabularyFlashcard extends StatelessWidget {
  const VocabularyFlashcard({
    super.key,
    required this.item,
    required this.contextText,
    required this.flipped,
    required this.ratingInFlight,
    required this.onFlip,
    required this.onRate,
  });

  final VocabularyItem item;
  final String? contextText;
  final bool flipped;
  final bool ratingInFlight;
  final VoidCallback onFlip;
  final ValueChanged<VocabularyRating> onRate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    if (!flipped) {
      return EnjoyTappableSurface(
        borderRadius: BorderRadius.circular(t.radiusLg),
        onTap: onFlip,
        child: Padding(
          padding: EdgeInsets.all(t.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.word,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: t.space16),
              if (contextText != null && contextText!.isNotEmpty)
                Text(
                  contextText!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Text(
                  l10n.vocabularyNoContextAvailable,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              SizedBox(height: t.space24),
              Text(
                l10n.vocabularyFlipHint,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: l10n.vocabularyContext),
              Tab(text: l10n.vocabularyDictionary),
              Tab(text: l10n.vocabularyNotes),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TabBody(
                  child: Text(
                    (contextText == null || contextText!.isEmpty)
                        ? l10n.vocabularyNoContextAvailable
                        : contextText!,
                  ),
                ),
                _TabBody(child: _DictionaryBody(explanation: item.explanation)),
                _TabBody(child: Text(l10n.vocabularyNotesPlaceholder)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(t.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.vocabularyHowWellDoYouKnow,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: t.space12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: t.space8,
                  runSpacing: t.space8,
                  children: [
                    EnjoyButton.secondary(
                      onPressed: ratingInFlight
                          ? null
                          : () => onRate(VocabularyRating.dontKnow),
                      child: Text(l10n.vocabularyDontKnow),
                    ),
                    EnjoyButton.primary(
                      onPressed: ratingInFlight
                          ? null
                          : () => onRate(VocabularyRating.know),
                      child: Text(l10n.vocabularyKnow),
                    ),
                    EnjoyButton.secondary(
                      onPressed: ratingInFlight
                          ? null
                          : () => onRate(VocabularyRating.knowWell),
                      child: Text(l10n.vocabularyKnowWell),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(t.space16),
      child: child,
    );
  }
}

class _DictionaryBody extends StatelessWidget {
  const _DictionaryBody({required this.explanation});

  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (explanation == null || explanation!.isEmpty) {
      return Text(l10n.vocabularyDictionaryNotAvailable);
    }
    try {
      final json = jsonDecode(explanation!) as Map<String, dynamic>;
      final result = DictionaryResult.fromJson(json);
      final senses = result.senses
          .map((s) {
            final parts = <String>[s.definition];
            if (s.translation != null && s.translation!.isNotEmpty) {
              parts.add(s.translation!);
            }
            return parts.join(' — ');
          })
          .join('\n');
      final header = [
        if (result.ipa != null && result.ipa!.isNotEmpty) '/${result.ipa}/',
        if (result.lemma != null && result.lemma!.isNotEmpty) result.lemma!,
      ].join(' · ');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header.isNotEmpty) ...[
            Text(header, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
          ],
          Text(senses.isEmpty ? l10n.vocabularyDictionaryNotAvailable : senses),
        ],
      );
    } catch (_) {
      return Text(l10n.vocabularyDictionaryNotAvailable);
    }
  }
}
