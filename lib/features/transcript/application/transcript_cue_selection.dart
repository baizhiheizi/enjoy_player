/// Echo-window gating for the highlighted transcript cue index.
///
/// The cue lookup itself lives in the timeline codec
/// (`transcript_timeline_codec.dart`, issue #766); this file owns only the
/// UI policy that decides whether the codec's global active index may show
/// the highlight while echo mode restricts the visible region.
library;

import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';

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
