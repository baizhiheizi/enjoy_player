import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'spoken_reference.dart';

/// Zero-based token index for each eSpeak word event, in event order.
///
/// Events map onto [spans] — the app's tokenizer output, which stays the
/// authoritative orthography. Each event takes the nearest span it has not
/// already passed, so swallowed-word neighbours keep their own events,
/// expansion duplicates (`77` + `7`) collapse onto one token, and stale or
/// zero-length events land on the token they were spoken for.
///
/// [positions] are zero-based character offsets into the same string the
/// spans were tokenized from, in UTF-16 code units (convert eSpeak's
/// code-point positions with [utf16Offset] first). Values outside the text
/// clamp to the nearest span.
@internal
List<int> mapWordEventsToTokenSpans(List<WordSpan> spans, List<int> positions) {
  if (spans.isEmpty) return const <int>[];
  final owners = List<int>.filled(positions.length, 0);
  var cursor = 0;
  for (var i = 0; i < positions.length; i++) {
    final position = math.max(0, math.min(spans.last.end, positions[i]));
    var best = cursor;
    var bestDistance = _distanceToSpan(spans[best], position);
    for (var t = cursor + 1; t < spans.length; t++) {
      final distance = _distanceToSpan(spans[t], position);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = t;
      }
      if (spans[t].start > position) break;
    }
    owners[i] = best;
    cursor = best;
  }
  return owners;
}

/// UTF-16 offset table for zero-based code-point positions, or null when
/// every code point of [text] is one UTF-16 unit (the common case).
///
/// eSpeak counts characters (code points) while Dart string indexes count
/// code units, so any non-BMP character (emoji, rare CJK) before a word
/// shifts its event by one without this conversion.
List<int>? codePointOffsetTable(String text) {
  if (text.runes.length == text.length) return null;
  final table = List<int>.filled(text.runes.length + 1, 0);
  var codePoint = 0;
  var unit = 0;
  for (final rune in text.runes) {
    table[codePoint++] = unit;
    unit += rune > 0xFFFF ? 2 : 1;
  }
  table[codePoint] = unit;
  return table;
}

int utf16Offset(List<int>? table, int zeroBasedCodePoint) {
  if (table == null) return zeroBasedCodePoint;
  return table[math.max(0, math.min(table.length - 1, zeroBasedCodePoint))];
}

int _distanceToSpan(WordSpan span, int position) {
  if (position >= span.start && position < span.end) return 0;
  if (position < span.start) return span.start - position;
  return position - (span.end - 1);
}
