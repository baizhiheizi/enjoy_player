import 'package:enjoy_player/features/transcript/data/transcript_timeline_codec.dart';
import 'package:flutter_test/flutter_test.dart';

String _buildTimelineJson(int cueCount) {
  final buffer = StringBuffer('[');
  for (var index = 0; index < cueCount; index++) {
    if (index > 0) buffer.write(',');
    buffer.write(
      '{"text":"line $index with a few words","startMs":${index * 1000},'
      '"durationMs":900,"timeline":null}',
    );
  }
  buffer.write(']');
  return buffer.toString();
}

void main() {
  group('timelineJsonCharacterCount at scale', () {
    test('counts a 20000-cue payload the same way the rune count does', () {
      final payload = _buildTimelineJson(20000);

      expect(timelineJsonCharacterCount(payload), payload.runes.length);
    });

    test('counts code points, not UTF-16 code units', () {
      const emoji = '🎵';
      final payload = _buildTimelineJson(3).replaceAll('with', emoji);

      expect(
        timelineJsonCharacterCount(payload),
        payload.length - 3,
        reason: 'each emoji is two code units but one character',
      );
    });

    test('a payload of only astral characters counts one per character', () {
      final payload = '🎵' * 5000;

      expect(timelineJsonCharacterCount(payload), 5000);
      expect(payload.length, 10000);
    });
  });

  test('counts a 20000-cue payload under the loose ceiling (local only)', () {
    final payload = _buildTimelineJson(20000);

    timelineJsonCharacterCount(payload);

    final sw = Stopwatch()..start();
    const runs = 20;
    for (var i = 0; i < runs; i++) {
      timelineJsonCharacterCount(payload);
    }
    sw.stop();

    final medianMs = sw.elapsedMilliseconds / runs;
    // ignore: avoid_print
    print(
      'timeline character count: ${medianMs.toStringAsFixed(2)} ms/run '
      '(20000 cues)',
    );
    expect(medianMs, lessThan(500));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');
}
