import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_virtual_items.dart';
import 'package:flutter_test/flutter_test.dart';

EchoState _echo(int start, int end) => EchoState(
  active: true,
  startLineIndex: start,
  endLineIndex: end,
  startTimeSeconds: start.toDouble(),
  endTimeSeconds: end.toDouble(),
);

List<TranscriptLine> _lines(int count) => List.generate(
  count,
  (i) => TranscriptLine(text: 'line $i', startMs: i * 1000, durationMs: 1000),
);

void main() {
  test('inactive echo keeps every line as its own row', () {
    final items = buildTranscriptVirtualItems(_lines(3), EchoState.inactive);

    expect(items, hasLength(3));
    expect(items.map((i) => i is TranscriptVirtualLine ? i.lineIndex : null), [
      0,
      1,
      2,
    ]);
  });

  test('active echo collapses its range into one card slot', () {
    final items = buildTranscriptVirtualItems(_lines(6), _echo(2, 4));

    expect(items, hasLength(4));
    expect(items[0], isA<TranscriptVirtualLine>());
    expect((items[0] as TranscriptVirtualLine).lineIndex, 0);
    expect((items[1] as TranscriptVirtualLine).lineIndex, 1);
    expect(
      items[2],
      isA<TranscriptVirtualEcho>()
          .having((e) => e.startLineIndex, 'start', 2)
          .having((e) => e.endLineIndex, 'end', 4),
    );
    expect((items[3] as TranscriptVirtualLine).lineIndex, 5);
  });

  test('echo spanning the whole list yields a single card slot', () {
    final items = buildTranscriptVirtualItems(_lines(3), _echo(0, 2));

    expect(items, hasLength(1));
    expect(items.single, isA<TranscriptVirtualEcho>());
  });

  test('echo bounds touch either edge without dropping neighbors', () {
    final leading = buildTranscriptVirtualItems(_lines(3), _echo(0, 0));
    final trailing = buildTranscriptVirtualItems(_lines(3), _echo(2, 2));

    expect(leading, hasLength(3));
    expect(leading.first, isA<TranscriptVirtualEcho>());
    expect(trailing, hasLength(3));
    expect(trailing.last, isA<TranscriptVirtualEcho>());
  });

  test('empty list yields no items', () {
    expect(buildTranscriptVirtualItems(const [], _echo(0, 2)), isEmpty);
    expect(buildTranscriptVirtualItems(const [], EchoState.inactive), isEmpty);
  });

  test('out-of-range echo start never matches, so nothing collapses', () {
    final items = buildTranscriptVirtualItems(_lines(3), _echo(10, 12));

    expect(items, hasLength(3));
    expect(items.every((i) => i is TranscriptVirtualLine), isTrue);
  });
}
