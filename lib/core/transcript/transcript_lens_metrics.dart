import 'package:flutter/widgets.dart';

import 'package:enjoy_player/core/platform/mobile_platform.dart';

/// Marks a transcript rendered in the video player's side column.
class TranscriptVideoColumnScope extends InheritedWidget {
  const TranscriptVideoColumnScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<TranscriptVideoColumnScope>() !=
      null;

  @override
  bool updateShouldNotify(TranscriptVideoColumnScope oldWidget) => false;
}

enum TranscriptLensSurface { desktop, video, phone }

/// Sizes of the Listen and Echo lenses, per surface (the `Main` and `Phone`
/// boards in `docs/design/duet/boards/`).
@immutable
class TranscriptLensMetrics {
  const TranscriptLensMetrics._(this.surface);

  factory TranscriptLensMetrics.of(BuildContext context) =>
      TranscriptLensMetrics.forSurface(
        TranscriptVideoColumnScope.of(context)
            ? TranscriptLensSurface.video
            : isMobilePlatform
            ? TranscriptLensSurface.phone
            : TranscriptLensSurface.desktop,
      );

  const TranscriptLensMetrics.forSurface(TranscriptLensSurface surface)
    : this._(surface);

  final TranscriptLensSurface surface;

  bool get isVideo => surface == TranscriptLensSurface.video;
  bool get isPhone => surface == TranscriptLensSurface.phone;

  double get gutterWidth => switch (surface) {
    TranscriptLensSurface.desktop => 44,
    TranscriptLensSurface.video => 36,
    TranscriptLensSurface.phone => 8,
  };
  double get gutterGap => isPhone ? 6 : 10;

  /// Phones show the active line's time above it instead of in the gutter.
  bool get timeInGutter => !isPhone;
  double get timeAboveLineGap => 5;
  double get lineRadius => 10;
  double get timeFontSize => 11;
  double get practicedDotGap => 6;

  double lineFontSize({required bool active}) => switch (surface) {
    TranscriptLensSurface.desktop => active ? 21 : 17,
    TranscriptLensSurface.video => active ? 17 : 15,
    TranscriptLensSurface.phone => active ? 20 : 16,
  };

  double secondaryFontSize({required bool active}) => switch (surface) {
    TranscriptLensSurface.desktop => active ? 14.5 : 13.5,
    TranscriptLensSurface.video => active ? 13.5 : 12.5,
    TranscriptLensSurface.phone => active ? 13.5 : 12.5,
  };

  EdgeInsets linePadding({required bool active}) => switch (surface) {
    TranscriptLensSurface.video =>
      active
          ? const EdgeInsets.fromLTRB(4, 8, 10, 9)
          : const EdgeInsets.fromLTRB(4, 4, 10, 4),
    TranscriptLensSurface.desktop =>
      active
          ? const EdgeInsets.fromLTRB(6, 10, 14, 12)
          : const EdgeInsets.fromLTRB(6, 5, 14, 5),
    TranscriptLensSurface.phone =>
      active
          ? const EdgeInsets.fromLTRB(0, 10, 8, 12)
          : const EdgeInsets.fromLTRB(0, 5, 8, 5),
  };

  double gutterTop({required bool active}) => switch (surface) {
    TranscriptLensSurface.desktop => active ? 7 : 5,
    TranscriptLensSurface.video => active ? 5 : 4,
    TranscriptLensSurface.phone => active ? 22 : 8,
  };

  double get alignedLineHeight => 1.32;
  double get plainLineHeight => 1.42;
  double get listenLetterSpacingEm => -0.006;
  double get listenIpaFontSize => isPhone ? 11.5 : 12;
  double get secondaryTopGap => 2;
  double get secondaryLineHeight => 1.45;

  double contextFontSize(int distance) => switch (surface) {
    TranscriptLensSurface.desktop => switch (distance) {
      1 => 16,
      2 => 15,
      _ => 14,
    },
    TranscriptLensSurface.video => distance == 1 ? 14.5 : 13.5,
    TranscriptLensSurface.phone => distance == 1 ? 14.5 : 13.5,
  };

  EdgeInsets get contextPadding => switch (surface) {
    TranscriptLensSurface.video => const EdgeInsets.fromLTRB(4, 3, 10, 3),
    TranscriptLensSurface.desktop => const EdgeInsets.fromLTRB(6, 3, 14, 3),
    TranscriptLensSurface.phone => const EdgeInsets.fromLTRB(0, 3, 8, 3),
  };

  double get contextLineHeight => 1.4;
  double get contextGutterTop => 4;

  double loopFontSize(int lineCount, {required double mediaWidth}) =>
      switch (surface) {
        TranscriptLensSurface.video => lineCount == 1 ? 20 : 18,
        TranscriptLensSurface.phone => lineCount == 1 ? 23 : 20,
        TranscriptLensSurface.desktop => switch (lineCount) {
          1 => (mediaWidth * 0.02).clamp(22.0, 28.0),
          2 => (mediaWidth * 0.017).clamp(20.0, 24.0),
          _ => 19,
        },
      };

  double get loopLineHeight => 1.3;
  double get loopLetterSpacingEm => isPhone ? -0.008 : -0.01;
  double get loopIpaFontSize => 13;
  double get loopLineGap => 12;
  double get loopSecondaryTopGap => 6;
  double get loopSecondaryLineHeight => 1.5;
  double get loopSecondaryFontSize => switch (surface) {
    TranscriptLensSurface.desktop => 15,
    TranscriptLensSurface.video => 13.5,
    TranscriptLensSurface.phone => 14,
  };

  bool get showLoopGutter => surface == TranscriptLensSurface.desktop;

  EdgeInsets get loopPadding => switch (surface) {
    TranscriptLensSurface.desktop => const EdgeInsets.fromLTRB(12, 24, 28, 24),
    TranscriptLensSurface.video => const EdgeInsets.fromLTRB(14, 22, 14, 22),
    TranscriptLensSurface.phone => const EdgeInsets.fromLTRB(16, 22, 16, 24),
  };

  double get loopTopMargin => isPhone ? 26 : 24;
  double get loopSideMargin => isPhone ? 4 : 0;
  double get bracketArm => isPhone ? 22 : 20;
  double get bracketRadius => isPhone ? 9 : 10;
  double get loopLabelGap => 8;
  double get loopLabelBottomGap => 10;
  double get loopRecordingTopGap => isPhone ? 14 : 16;
  double get pitchTopGap => isPhone ? 16 : 18;
  double get pitchHeight => isPhone ? 52 : 64;

  /// Left inset of the takes strip, aligned with the loop text column.
  double get takesLeftInset =>
      showLoopGutter ? loopPadding.left + gutterWidth + gutterGap : 0;
  double get takesTopGap => 22;
}
