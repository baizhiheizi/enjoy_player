/// Pure current-word matching for karaoke highlight (no Flutter).
library;

import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';

/// UTF-16 offsets into plain (markup-stripped) line text.
@immutable
class WordTextRange {
  const WordTextRange({required this.start, required this.end});

  final int start;
  final int end;

  bool get isValid => start >= 0 && end > start;
}

typedef _TimedWordEntry = ({int index, int start, int end});

final class _TimedWordTable {
  _TimedWordTable({
    required this.entries,
    required this.prefixMaxEnd,
    required this.monotonic,
  });

  final List<_TimedWordEntry> entries;
  final List<int> prefixMaxEnd;
  final bool monotonic;
}

final Expando<_TimedWordTable> _timedWordTableMemo = Expando<_TimedWordTable>(
  'timedWordTable',
);

final Expando<({String plain, int length, List<WordTextRange?> ranges})>
_wordRangesMemo =
    Expando<({String plain, int length, List<WordTextRange?> ranges})>(
      'wordRangesMemo',
    );

_TimedWordTable _timedWordTableFor(TranscriptLine line) {
  final cached = _timedWordTableMemo[line];
  if (cached != null) return cached;
  final words = line.timeline;
  if (words == null || words.isEmpty) {
    final empty = _TimedWordTable(
      entries: const [],
      prefixMaxEnd: const [],
      monotonic: true,
    );
    _timedWordTableMemo[line] = empty;
    return empty;
  }
  final lineStart = line.startMs;
  final lineEnd = lineStart + line.durationMs;
  final entries = <_TimedWordEntry>[];
  final prefixMaxEnd = <int>[];
  var monotonic = true;
  var runningMaxEnd = -0x7fffffff;
  for (var i = 0; i < words.length; i++) {
    final word = words[i];
    if (word.text.trim().isEmpty || !_isTimedWord(word)) continue;
    final start = lineStart + (word.startMs ?? 0);
    final end = start + word.durationMs!;
    if (end <= lineStart || start >= lineEnd) continue;
    if (entries.isNotEmpty && start < entries.last.start) {
      monotonic = false;
    }
    runningMaxEnd = entries.isEmpty ? end : math.max(runningMaxEnd, end);
    entries.add((index: i, start: start, end: end));
    prefixMaxEnd.add(runningMaxEnd);
  }
  final table = _TimedWordTable(
    entries: entries,
    prefixMaxEnd: prefixMaxEnd,
    monotonic: monotonic,
  );
  _timedWordTableMemo[line] = table;
  return table;
}

/// Index of the timed word whose media window contains [positionMs].
///
/// Word windows are `[line.startMs + word.startMs, + duration)`. Overlaps
/// pick the last matching index. Returns null when karaoke should not paint.
int? currentWordIndex(TranscriptLine line, int positionMs) {
  final words = line.timeline;
  if (words == null || words.isEmpty) return null;
  final table = _timedWordTableFor(line);
  final entries = table.entries;
  if (entries.isEmpty) return null;

  if (!table.monotonic) {
    int? last;
    for (final entry in entries) {
      if (positionMs >= entry.start && positionMs < entry.end) {
        last = entry.index;
      }
    }
    return last;
  }

  var lo = 0;
  var hi = entries.length - 1;
  var rightmost = -1;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    if (entries[mid].start <= positionMs) {
      rightmost = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  if (rightmost < 0) return null;

  final prefixMaxEnd = table.prefixMaxEnd;
  for (var k = rightmost; k >= 0; k--) {
    if (prefixMaxEnd[k] <= positionMs) break;
    if (positionMs < entries[k].end) {
      return entries[k].index;
    }
  }
  return null;
}

/// Sequential substring range for [words]\[index] inside [plain].
WordTextRange? wordHighlightRange(
  String plain,
  List<TranscriptWord>? words,
  int index,
) {
  if (words == null || index < 0 || index >= words.length) return null;
  final range = allWordTextRanges(plain, words)[index];
  return range?.isValid == true ? range : null;
}

/// Sequential substring ranges for every word in [plain], aligned with
/// [wordHighlightRange]. Missing tokens are omitted (`null` at that index).
List<WordTextRange?> allWordTextRanges(
  String plain,
  List<TranscriptWord>? words,
) {
  if (words == null || words.isEmpty) return const [];
  final memo = _wordRangesMemo[words];
  if (memo != null && memo.length == words.length && memo.plain == plain) {
    return memo.ranges;
  }
  final out = List<WordTextRange?>.filled(words.length, null);
  var cursor = 0;
  for (var i = 0; i < words.length; i++) {
    final token = words[i].text;
    if (token.isEmpty) continue;
    final at = plain.indexOf(token, cursor);
    if (at < 0) continue;
    final range = WordTextRange(start: at, end: at + token.length);
    cursor = range.end;
    if (range.isValid) out[i] = range;
  }
  _wordRangesMemo[words] = (plain: plain, length: words.length, ranges: out);
  return out;
}

/// Word index whose sequential plain-text range contains [offset], or null.
int? wordIndexAtPlainOffset(
  String plain,
  List<TranscriptWord>? words,
  int offset,
) {
  if (words == null || offset < 0 || offset > plain.length) return null;
  final ranges = allWordTextRanges(plain, words);
  int? last;
  for (var i = 0; i < ranges.length; i++) {
    final range = ranges[i];
    if (range == null || !range.isValid) continue;
    if (offset >= range.start && offset < range.end) {
      last = i;
    }
  }
  return last;
}

/// Media-timeline window `[start, end)` for a timed word, or null if the word
/// is not a seek/loop target (empty text, non-positive duration, or entirely
/// outside the parent line).
({int startMs, int endMs})? wordMediaWindowMs(
  TranscriptLine line,
  int wordIndex,
) {
  final words = line.timeline;
  if (words == null || wordIndex < 0 || wordIndex >= words.length) return null;
  final word = words[wordIndex];
  if (word.text.trim().isEmpty || !_isTimedWord(word)) return null;
  final lineStart = line.startMs;
  final lineEnd = line.startMs + line.durationMs;
  final start = lineStart + (word.startMs ?? 0);
  final end = start + word.durationMs!;
  if (end <= lineStart || start >= lineEnd) return null;
  return (startMs: start, endMs: end);
}

bool _isTimedWord(TranscriptWord word) {
  final duration = word.durationMs;
  return duration != null && duration > 0;
}
