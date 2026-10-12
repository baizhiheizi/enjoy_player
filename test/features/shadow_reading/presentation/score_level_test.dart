import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/shadow_reading/presentation/score_level.dart';

void main() {
  group('assessmentScoreLevel', () {
    test('maps to excellent for >=91', () {
      expect(assessmentScoreLevel(91), AssessmentScoreLevel.excellent);
      expect(assessmentScoreLevel(120), AssessmentScoreLevel.excellent);
    });

    test('maps to good for 81..90', () {
      expect(assessmentScoreLevel(81), AssessmentScoreLevel.good);
      expect(assessmentScoreLevel(90), AssessmentScoreLevel.good);
    });

    test('maps to fair for 61..80', () {
      expect(assessmentScoreLevel(61), AssessmentScoreLevel.fair);
      expect(assessmentScoreLevel(80), AssessmentScoreLevel.fair);
    });

    test('maps to poor for <61', () {
      expect(assessmentScoreLevel(60), AssessmentScoreLevel.poor);
      expect(assessmentScoreLevel(0), AssessmentScoreLevel.poor);
    });
  });

  group('assessmentScoreColor + assessmentScoreBackground', () {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));

    test('every level reads in ink — scores are never colored', () {
      for (final level in AssessmentScoreLevel.values) {
        expect(assessmentScoreColor(scheme, level), scheme.onSurface);
      }
    });

    test('background applies 0.08 alpha over ink', () {
      final level = AssessmentScoreLevel.poor;
      final expected = scheme.onSurface.withValues(alpha: 0.08);
      expect(assessmentScoreBackground(scheme, level), expected);
    });
  });
}
