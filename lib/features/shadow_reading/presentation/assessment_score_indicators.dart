/// Score readouts for the assessment result surfaces: the overall progress
/// ring, the tinted level pill, and per-skill linear bars, all colored by the
/// level palettes of `score_level.dart`.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

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
