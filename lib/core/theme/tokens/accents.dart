part of '../enjoy_tokens.dart';

final class _AccentColors {
  const _AccentColors({
    required this.echoActive,
    required this.blurActive,
    required this.scoreGood,
    required this.scoreWarn,
    required this.scoreBad,
    required this.scoreGoodContainer,
    required this.scoreWarnContainer,
    required this.scoreBadContainer,
    required this.accentSoft,
    required this.accentInk,
    required this.intelligenceInk,
    required this.echoInk,
    required this.ccBadge,
    required this.original,
    required this.originalInk,
    required this.originalSoft,
    required this.you,
    required this.youInk,
    required this.youSoft,
    required this.youLine,
    required this.onYou,
    required this.brandInk,
    required this.brandSoft,
    required this.primary,
    required this.onPrimary,
    required this.danger,
    required this.vocabNew,
    required this.vocabLearning,
    required this.vocabReviewing,
    required this.vocabMastered,
  });

  factory _AccentColors.build({
    required bool light,
    required ColorScheme scheme,
  }) => _AccentColors(
    echoActive: light ? AppColors.youLight : AppColors.youDark,
    blurActive: light ? AppColors.inkLight : AppColors.inkDark,
    scoreGood: light ? AppColors.ink2Light : AppColors.ink2Dark,
    scoreWarn: light ? AppColors.ink2Light : AppColors.ink2Dark,
    scoreBad: light ? AppColors.dangerLight : AppColors.dangerDark,
    scoreGoodContainer: light ? AppColors.sunkLight : AppColors.sunkDark,
    scoreWarnContainer: light ? AppColors.sunkLight : AppColors.sunkDark,
    scoreBadContainer: light ? AppColors.sunkLight : AppColors.sunkDark,
    accentSoft: light ? AppColors.brandSoftLight : AppColors.brandSoftDark,
    accentInk: light ? AppColors.brandInkLight : AppColors.brandInkDark,
    intelligenceInk: light
        ? AppColors.originalInkLight
        : AppColors.originalInkDark,
    echoInk: light ? AppColors.youInkLight : AppColors.youInkDark,
    ccBadge: scheme.primary,
    original: light ? AppColors.originalLight : AppColors.originalDark,
    originalInk: light ? AppColors.originalInkLight : AppColors.originalInkDark,
    originalSoft: light
        ? AppColors.originalSoftLight
        : AppColors.originalSoftDark,
    you: light ? AppColors.youLight : AppColors.youDark,
    youInk: light ? AppColors.youInkLight : AppColors.youInkDark,
    youSoft: light ? AppColors.youSoftLight : AppColors.youSoftDark,
    youLine: light ? AppColors.youLineLight : AppColors.youLineDark,
    onYou: light ? AppColors.onYouLight : AppColors.onYouDark,
    brandInk: light ? AppColors.brandInkLight : AppColors.brandInkDark,
    brandSoft: light ? AppColors.brandSoftLight : AppColors.brandSoftDark,
    primary: light ? AppColors.primaryInkLight : AppColors.primaryInkDark,
    onPrimary: light ? AppColors.onPrimaryInkLight : AppColors.onPrimaryInkDark,
    danger: light ? AppColors.dangerLight : AppColors.dangerDark,
    vocabNew: light ? AppColors.vocabNewLight : AppColors.vocabNewDark,
    vocabLearning: light
        ? AppColors.vocabLearningLight
        : AppColors.vocabLearningDark,
    vocabReviewing: light
        ? AppColors.vocabReviewingLight
        : AppColors.vocabReviewingDark,
    vocabMastered: light
        ? AppColors.vocabMasteredLight
        : AppColors.vocabMasteredDark,
  );

  final Color echoActive;

  /// Accent used for the listening-focus (hide text) toggle when active.
  final Color blurActive;

  /// Evaluation & assessment good color (ink in Duet — scores are uncolored).
  final Color scoreGood;

  /// Evaluation & assessment warn color (ink in Duet — scores are uncolored).
  final Color scoreWarn;

  /// Evaluation & assessment bad color (danger).
  final Color scoreBad;
  final Color scoreGoodContainer;
  final Color scoreWarnContainer;
  final Color scoreBadContainer;

  /// Soft translucent brand accent background.
  final Color accentSoft;

  /// Violet used as text/icon ink (deep on paper, bright on graphite).
  final Color accentInk;

  /// Original-speaker blue ink.
  final Color intelligenceInk;

  /// Learner violet ink.
  final Color echoInk;
  final Color ccBadge;

  /// Original-speaker blue: playback, spoken word, reference pitch, Listen.
  final Color original;

  /// Original blue as text/icon ink.
  final Color originalInk;

  /// Translucent original wash (selected rows, soft pills).
  final Color originalSoft;

  /// Learner violet: Echo loop, Record, takes, your pitch.
  final Color you;

  /// Learner violet as text/icon ink.
  final Color youInk;

  /// Translucent you wash (selected rows, soft pills).
  final Color youSoft;

  /// You-tinted outline (loop brackets, wavy underlines).
  final Color youLine;

  /// Label/icon color on [you] fills.
  final Color onYou;

  /// Brand ink — the readable end of the brand gradient.
  final Color brandInk;

  /// Soft brand wash (selected rows, tab-bar pill, radio fill).
  final Color brandSoft;

  /// Ink-fill primary buttons.
  final Color primary;

  /// Label color on [primary] fills.
  final Color onPrimary;

  /// Destructive actions and errors.
  final Color danger;

  /// Vocabulary status scale (new / learning / reviewing / mastered).
  final Color vocabNew;
  final Color vocabLearning;
  final Color vocabReviewing;
  final Color vocabMastered;

  _AccentColors copyWith({
    Color? echoActive,
    Color? blurActive,
    Color? scoreGood,
    Color? scoreWarn,
    Color? scoreBad,
    Color? scoreGoodContainer,
    Color? scoreWarnContainer,
    Color? scoreBadContainer,
    Color? accentSoft,
    Color? accentInk,
    Color? intelligenceInk,
    Color? echoInk,
    Color? ccBadge,
    Color? original,
    Color? originalInk,
    Color? originalSoft,
    Color? you,
    Color? youInk,
    Color? youSoft,
    Color? youLine,
    Color? onYou,
    Color? brandInk,
    Color? brandSoft,
    Color? primary,
    Color? onPrimary,
    Color? danger,
    Color? vocabNew,
    Color? vocabLearning,
    Color? vocabReviewing,
    Color? vocabMastered,
  }) {
    return _AccentColors(
      echoActive: echoActive ?? this.echoActive,
      blurActive: blurActive ?? this.blurActive,
      scoreGood: scoreGood ?? this.scoreGood,
      scoreWarn: scoreWarn ?? this.scoreWarn,
      scoreBad: scoreBad ?? this.scoreBad,
      scoreGoodContainer: scoreGoodContainer ?? this.scoreGoodContainer,
      scoreWarnContainer: scoreWarnContainer ?? this.scoreWarnContainer,
      scoreBadContainer: scoreBadContainer ?? this.scoreBadContainer,
      accentSoft: accentSoft ?? this.accentSoft,
      accentInk: accentInk ?? this.accentInk,
      intelligenceInk: intelligenceInk ?? this.intelligenceInk,
      echoInk: echoInk ?? this.echoInk,
      ccBadge: ccBadge ?? this.ccBadge,
      original: original ?? this.original,
      originalInk: originalInk ?? this.originalInk,
      originalSoft: originalSoft ?? this.originalSoft,
      you: you ?? this.you,
      youInk: youInk ?? this.youInk,
      youSoft: youSoft ?? this.youSoft,
      youLine: youLine ?? this.youLine,
      onYou: onYou ?? this.onYou,
      brandInk: brandInk ?? this.brandInk,
      brandSoft: brandSoft ?? this.brandSoft,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      danger: danger ?? this.danger,
      vocabNew: vocabNew ?? this.vocabNew,
      vocabLearning: vocabLearning ?? this.vocabLearning,
      vocabReviewing: vocabReviewing ?? this.vocabReviewing,
      vocabMastered: vocabMastered ?? this.vocabMastered,
    );
  }

  _AccentColors lerp(_AccentColors other, double t) {
    return _AccentColors(
      echoActive: Color.lerp(echoActive, other.echoActive, t)!,
      blurActive: Color.lerp(blurActive, other.blurActive, t)!,
      scoreGood: Color.lerp(scoreGood, other.scoreGood, t)!,
      scoreWarn: Color.lerp(scoreWarn, other.scoreWarn, t)!,
      scoreBad: Color.lerp(scoreBad, other.scoreBad, t)!,
      scoreGoodContainer: Color.lerp(
        scoreGoodContainer,
        other.scoreGoodContainer,
        t,
      )!,
      scoreWarnContainer: Color.lerp(
        scoreWarnContainer,
        other.scoreWarnContainer,
        t,
      )!,
      scoreBadContainer: Color.lerp(
        scoreBadContainer,
        other.scoreBadContainer,
        t,
      )!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      intelligenceInk: Color.lerp(intelligenceInk, other.intelligenceInk, t)!,
      echoInk: Color.lerp(echoInk, other.echoInk, t)!,
      ccBadge: Color.lerp(ccBadge, other.ccBadge, t)!,
      original: Color.lerp(original, other.original, t)!,
      originalInk: Color.lerp(originalInk, other.originalInk, t)!,
      originalSoft: Color.lerp(originalSoft, other.originalSoft, t)!,
      you: Color.lerp(you, other.you, t)!,
      youInk: Color.lerp(youInk, other.youInk, t)!,
      youSoft: Color.lerp(youSoft, other.youSoft, t)!,
      youLine: Color.lerp(youLine, other.youLine, t)!,
      onYou: Color.lerp(onYou, other.onYou, t)!,
      brandInk: Color.lerp(brandInk, other.brandInk, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      vocabNew: Color.lerp(vocabNew, other.vocabNew, t)!,
      vocabLearning: Color.lerp(vocabLearning, other.vocabLearning, t)!,
      vocabReviewing: Color.lerp(vocabReviewing, other.vocabReviewing, t)!,
      vocabMastered: Color.lerp(vocabMastered, other.vocabMastered, t)!,
    );
  }
}
