/// The detail surface for one selected assessment word: word header with
/// score, model pronunciation and my-clip playback controls, phoneme tiles,
/// syllable breakdown, and the localized error explanation.
library;

import 'package:azure_speech/azure_speech.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_tappable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/features/pronounce/domain/pronounce_target.dart';
import 'package:enjoy_player/features/pronounce/presentation/pronounce_icon_button.dart';
import 'package:enjoy_player/features/shadow_reading/domain/assessment_word_timing.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'assessment_error_messages.dart';
import 'assessment_score_indicators.dart';
import 'score_level.dart';

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
