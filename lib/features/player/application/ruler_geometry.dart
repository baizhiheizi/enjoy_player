/// Static geometry for the Duet sentence ruler.
library;

import 'package:flutter/foundation.dart' show listEquals;

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';

class RulerGeometry {
  const RulerGeometry({
    required this.durationSec,
    required this.lineStartFractions,
    required this.practicedLineIndexes,
    required this.loopStart,
    required this.loopEnd,
  });

  factory RulerGeometry.from({
    required List<TranscriptLine> lines,
    required EchoState echo,
    required Map<int, int> practicedCounts,
    required double durationSec,
  }) {
    final safeDuration = durationSec > 0 ? durationSec : 1.0;
    return RulerGeometry(
      durationSec: safeDuration,
      lineStartFractions: [
        for (final line in lines)
          (line.startMs / 1000 / safeDuration).clamp(0.0, 1.0),
      ],
      practicedLineIndexes: [for (final entry in practicedCounts.keys) entry],
      loopStart: echo.active
          ? (echo.startTimeSeconds / safeDuration).clamp(0.0, 1.0)
          : null,
      loopEnd: echo.active
          ? (echo.endTimeSeconds / safeDuration).clamp(0.0, 1.0)
          : null,
    );
  }

  final double durationSec;
  final List<double> lineStartFractions;
  final List<int> practicedLineIndexes;
  final double? loopStart;
  final double? loopEnd;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RulerGeometry &&
        other.durationSec == durationSec &&
        other.loopStart == loopStart &&
        other.loopEnd == loopEnd &&
        listEquals(other.lineStartFractions, lineStartFractions) &&
        listEquals(other.practicedLineIndexes, practicedLineIndexes);
  }

  @override
  int get hashCode => Object.hash(
    durationSec,
    loopStart,
    loopEnd,
    Object.hashAll(lineStartFractions),
    Object.hashAll(practicedLineIndexes),
  );
}
