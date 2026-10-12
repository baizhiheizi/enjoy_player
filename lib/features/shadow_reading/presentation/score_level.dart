/// Tiered score levels (mirrors web `getScoreLevel` thresholds).
library;

import 'package:flutter/material.dart';

enum AssessmentScoreLevel { excellent, good, fair, poor }

AssessmentScoreLevel assessmentScoreLevel(num score) {
  if (score >= 91) return AssessmentScoreLevel.excellent;
  if (score >= 81) return AssessmentScoreLevel.good;
  if (score >= 61) return AssessmentScoreLevel.fair;
  return AssessmentScoreLevel.poor;
}

/// Scores are never colored (ADR-0093): every level reads in ink; the level
/// itself is conveyed by the number, label and meter.
Color assessmentScoreColor(ColorScheme scheme, AssessmentScoreLevel level) =>
    scheme.onSurface;

Color assessmentScoreBackground(
  ColorScheme scheme,
  AssessmentScoreLevel level,
) {
  return assessmentScoreColor(scheme, level).withValues(alpha: 0.08);
}
