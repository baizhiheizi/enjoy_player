/// Maps playback time + echo mode to the highlighted transcript cue index.
library;

import 'package:enjoy_player/data/subtitle/transcript_line.dart';

import '../../player/application/echo_mode_provider.dart';

/// Active cue index for [t] in seconds.
///
/// Assumes [lines] are ordered by [TranscriptLine.startSeconds] (normal transcript order).
int transcriptActiveIndex(List<TranscriptLine> lines, double t) {
  if (lines.isEmpty) return -1;

  // Largest index with start <= t (binary search).
  var lo = 0;
  var hi = lines.length - 1;
  var rightmost = -1;
  while (lo <= hi) {
    final mid = (lo + hi) ~/ 2;
    final s = lines[mid].startSeconds;
    if (s <= t) {
      rightmost = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }

  if (rightmost >= 0 && t < lines[rightmost].endSeconds) {
    return rightmost;
  }

  // Gap after last matched start, or before first cue: fall back to last cue with start <= t.
  for (var i = lines.length - 1; i >= 0; i--) {
    if (t >= lines[i].startSeconds) return i;
  }
  return -1;
}

/// When echo mode is on, only cues inside `[startLineIndex, endLineIndex]` may show
/// the active highlight; otherwise [globalActive] is ignored for transcript UI (gaps
/// can resolve to a cue outside the echo segment).
int transcriptActiveIndexForEchoUi(EchoState echo, int globalActive) {
  if (globalActive < 0) return -1;
  if (!echo.active) return globalActive;
  if (globalActive >= echo.startLineIndex &&
      globalActive <= echo.endLineIndex) {
    return globalActive;
  }
  return -1;
}
