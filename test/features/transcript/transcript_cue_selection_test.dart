import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_cue_selection.dart';
import 'package:flutter_test/flutter_test.dart';

TranscriptLine cue(int startMs, int durationMs, [String text = 'x']) {
  return TranscriptLine(text: text, startMs: startMs, durationMs: durationMs);
}

void main() {
  group('transcriptActiveIndex', () {
    test('returns index when time is inside a cue', () {
      final lines = [cue(0, 1000), cue(1000, 1000), cue(2000, 1000)];
      expect(transcriptActiveIndex(lines, 0.5), 0);
      expect(transcriptActiveIndex(lines, 1.0), 1);
      expect(transcriptActiveIndex(lines, 1.5), 1);
      expect(transcriptActiveIndex(lines, 2.5), 2);
    });

    test('returns last cue with start <= t when t is in a gap (after end)', () {
      final lines = [cue(0, 500), cue(2000, 500)];
      expect(transcriptActiveIndex(lines, 1.0), 0);
      expect(transcriptActiveIndex(lines, 1.5), 0);
    });

    test('returns last cue when t is in a non-empty gap between cues', () {
      final lines = [
        cue(0, 1000),
        cue(1000, 1000),
        cue(3000, 1000),
        cue(4000, 1000),
      ];
      expect(transcriptActiveIndex(lines, 2.5), 1);
    });

    test('returns -1 when t is before first cue', () {
      final lines = [cue(1000, 500)];
      expect(transcriptActiveIndex(lines, 0.5), -1);
    });

    test('empty lines returns -1', () {
      expect(transcriptActiveIndex([], 1.0), -1);
    });
  });

  group('transcriptActiveIndexForEchoUi', () {
    test('filters to echo window', () {
      final echo = const EchoState(
        active: true,
        startLineIndex: 1,
        endLineIndex: 2,
        startTimeSeconds: 0,
        endTimeSeconds: 10,
      );
      expect(transcriptActiveIndexForEchoUi(echo, 0), -1);
      expect(transcriptActiveIndexForEchoUi(echo, 1), 1);
      expect(transcriptActiveIndexForEchoUi(echo, 3), -1);
    });
  });
}
