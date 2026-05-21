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
}
