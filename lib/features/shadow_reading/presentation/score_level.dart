/// Tiered score levels (mirrors web `getScoreLevel` thresholds) and their
/// colors: green for Excellent / Good, amber for Fair, red for Poor.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

enum AssessmentScoreLevel { excellent, good, fair, poor }

AssessmentScoreLevel assessmentScoreLevel(num score) {
  if (score >= 91) return AssessmentScoreLevel.excellent;
  if (score >= 81) return AssessmentScoreLevel.good;
  if (score >= 61) return AssessmentScoreLevel.fair;
  return AssessmentScoreLevel.poor;
}

/// Foreground color for [level] (text, bars, rings).
Color assessmentScoreColor(EnjoyThemeTokens t, AssessmentScoreLevel level) =>
    switch (level) {
      AssessmentScoreLevel.excellent ||
      AssessmentScoreLevel.good => t.scoreGood,
      AssessmentScoreLevel.fair => t.scoreWarn,
      AssessmentScoreLevel.poor => t.scoreBad,
    };

/// Tinted fill for [level] (chips, pills, panels).
Color assessmentScoreBackground(
  EnjoyThemeTokens t,
  AssessmentScoreLevel level,
) => switch (level) {
  AssessmentScoreLevel.excellent ||
  AssessmentScoreLevel.good => t.scoreGoodContainer,
  AssessmentScoreLevel.fair => t.scoreWarnContainer,
  AssessmentScoreLevel.poor => t.scoreBadContainer,
};

String assessmentScoreLevelLabel(
  AppLocalizations l10n,
  AssessmentScoreLevel level,
) => switch (level) {
  AssessmentScoreLevel.excellent => l10n.assessmentLevelExcellent,
  AssessmentScoreLevel.good => l10n.assessmentLevelGood,
  AssessmentScoreLevel.fair => l10n.assessmentLevelFair,
  AssessmentScoreLevel.poor => l10n.assessmentLevelPoor,
};
