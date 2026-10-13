import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

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
    final t = EnjoyThemeTokens.build(scheme);

    test('green for Excellent / Good, amber for Fair, red for Poor', () {
      expect(
        assessmentScoreColor(t, AssessmentScoreLevel.excellent),
        t.scoreGood,
      );
      expect(assessmentScoreColor(t, AssessmentScoreLevel.good), t.scoreGood);
      expect(assessmentScoreColor(t, AssessmentScoreLevel.fair), t.scoreWarn);
      expect(assessmentScoreColor(t, AssessmentScoreLevel.poor), t.scoreBad);
      expect(t.scoreGood, isNot(t.scoreWarn));
      expect(t.scoreWarn, isNot(t.scoreBad));
    });

    test('backgrounds use the matching tinted containers', () {
      expect(
        assessmentScoreBackground(t, AssessmentScoreLevel.good),
        t.scoreGoodContainer,
      );
      expect(
        assessmentScoreBackground(t, AssessmentScoreLevel.fair),
        t.scoreWarnContainer,
      );
      expect(
        assessmentScoreBackground(t, AssessmentScoreLevel.poor),
        t.scoreBadContainer,
      );
    });
  });

  test('level labels', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(
      assessmentScoreLevelLabel(l10n, AssessmentScoreLevel.excellent),
      'Excellent',
    );
    expect(
      assessmentScoreLevelLabel(l10n, AssessmentScoreLevel.poor),
      'Needs work',
    );
  });
}
