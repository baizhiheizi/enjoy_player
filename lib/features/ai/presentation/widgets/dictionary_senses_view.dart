import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/colors.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/ipa_formatter.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';

/// Renders one dictionary entry's IPA / lemma header and its senses.
///
/// Shared by the Lookup sheet and the vocabulary flashcard so the same entry
/// looks the same on both surfaces. [lemmaLabel] is the localized label
/// prefixed to a lemma that differs from the headword; the flashcard passes
/// `null` because the card already shows the word above the tab.
class DictionarySensesView extends StatelessWidget {
  const DictionarySensesView({
    super.key,
    required this.result,
    this.lemmaLabel,
  });

  final DictionaryResult result;
  final String? lemmaLabel;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final t = EnjoyThemeTokens.of(context);
    final lemmaTrim = result.lemma?.trim();
    final showLemma =
        lemmaTrim != null &&
        lemmaTrim.isNotEmpty &&
        lemmaTrim != result.word.trim();
    final ipa = result.ipa == null ? '' : formatIpaWithSlashes(result.ipa!);
    final hasIpa = ipa.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasIpa || showLemma) ...[
          Wrap(
            spacing: t.space8,
            runSpacing: t.space4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (hasIpa)
                Text(
                  ipa,
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              if (showLemma)
                Text(
                  lemmaLabel == null ? lemmaTrim : '$lemmaLabel · $lemmaTrim',
                  style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
            ],
          ),
          SizedBox(height: t.space16),
        ],
        for (var i = 0; i < result.senses.length; i++) ...[
          if (i > 0) ...[
            SizedBox(height: t.space12),
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.18),
            ),
            SizedBox(height: t.space12),
          ],
          DictionarySenseTile(sense: result.senses[i]),
        ],
      ],
    );
  }
}

/// Renders one [DictionarySense]: part of speech, definition, translation,
/// examples, and notes.
class DictionarySenseTile extends StatelessWidget {
  const DictionarySenseTile({super.key, required this.sense});

  final DictionarySense sense;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final t = EnjoyThemeTokens.of(context);
    final pos = sense.partOfSpeech?.trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final translationColor = isDark ? AppColors.brandOnDark : scheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pos != null && pos.isNotEmpty) ...[
          Text(
            pos,
            style: tt.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: t.space4),
        ],
        if (sense.definition.trim().isNotEmpty)
          SelectableText(
            sense.definition,
            style: tt.bodyMedium?.copyWith(height: 1.45),
          ),
        if (sense.translation != null &&
            sense.translation!.trim().isNotEmpty) ...[
          SizedBox(height: t.space4),
          SelectableText(
            sense.translation!,
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: translationColor,
              height: 1.4,
            ),
          ),
        ],
        if (sense.examples != null && sense.examples!.isNotEmpty) ...[
          SizedBox(height: t.space12),
          for (final ex in sense.examples!)
            Padding(
              padding: EdgeInsets.only(bottom: t.space8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: 2,
                      color: scheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                padding: EdgeInsetsDirectional.only(start: t.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      ex.source,
                      style: tt.bodySmall?.copyWith(
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (ex.target != null && ex.target!.trim().isNotEmpty) ...[
                      SizedBox(height: t.space4),
                      SelectableText(
                        ex.target!,
                        style: tt.bodySmall?.copyWith(
                          height: 1.4,
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
        if (sense.notes != null && sense.notes!.trim().isNotEmpty) ...[
          SizedBox(height: t.space4),
          Text(
            sense.notes!,
            style: tt.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
