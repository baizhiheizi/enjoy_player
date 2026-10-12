/// Stateless presentation widgets shared by every assessment surface (the wide
/// dialog, the side margin, the narrow sheet): [OverallScoreRing],
/// [ScoreBar], [AssessmentWordLegend], [WordChip], [SelectedWordPanel].
/// Scores read in the level colors of `score_level.dart`.
library;

import 'package:azure_speech/azure_speech.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/interaction/enjoy_tappable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/features/pronounce/domain/pronounce_target.dart';
import 'package:enjoy_player/features/pronounce/presentation/pronounce_icon_button.dart';
import 'package:enjoy_player/features/shadow_reading/domain/assessment_word_timing.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'assessment_error_messages.dart';
import 'score_level.dart';

class OverallScoreRing extends StatelessWidget {
  const OverallScoreRing({
    required this.score,
    required this.label,
    required this.scheme,
    required this.tt,
    this.trailing,
    super.key,
  });

  final int score;
  final String label;
  final ColorScheme scheme;
  final TextTheme tt;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final level = assessmentScoreLevel(score);
    final color = assessmentScoreColor(t, level);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: tt.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.88,
            color: t.ink3,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 132,
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: (score / 100).clamp(0.0, 1.0),
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                  backgroundColor: assessmentScoreBackground(t, level),
                  color: color,
                ),
              ),
              Text(
                '$score',
                style: enjoyDisplayStyle(
                  context,
                  size: 46,
                  color: t.ink,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AssessmentLevelPill(
          level: level,
          label: assessmentScoreLevelLabel(l10n, level),
        ),
        if (trailing != null) ...[const SizedBox(height: 12), trailing!],
      ],
    );
  }
}

/// Small tinted pill naming a score level.
class AssessmentLevelPill extends StatelessWidget {
  const AssessmentLevelPill({
    required this.level,
    required this.label,
    super.key,
  });

  final AssessmentScoreLevel level;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final color = assessmentScoreColor(t, level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: assessmentScoreBackground(t, level),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class ScoreBar extends StatelessWidget {
  const ScoreBar({
    required this.label,
    required this.value,
    required this.scheme,
    super.key,
  });

  final String label;
  final int value;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final level = assessmentScoreLevel(value);
    final color = assessmentScoreColor(t, level);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: t.ink2,
                ),
              ),
            ),
            Text(
              '$value',
              style: enjoyMonoStyle(
                context,
                size: 14,
                weight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: assessmentScoreBackground(t, level),
            color: color,
          ),
        ),
      ],
    );
  }
}

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

class SelectedWordPanel extends StatelessWidget {
  const SelectedWordPanel({
    required this.word,
    required this.localeTag,
    required this.l10n,
    required this.scheme,
    required this.tt,
    required this.recordingPlayable,
    required this.clipPlaying,
    required this.onToggleClip,
    required this.beforeModelPronounce,
    super.key,
  });

  final AzureWordAssessment word;
  final String localeTag;
  final AppLocalizations l10n;
  final ColorScheme scheme;
  final TextTheme tt;
  final bool recordingPlayable;
  final bool clipPlaying;
  final VoidCallback onToggleClip;
  final Future<void> Function() beforeModelPronounce;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final pa = word.pronunciationAssessment;
    final err = pa.errorType;
    final omitted = err == 'Omission';
    final acc = pa.accuracyScore;
    final level = assessmentScoreLevel(acc);
    final color = omitted ? t.ink3 : assessmentScoreColor(t, level);
    final clipUsable = recordingPlayable && isWordClipUsable(word);
    final clipTooltip = !recordingPlayable
        ? l10n.assessmentRecordingUnavailable
        : !isWordClipUsable(word)
        ? l10n.assessmentClipUnavailable
        : clipPlaying
        ? l10n.assessmentStopMyClip
        : l10n.assessmentPlayMyClip;
    final phonemes = word.phonemes ?? const <AzurePhonemeAssessment>[];
    final syllables = word.syllables ?? const <AzureSyllableAssessment>[];
    final sectionLabel = tt.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: t.ink2,
    );

    return Container(
      decoration: ShapeDecoration(
        color: t.paper,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.45)),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      style: enjoyDisplayStyle(
                        context,
                        size: 26,
                        color: t.ink,
                        height: 1.1,
                      ),
                    ),
                    if (phonemes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '/${phonemes.map((p) => p.phoneme).join()}/',
                        style: TextStyle(
                          fontFamily: kNotoSansFamily,
                          fontSize: 14,
                          color: t.ink3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    omitted ? '—' : '${acc.round()}',
                    style: enjoyDisplayStyle(
                      context,
                      size: 30,
                      color: color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (err != 'None')
                    _ErrorPill(
                      label: assessmentErrorTypeLabel(l10n, err),
                      color: color,
                    )
                  else
                    AssessmentLevelPill(
                      level: level,
                      label: assessmentScoreLevelLabel(l10n, level),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              PronounceIconButton(
                text: word.word,
                localeTag: localeTag,
                surfaceId: PronounceSurfaceId.assessment,
                compact: true,
                beforePlay: beforeModelPronounce,
              ),
              const SizedBox(width: 4),
              EnjoyTappableIcon(
                tooltip: clipTooltip,
                semanticLabel: clipTooltip,
                iconSize: 20,
                icon: clipPlaying ? EnjoyIcons.stop : EnjoyIcons.speak,
                color: clipUsable ? t.youInk : t.ink3.withValues(alpha: 0.5),
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  fixedSize: const Size(40, 40),
                ),
                onPressed: clipUsable ? onToggleClip : null,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  clipTooltip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(color: t.ink3),
                ),
              ),
            ],
          ),
          if (phonemes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(l10n.assessmentPhonemes, style: sectionLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final p in phonemes) _PhonemeTile(phoneme: p)],
            ),
          ],
          if (syllables.length > 1) ...[
            const SizedBox(height: 14),
            Text(l10n.assessmentSyllables, style: sectionLabel),
            const SizedBox(height: 4),
            Text(
              syllables.map((s) => s.syllable).join(' · '),
              style: tt.bodyMedium?.copyWith(color: t.ink2),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              color: omitted ? t.sunk : assessmentScoreBackground(t, level),
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  err == 'None' ? EnjoyIcons.checkCircle : EnjoyIcons.info,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assessmentErrorExplanation(l10n, err),
                    style: tt.bodySmall?.copyWith(color: t.ink2, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPill extends StatelessWidget {
  const _ErrorPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.14),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _PhonemeTile extends StatelessWidget {
  const _PhonemeTile({required this.phoneme});

  final AzurePhonemeAssessment phoneme;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final score = phoneme.pronunciationAssessment.accuracyScore;
    final level = assessmentScoreLevel(score);
    final color = assessmentScoreColor(t, level);
    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: ShapeDecoration(
        color: assessmentScoreBackground(t, level),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            phoneme.phoneme,
            style: TextStyle(
              fontFamily: kNotoSansFamily,
              fontSize: 16,
              height: 1.2,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${score.round()}',
            style: enjoyMonoStyle(
              context,
              size: 11,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
