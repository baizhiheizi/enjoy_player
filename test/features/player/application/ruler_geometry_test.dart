import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/ruler_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

const _lines = [
  TranscriptLine(text: 'a', startMs: 0, durationMs: 4000),
  TranscriptLine(text: 'b', startMs: 4000, durationMs: 4000),
  TranscriptLine(text: 'c', startMs: 8000, durationMs: 4000),
];

void main() {
  test('projects line starts, practiced indexes and echo bounds', () {
    final geometry = RulerGeometry.from(
      lines: _lines,
      echo: const EchoState(
        active: true,
        startTimeSeconds: 4,
        endTimeSeconds: 8,
        startLineIndex: 1,
        endLineIndex: 2,
      ),
      practicedCounts: const {0: 2, 2: 1},
      durationSec: 16,
    );

    expect(geometry.lineStartFractions, [0.0, 0.25, 0.5]);
    expect(geometry.practicedLineIndexes, [0, 2]);
    expect(geometry.loopStart, 0.25);
    expect(geometry.loopEnd, 0.5);
  });

  test('inactive echo has no loop bounds', () {
    final geometry = RulerGeometry.from(
      lines: _lines,
      echo: EchoState.inactive,
      practicedCounts: const {},
      durationSec: 12,
    );

    expect(geometry.loopStart, isNull);
    expect(geometry.loopEnd, isNull);
    expect(geometry.practicedLineIndexes, isEmpty);
  });

  test('value equality compares lists element-wise', () {
    RulerGeometry build() => RulerGeometry.from(
      lines: _lines,
      echo: EchoState.inactive,
      practicedCounts: const {1: 3},
      durationSec: 12,
    );

    final a = build();
    final b = build();
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('a mismatched duration breaks equality', () {
    final a = RulerGeometry.from(
      lines: _lines,
      echo: EchoState.inactive,
      practicedCounts: const {},
      durationSec: 12,
    );
    final b = RulerGeometry.from(
      lines: _lines,
      echo: EchoState.inactive,
      practicedCounts: const {},
      durationSec: 16,
    );

    expect(a, isNot(equals(b)));
  });
}
