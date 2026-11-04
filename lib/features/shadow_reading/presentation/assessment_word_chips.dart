/// The per-word assessment chip row presentation: the color legend for the
/// four chip states and the tappable [WordChip] with score coloring, error
/// text decoration, and karaoke current-word highlight.
library;

import 'package:azure_speech/azure_speech.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'score_level.dart';

/// Key for the word chip colors: the three score hues plus omitted words.
class AssessmentWordLegend extends StatelessWidget {
  const AssessmentWordLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(fontSize: 11.5, color: t.ink3);

    Widget entry(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: style),
      ],
    );

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        entry(t.scoreGood, l10n.assessmentLevelGood),
        entry(t.scoreWarn, l10n.assessmentLevelFair),
        entry(t.scoreBad, l10n.assessmentLevelPoor),
        entry(t.ink3, l10n.assessmentErrorTypeOmission),
      ],
    );
  }
}

class WordChip extends StatelessWidget {
  const WordChip({
    required this.word,
    required this.selected,
    required this.karaokeCurrent,
    required this.scheme,
    required this.onTap,
    super.key,
  });

  final AzureWordAssessment word;
  final bool selected;
  final bool karaokeCurrent;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final pa = word.pronunciationAssessment;
    final err = pa.errorType;
    final omitted = err == 'Omission';
    final level = assessmentScoreLevel(pa.accuracyScore);
    final fg = karaokeCurrent
        ? t.originalInk
        : omitted
        ? t.ink3
        : assessmentScoreColor(t, level);
    final bg = karaokeCurrent
        ? t.originalSoft
        : omitted
        ? t.sunk
        : assessmentScoreBackground(t, level);

    return EnjoyPressable(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: t.motionFast,
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
        decoration: ShapeDecoration(
          color: bg,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: selected ? fg : Colors.transparent,
              width: 1.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              word.word,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: omitted ? t.ink3 : t.ink,
                decoration: switch (err) {
                  'Insertion' || 'Omission' => TextDecoration.lineThrough,
                  'Mispronunciation' => TextDecoration.underline,
                  _ => null,
                },
                decorationStyle: err == 'Mispronunciation'
                    ? TextDecorationStyle.wavy
                    : null,
                decorationColor: fg,
              ),
            ),
            if (!omitted) ...[
              const SizedBox(width: 6),
              Text(
                '${pa.accuracyScore.round()}',
                style: enjoyMonoStyle(
                  context,
                  size: 11.5,
                  weight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
