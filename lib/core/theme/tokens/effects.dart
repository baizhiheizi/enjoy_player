part of '../enjoy_tokens.dart';

List<double> _lerpDoubles(List<double> a, List<double> b, double t) =>
    List.generate(a.length, (i) => lerpDouble(a[i], b[i], t)!);

final class _EffectTokens {
  const _EffectTokens({
    required this.transcriptLinePadding,
    required this.echoLensOpacity,
    required this.referencePitchOpacity,
  });

  factory _EffectTokens.build() => const _EffectTokens(
    transcriptLinePadding: EdgeInsets.symmetric(horizontal: 16),
    echoLensOpacity: [1, 0.65, 0.35, 0.2],
    referencePitchOpacity: 0.35,
  );

  final EdgeInsets transcriptLinePadding;

  /// Listen ↔ Echo neighbour fade steps, by distance from the loop.
  final List<double> echoLensOpacity;

  /// Reference-pitch band opacity in the pitch duet.
  final double referencePitchOpacity;

  _EffectTokens copyWith({
    EdgeInsets? transcriptLinePadding,
    List<double>? echoLensOpacity,
    double? referencePitchOpacity,
  }) {
    return _EffectTokens(
      transcriptLinePadding:
          transcriptLinePadding ?? this.transcriptLinePadding,
      echoLensOpacity: echoLensOpacity ?? this.echoLensOpacity,
      referencePitchOpacity:
          referencePitchOpacity ?? this.referencePitchOpacity,
    );
  }

  _EffectTokens lerp(_EffectTokens other, double t) {
    return _EffectTokens(
      transcriptLinePadding: EdgeInsets.lerp(
        transcriptLinePadding,
        other.transcriptLinePadding,
        t,
      )!,
      echoLensOpacity: _lerpDoubles(echoLensOpacity, other.echoLensOpacity, t),
      referencePitchOpacity: lerpDouble(
        referencePitchOpacity,
        other.referencePitchOpacity,
        t,
      )!,
    );
  }
}
