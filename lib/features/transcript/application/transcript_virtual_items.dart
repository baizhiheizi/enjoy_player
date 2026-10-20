/// Flat render-item model for the scrollable transcript list: the echoed line
/// range collapses into one card slot, every other line stays its own row.
library;

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';

sealed class TranscriptVirtualItem {
  const TranscriptVirtualItem();
}

class TranscriptVirtualEcho extends TranscriptVirtualItem {
  const TranscriptVirtualEcho(this.startLineIndex, this.endLineIndex);

  final int startLineIndex;
  final int endLineIndex;
}

class TranscriptVirtualLine extends TranscriptVirtualItem {
  const TranscriptVirtualLine(this.lineIndex);

  final int lineIndex;
}

List<TranscriptVirtualItem> buildTranscriptVirtualItems(
  List<TranscriptLine> lines,
  EchoState echo,
) {
  final out = <TranscriptVirtualItem>[];
  var i = 0;
  while (i < lines.length) {
    if (echo.active && i == echo.startLineIndex) {
      out.add(TranscriptVirtualEcho(echo.startLineIndex, echo.endLineIndex));
      i = echo.endLineIndex + 1;
      continue;
    }
    out.add(TranscriptVirtualLine(i));
    i++;
  }
  return out;
}
