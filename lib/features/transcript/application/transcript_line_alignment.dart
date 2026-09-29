/// Aligns primary transcript cues with a secondary track for bilingual UI.
library;

import 'package:enjoy_player/data/subtitle/subtitle_markup_parser.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';

/// Fast matcher for [transcriptMatchSecondary] when many primaries are resolved
/// against the same [secondary] list (e.g. virtualized transcript rows).
///
/// [secondary] is copied and sorted by [TranscriptLine.startSeconds] once.
/// Each [match] bounds its candidate window with one shared lower-bound
/// search instead of scanning from index 0, so materializing a row no longer
/// costs O(len) comparisons on long bilingual transcripts (issue #810 G).
class TranscriptSecondaryMatcher {
  factory TranscriptSecondaryMatcher.from(List<TranscriptLine> secondary) {
    if (secondary.isEmpty) {
      return TranscriptSecondaryMatcher._(const [], 0);
    }
    final copy = List<TranscriptLine>.from(secondary)
      ..sort((a, b) => a.startSeconds.compareTo(b.startSeconds));
    var halfMaxSeconds = 0.0;
    for (final s in copy) {
      final half = (s.endSeconds - s.startSeconds) / 2;
      if (half > halfMaxSeconds) halfMaxSeconds = half;
    }
    return TranscriptSecondaryMatcher._(copy, halfMaxSeconds);
  }
  TranscriptSecondaryMatcher._(this._sec, this._halfMaxSeconds);

  /// Sorted by [TranscriptLine.startSeconds] ascending.
  final List<TranscriptLine> _sec;

  /// Half the longest secondary cue duration. A cue whose start precedes a
  /// primary's start by more than this cannot have its midpoint reach that
  /// start, which is what makes the lower-bound search sound.
  final double _halfMaxSeconds;

  /// Last index with [TranscriptLine.startSeconds] strictly below
  /// [threshold] — the index immediately before
  /// [_firstIndexWithStartAtOrAfter]; `-1` when none.
  int _lastIndexWithStartBefore(double threshold) =>
      _firstIndexWithStartAtOrAfter(threshold) - 1;

  /// First index with [TranscriptLine.startSeconds] at or after [threshold];
  /// [List.length] when every cue starts below it.
  int _firstIndexWithStartAtOrAfter(double threshold) {
    var lo = 0;
    var hi = _sec.length;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (_sec[mid].startSeconds < threshold) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Same semantics as [transcriptMatchSecondary] for a single primary line.
  TranscriptLine? match(TranscriptLine primary) {
    if (_sec.isEmpty) return null;
    final pStart = primary.startSeconds;
    final pEnd = primary.endSeconds;

    final upper = _lastIndexWithStartBefore(pEnd);
    if (upper < 0) return null;
    for (
      var i = _firstIndexWithStartAtOrAfter(pStart - _halfMaxSeconds);
      i <= upper;
      i++
    ) {
      final s = _sec[i];
      final mid = s.startSeconds + (s.endSeconds - s.startSeconds) / 2;
      if (mid >= pStart && mid < pEnd) return s;
    }

    return _sec[upper];
  }
}

/// Secondary line whose midpoint falls within [primary]'s range, else nearest.
TranscriptLine? transcriptMatchSecondary(
  TranscriptLine primary,
  List<TranscriptLine> secondary, {
  TranscriptSecondaryMatcher? matcher,
}) {
  final m = matcher ?? TranscriptSecondaryMatcher.from(secondary);
  return m.match(primary);
}

String echoReferencePlainText(List<TranscriptLine> lines, EchoState echo) {
  if (!echo.active) return '';
  final start = echo.startLineIndex;
  final end = echo.endLineIndex;
  if (start < 0 || end < 0 || start > end) return '';
  final parts = <String>[];
  for (var i = start; i <= end && i < lines.length; i++) {
    final plain = lines[i].text.replaceAll(tagStripRegExp, '').trim();
    if (plain.isNotEmpty) parts.add(plain);
  }
  return parts.join(' ');
}
