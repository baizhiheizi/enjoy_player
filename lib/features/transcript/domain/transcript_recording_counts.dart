/// Overlap between shadow-reading recordings and transcript cue windows.
library;

import 'dart:math' as math;

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';

/// Whether [recording]'s reference window overlaps [line]'s cue window (ms).
///
/// Same rule as web transcript lines and echo-region queries:
/// `max(startA, startB) < min(endA, endB)`.
bool recordingOverlapsLine(RecordingRow recording, TranscriptLine line) {
  final recStart = recording.referenceStart;
  final recEnd = recording.referenceStart + recording.referenceDuration;
  final lineStart = line.startMs;
  final lineEnd = line.startMs + line.durationMs;
  return math.max(recStart, lineStart) < math.min(recEnd, lineEnd);
}

/// Number of entries in [sorted] that are strictly less than [bound].
int _countLessThan(List<int> sorted, int bound) {
  var lo = 0;
  var hi = sorted.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (sorted[mid] < bound) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}

/// Number of entries in [sorted] that are less than or equal to [bound].
int _countLessThanOrEqual(List<int> sorted, int bound) {
  var lo = 0;
  var hi = sorted.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (sorted[mid] <= bound) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}

/// Count overlapping recordings per transcript line index (0-based).
///
/// Equivalent to scanning every recording for every line, but resolved
/// through two sorted projections of the recording windows: sorting the
/// recordings once, then one binary search per line, instead of a nested
/// scan.
Map<int, int> countRecordingsPerLineIndex(
  List<TranscriptLine> lines,
  List<RecordingRow> recordings,
) {
  if (lines.isEmpty || recordings.isEmpty) return const {};

  final starts = <int>[];
  final ends = <int>[];
  for (final r in recordings) {
    if (r.referenceDuration <= 0) continue;
    starts.add(r.referenceStart);
    ends.add(r.referenceStart + r.referenceDuration);
  }

  final counts = <int, int>{};
  if (starts.isEmpty) return counts;

  starts.sort();
  ends.sort();

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.durationMs <= 0) continue;
    final lineStart = line.startMs;
    final lineEnd = lineStart + line.durationMs;
    final count =
        _countLessThan(starts, lineEnd) -
        _countLessThanOrEqual(ends, lineStart);
    if (count > 0) counts[i] = count;
  }
  return counts;
}
