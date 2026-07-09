import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('orderPendingLineIndexes never exceeds pending set', () {
    final pending = List<int>.generate(20, (i) => i);
    final ordered = orderPendingLineIndexes(
      anchorIndex: 10,
      pending: pending,
    );
    expect(ordered.length, pending.length);
    expect(ordered.toSet(), pending.toSet());
    expect(ordered.first, 10);
    expect(ordered[1], 9);
    expect(ordered[2], 11);
  });

  test('pendingLineIndexes finds empty texts only', () {
    const lines = [
      TranscriptLine(text: 'done', startMs: 0, durationMs: 1000),
      TranscriptLine(text: '', startMs: 1000, durationMs: 500),
      TranscriptLine(text: '   ', startMs: 1500, durationMs: 500),
    ];
    expect(pendingLineIndexes(lines), [1, 2]);
    expect(readyLineCount(lines), 1);
  });

  test('pendingLineIndexes excludes exhausted failures', () {
    const lines = [
      TranscriptLine(text: '', startMs: 0, durationMs: 1000),
      TranscriptLine(text: '', startMs: 1000, durationMs: 500),
      TranscriptLine(text: '', startMs: 1500, durationMs: 500),
    ];
    expect(pendingLineIndexes(lines, exclude: {0, 2}), [1]);
  });

  test('failed line indexes are part of ui state equality', () {
    const a = AutoTranslateUiState(failedLineIndexes: {1, 3});
    const b = AutoTranslateUiState(failedLineIndexes: {3, 1});
    const c = AutoTranslateUiState(failedLineIndexes: {1});
    expect(a, b);
    expect(a == c, isFalse);
    expect(a.isLineFailed(1), isTrue);
    expect(a.isLineFailed(2), isFalse);
  });
}
