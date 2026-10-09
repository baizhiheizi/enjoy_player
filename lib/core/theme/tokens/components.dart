part of '../enjoy_tokens.dart';

final class _ComponentTokens {
  const _ComponentTokens({
    required this.miniBarBlurSigma,
    required this.heroTitleLetterSpacing,
    required this.controlHeightSm,
    required this.controlHeight,
    required this.controlHeightLg,
    required this.touchTargetMin,
    required this.iconButtonSize,
    required this.iconButtonSizePhone,
    required this.segmentHeight,
    required this.chipHeight,
    required this.takeChipHeight,
    required this.playButtonSize,
    required this.playButtonSizePhone,
    required this.recordButtonSize,
    required this.recordButtonSizePhone,
    required this.originalPillWidth,
    required this.originalPillHeight,
    required this.originalButtonPhoneSize,
  });

  factory _ComponentTokens.build() => const _ComponentTokens(
    miniBarBlurSigma: 24,
    heroTitleLetterSpacing: -0.9,
    controlHeightSm: 32,
    controlHeight: 40,
    controlHeightLg: 50,
    touchTargetMin: 44,
    iconButtonSize: 40,
    iconButtonSizePhone: 44,
    segmentHeight: 38,
    chipHeight: 34,
    takeChipHeight: 36,
    playButtonSize: 60,
    playButtonSizePhone: 68,
    recordButtonSize: 62,
    recordButtonSizePhone: 76,
    originalPillWidth: 150,
    originalPillHeight: 52,
    originalButtonPhoneSize: 56,
  );

  /// Backdrop-filter blur for the transport glass bar.
  final double miniBarBlurSigma;

  /// Letter-spacing for hero display titles (negative = tight).
  final double heroTitleLetterSpacing;

  /// Compact control height (toolbar buttons, chips).
  final double controlHeightSm;

  /// Default control height (buttons, fields, segmented).
  final double controlHeight;

  /// Prominent control height (primary CTAs, dock play button).
  final double controlHeightLg;

  /// Smallest tappable dimension.
  final double touchTargetMin;
  final double iconButtonSize;
  final double iconButtonSizePhone;
  final double segmentHeight;
  final double chipHeight;
  final double takeChipHeight;
  final double playButtonSize;
  final double playButtonSizePhone;
  final double recordButtonSize;
  final double recordButtonSizePhone;
  final double originalPillWidth;
  final double originalPillHeight;
  final double originalButtonPhoneSize;

  _ComponentTokens copyWith({
    double? miniBarBlurSigma,
    double? heroTitleLetterSpacing,
    double? controlHeightSm,
    double? controlHeight,
    double? controlHeightLg,
    double? touchTargetMin,
    double? iconButtonSize,
    double? iconButtonSizePhone,
    double? segmentHeight,
    double? chipHeight,
    double? takeChipHeight,
    double? playButtonSize,
    double? playButtonSizePhone,
    double? recordButtonSize,
    double? recordButtonSizePhone,
    double? originalPillWidth,
    double? originalPillHeight,
    double? originalButtonPhoneSize,
  }) {
    return _ComponentTokens(
      miniBarBlurSigma: miniBarBlurSigma ?? this.miniBarBlurSigma,
      heroTitleLetterSpacing:
          heroTitleLetterSpacing ?? this.heroTitleLetterSpacing,
      controlHeightSm: controlHeightSm ?? this.controlHeightSm,
      controlHeight: controlHeight ?? this.controlHeight,
      controlHeightLg: controlHeightLg ?? this.controlHeightLg,
      touchTargetMin: touchTargetMin ?? this.touchTargetMin,
      iconButtonSize: iconButtonSize ?? this.iconButtonSize,
      iconButtonSizePhone: iconButtonSizePhone ?? this.iconButtonSizePhone,
      segmentHeight: segmentHeight ?? this.segmentHeight,
      chipHeight: chipHeight ?? this.chipHeight,
      takeChipHeight: takeChipHeight ?? this.takeChipHeight,
      playButtonSize: playButtonSize ?? this.playButtonSize,
      playButtonSizePhone: playButtonSizePhone ?? this.playButtonSizePhone,
      recordButtonSize: recordButtonSize ?? this.recordButtonSize,
      recordButtonSizePhone:
          recordButtonSizePhone ?? this.recordButtonSizePhone,
      originalPillWidth: originalPillWidth ?? this.originalPillWidth,
      originalPillHeight: originalPillHeight ?? this.originalPillHeight,
      originalButtonPhoneSize:
          originalButtonPhoneSize ?? this.originalButtonPhoneSize,
    );
  }

  _ComponentTokens lerp(_ComponentTokens other, double t) {
    return _ComponentTokens(
      miniBarBlurSigma: lerpDouble(
        miniBarBlurSigma,
        other.miniBarBlurSigma,
        t,
      )!,
      heroTitleLetterSpacing: lerpDouble(
        heroTitleLetterSpacing,
        other.heroTitleLetterSpacing,
        t,
      )!,
      controlHeightSm: lerpDouble(controlHeightSm, other.controlHeightSm, t)!,
      controlHeight: lerpDouble(controlHeight, other.controlHeight, t)!,
      controlHeightLg: lerpDouble(controlHeightLg, other.controlHeightLg, t)!,
      touchTargetMin: lerpDouble(touchTargetMin, other.touchTargetMin, t)!,
      iconButtonSize: lerpDouble(iconButtonSize, other.iconButtonSize, t)!,
      iconButtonSizePhone: lerpDouble(
        iconButtonSizePhone,
        other.iconButtonSizePhone,
        t,
      )!,
      segmentHeight: lerpDouble(segmentHeight, other.segmentHeight, t)!,
      chipHeight: lerpDouble(chipHeight, other.chipHeight, t)!,
      takeChipHeight: lerpDouble(takeChipHeight, other.takeChipHeight, t)!,
      playButtonSize: lerpDouble(playButtonSize, other.playButtonSize, t)!,
      playButtonSizePhone: lerpDouble(
        playButtonSizePhone,
        other.playButtonSizePhone,
        t,
      )!,
      recordButtonSize: lerpDouble(
        recordButtonSize,
        other.recordButtonSize,
        t,
      )!,
      recordButtonSizePhone: lerpDouble(
        recordButtonSizePhone,
        other.recordButtonSizePhone,
        t,
      )!,
      originalPillWidth: lerpDouble(
        originalPillWidth,
        other.originalPillWidth,
        t,
      )!,
      originalPillHeight: lerpDouble(
        originalPillHeight,
        other.originalPillHeight,
        t,
      )!,
      originalButtonPhoneSize: lerpDouble(
        originalButtonPhoneSize,
        other.originalButtonPhoneSize,
        t,
      )!,
    );
  }
}
