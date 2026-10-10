part of '../enjoy_tokens.dart';

double _lerpMs(Duration a, Duration b, double t) => lerpDouble(
  a.inMilliseconds.toDouble(),
  b.inMilliseconds.toDouble(),
  t,
)!.roundToDouble();

final class _MotionTokens {
  const _MotionTokens({
    required this.motionFast,
    required this.motionStandard,
    required this.motionEnter,
    required this.motionExit,
    required this.motionMedium,
    required this.motionLens,
    required this.motionMargin,
  });

  factory _MotionTokens.build() => const _MotionTokens(
    motionFast: Duration(milliseconds: 160),
    motionStandard: Duration(milliseconds: 280),
    motionEnter: Duration(milliseconds: 260),
    motionExit: Duration(milliseconds: 160),
    motionMedium: Duration(milliseconds: 220),
    motionLens: Duration(milliseconds: 280),
    motionMargin: Duration(milliseconds: 220),
  );

  /// Micro-interactions: 160ms.
  final Duration motionFast;

  /// Standard transitions: 280ms.
  final Duration motionStandard;

  /// Screen enter: 260ms.
  final Duration motionEnter;

  /// Screen exit: 160ms (faster than enter for responsiveness).
  final Duration motionExit;

  /// Transport / layout morphs: 220ms (between [motionFast] and [motionStandard]).
  final Duration motionMedium;

  /// Listen ↔ Echo lens transition: 280ms.
  final Duration motionLens;

  /// Side margin open/close slide: 220ms.
  final Duration motionMargin;

  _MotionTokens copyWith({
    Duration? motionFast,
    Duration? motionStandard,
    Duration? motionEnter,
    Duration? motionExit,
    Duration? motionMedium,
    Duration? motionLens,
    Duration? motionMargin,
  }) {
    return _MotionTokens(
      motionFast: motionFast ?? this.motionFast,
      motionStandard: motionStandard ?? this.motionStandard,
      motionEnter: motionEnter ?? this.motionEnter,
      motionExit: motionExit ?? this.motionExit,
      motionMedium: motionMedium ?? this.motionMedium,
      motionLens: motionLens ?? this.motionLens,
      motionMargin: motionMargin ?? this.motionMargin,
    );
  }

  _MotionTokens lerp(_MotionTokens other, double t) {
    return _MotionTokens(
      motionFast: Duration(
        milliseconds: _lerpMs(motionFast, other.motionFast, t).round(),
      ),
      motionStandard: Duration(
        milliseconds: _lerpMs(motionStandard, other.motionStandard, t).round(),
      ),
      motionEnter: Duration(
        milliseconds: _lerpMs(motionEnter, other.motionEnter, t).round(),
      ),
      motionExit: Duration(
        milliseconds: _lerpMs(motionExit, other.motionExit, t).round(),
      ),
      motionMedium: Duration(
        milliseconds: _lerpMs(motionMedium, other.motionMedium, t).round(),
      ),
      motionLens: Duration(
        milliseconds: _lerpMs(motionLens, other.motionLens, t).round(),
      ),
      motionMargin: Duration(
        milliseconds: _lerpMs(motionMargin, other.motionMargin, t).round(),
      ),
    );
  }
}
