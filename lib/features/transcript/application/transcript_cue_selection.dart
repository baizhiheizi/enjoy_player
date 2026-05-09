/// Maps playback time + echo mode to the highlighted transcript cue index.
library;

import 'package:enjoy_player/data/subtitle/transcript_line.dart';

import '../../player/application/echo_mode_provider.dart';

/// Active cue index for [t] in seconds.
int transcriptActiveIndex(List<TranscriptLine> lines, double t) {
  for (var i = 0; i < lines.length; i++) {
    if (t >= lines[i].startSeconds && t < lines[i].endSeconds) return i;
  }
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
