/// Highlighted transcript cue index for the active playback position.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../player/application/display_position_provider.dart';
import '../../player/application/echo_mode_provider.dart';
import 'transcript_cue_selection.dart';
import 'transcript_lines_provider.dart';

part 'transcript_playback_highlight_provider.g.dart';

/// Current cue index for transcript highlighting (echo-aware).
///
/// Depends on [displayPositionProvider] but consumers should use
/// `.select((i) => i)` so widgets rebuild only when the index **changes**.
@riverpod
int transcriptPlaybackHighlight(Ref ref, String mediaId) {
  final linesAsync = ref.watch(transcriptLinesForMediaProvider(mediaId));
  final lines = linesAsync.value ?? [];
  final echo = ref.watch(echoModeProvider);
  final posAsync = ref.watch(displayPositionProvider);
  final timeSec = switch (posAsync) {
    AsyncData(:final value) => value.inMilliseconds / 1000.0,
    _ => 0.0,
  };
  if (lines.isEmpty) return -1;
  final active = transcriptActiveIndex(lines, timeSec);
  return transcriptActiveIndexForEchoUi(echo, active);
}
