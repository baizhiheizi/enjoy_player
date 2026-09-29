import 'dart:math';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_alignment.dart';
import 'package:flutter_test/flutter_test.dart';

TranscriptLine cue(int startMs, int durationMs, [String text = 'x']) {
  return TranscriptLine(text: text, startMs: startMs, durationMs: durationMs);
}

void main() {
  test('midpoint inside primary range wins', () {
    final primary = cue(1000, 2000);
    final secondary = [cue(0, 500), cue(1500, 500), cue(4000, 500)];
    final m = TranscriptSecondaryMatcher.from(secondary);
    expect(m.match(primary)?.startMs, 1500);
  });

  test('fallback is last secondary with start strictly before primary end', () {
    final primary = cue(1000, 2000);
    final secondary = [cue(0, 200), cue(500, 200)];
    final m = TranscriptSecondaryMatcher.from(secondary);
    expect(m.match(primary)?.startMs, 500);
  });

  test('unsorted secondary is sorted internally', () {
    final primary = cue(1000, 2000);
    final secondary = [cue(2000, 200), cue(0, 200)];
    final m = TranscriptSecondaryMatcher.from(secondary);
    expect(m.match(primary)?.startMs, 2000);
  });

  test('a very long secondary cue still matches a much later primary', () {
    final primary = cue(300000, 1000);
    final secondary = [cue(0, 600000), cue(10000, 200)];
    final m = TranscriptSecondaryMatcher.from(secondary);
    expect(m.match(primary)?.startMs, 0);
  });

  test('windowed search agrees with a linear scan (issue #810 G)', () {
    final rnd = Random(7);
    final secondary = [
      for (var i = 0; i < 400; i++)
        cue(rnd.nextInt(600000), 1 + rnd.nextInt(4000)),
    ];
    final m = TranscriptSecondaryMatcher.from(secondary);
    final sorted = [...secondary]
      ..sort((a, b) => a.startSeconds.compareTo(b.startSeconds));

    TranscriptLine? bruteForce(TranscriptLine p) {
      for (final s in sorted) {
        if (s.startSeconds >= p.endSeconds) break;
        final mid = s.startSeconds + (s.endSeconds - s.startSeconds) / 2;
        if (mid >= p.startSeconds && mid < p.endSeconds) return s;
      }
      for (final s in sorted.reversed) {
        if (s.startSeconds < p.endSeconds) return s;
      }
      return null;
    }

    for (var i = 0; i < 300; i++) {
      final primary = cue(rnd.nextInt(600000), 1 + rnd.nextInt(5000));
      expect(
        m.match(primary),
        bruteForce(primary),
        reason: 'primary startMs=${primary.startMs}',
      );
    }
  });
}
