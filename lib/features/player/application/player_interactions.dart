/// Line-level controls: prev / next / replay / echo toggle (maps web `usePlayerControls`).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/subtitle/transcript_line.dart';
import '../../transcript/application/transcript_blur_mode_provider.dart';
import '../../transcript/application/transcript_repository_provider.dart';
import 'echo_mode_provider.dart';
import 'playback_session_persister.dart';
import 'player_controller.dart';

part 'player_interactions.g.dart';

int indexOfActiveLine(List<TranscriptLine> lines, double t) {
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (t >= line.startSeconds && t < line.endSeconds) {
      return i;
    }
  }
  for (var i = lines.length - 1; i >= 0; i--) {
    if (t >= lines[i].startSeconds) return i;
  }
  return -1;
}

/// Target line index for [PlayerInteractions.nextLine].
///
/// When echo is active, follow the echo segment ([EchoState.endLineIndex]), not
/// [currentTimeSeconds]. Playback can sit on the cue after the segment (exclusive
/// end boundary) while the UI still shows the previous line as the echo region.
int nextLineNavigationIndex({
  required EchoState echo,
  required List<TranscriptLine> lines,
  required double currentTimeSeconds,
}) {
  if (echo.active && echo.endLineIndex >= 0) {
    final next = echo.endLineIndex + 1;
    return next < lines.length ? next : lines.length - 1;
  }
  final idx = indexOfActiveLine(lines, currentTimeSeconds);
  return idx < lines.length - 1 ? idx + 1 : lines.length - 1;
}

/// Target line index for [PlayerInteractions.prevLine] (same echo anchoring rules).
int prevLineNavigationIndex({
  required EchoState echo,
  required List<TranscriptLine> lines,
  required double currentTimeSeconds,
}) {
  if (echo.active && echo.startLineIndex >= 0) {
    final prev = echo.startLineIndex - 1;
    return prev > 0 ? prev : 0;
  }
  final idx = indexOfActiveLine(lines, currentTimeSeconds);
  return idx > 0 ? idx - 1 : 0;
}

@Riverpod(keepAlive: true)
class PlayerInteractions extends _$PlayerInteractions {
  @override
  int build() => 0;

  Future<List<TranscriptLine>> _lines() async {
    final session = ref.read(playerControllerProvider);
    final mediaId = session?.mediaId;
    if (mediaId == null) return [];
    final repo = ref.read(transcriptRepositoryProvider);
    final row = await repo.primaryTranscriptRowForMedia(mediaId);
    if (row == null) return [];
    return repo.linesForRow(row);
  }

  Future<void> prevLine() async {
    final lines = await _lines();
    if (lines.isEmpty) return;
    final session = ref.read(playerControllerProvider);
    if (session == null) return;
    final echo = ref.read(echoModeProvider);
    final prev = prevLineNavigationIndex(
      echo: echo,
      lines: lines,
      currentTimeSeconds: session.currentTimeSeconds,
    );
    await _seekLine(lines[prev], prev);
  }

  Future<void> nextLine() async {
    final lines = await _lines();
    if (lines.isEmpty) return;
    final session = ref.read(playerControllerProvider);
    if (session == null) return;
    final echo = ref.read(echoModeProvider);
    final next = nextLineNavigationIndex(
      echo: echo,
      lines: lines,
      currentTimeSeconds: session.currentTimeSeconds,
    );
    await _seekLine(lines[next], next);
  }

  Future<void> replayLine() async {
    final lines = await _lines();
    final session = ref.read(playerControllerProvider);
    if (session == null || lines.isEmpty) return;
    final echo = ref.read(echoModeProvider);
    final seconds = echo.active
        ? echo.startTimeSeconds
        : () {
            final idx = indexOfActiveLine(lines, session.currentTimeSeconds);
            if (idx < 0) return session.currentTimeSeconds;
            return lines[idx].startSeconds;
          }();
    await ref.read(playerControllerProvider.notifier).seekToSeconds(seconds);
    await ref.read(playerControllerProvider.notifier).play();
  }

  Future<void> _seekLine(TranscriptLine line, int index) async {
    final echo = ref.read(echoModeProvider);
    if (echo.active) {
      ref
          .read(echoModeProvider.notifier)
          .activate(
            startLineIndex: index,
            endLineIndex: index,
            startTimeSeconds: line.startSeconds,
            endTimeSeconds: line.endSeconds,
          );
      await ref
          .read(playerControllerProvider.notifier)
          .seekToSeconds(
            line.startSeconds,
            echoWindowForSeekClamp: (
              start: line.startSeconds,
              end: line.endSeconds,
            ),
          );
    } else {
      await ref
          .read(playerControllerProvider.notifier)
          .seekToSeconds(line.startSeconds);
    }
    await ref.read(playerControllerProvider.notifier).play();
  }

  Future<void> toggleEcho() async {
    final lines = await _lines();
    final session = ref.read(playerControllerProvider);
    if (session == null || lines.isEmpty) return;
    final echo = ref.read(echoModeProvider);
    if (echo.active) {
      ref.read(echoModeProvider.notifier).deactivate();
      return;
    }
    final idx = indexOfActiveLine(lines, session.currentTimeSeconds);
    if (idx < 0) return;
    final line = lines[idx];
    ref
        .read(echoModeProvider.notifier)
        .activate(
          startLineIndex: idx,
          endLineIndex: idx,
          startTimeSeconds: line.startSeconds,
          endTimeSeconds: line.endSeconds,
        );
  }

  /// Toggles listening-focus (transcript blur) practice for the open media.
  ///
  /// Allows turning blur off even when there are no transcript lines so the
  /// user can always exit the mode (same enable rule as the transport button).
  Future<void> toggleBlur() async {
    final session = ref.read(playerControllerProvider);
    if (session == null) return;
    final blur = ref.read(transcriptBlurModeProvider);
    if (blur) {
      ref.read(transcriptBlurModeProvider.notifier).deactivate();
    } else {
      final lines = await _lines();
      if (lines.isEmpty) return;
      ref.read(transcriptBlurModeProvider.notifier).activate();
    }
    // Persist immediately so a quick media switch cannot race a debounced
    // write against the newly restored blur state for a different target.
    await ref
        .read(playbackSessionPersisterProvider)
        .writeNow(
          mediaId: session.mediaId,
          dexieTargetType: session.dexieTargetType,
          session: session,
        );
  }

  Future<void> expandEchoBackward() async {
    final echo = ref.read(echoModeProvider);
    if (!echo.active) return;
    final lines = await _lines();
    if (lines.isEmpty) return;
    ref.read(echoModeProvider.notifier).expandEchoBackward(lines);
  }

  Future<void> expandEchoForward() async {
    final echo = ref.read(echoModeProvider);
    if (!echo.active) return;
    final lines = await _lines();
    if (lines.isEmpty) return;
    ref.read(echoModeProvider.notifier).expandEchoForward(lines);
  }

  Future<void> shrinkEchoBackward() async {
    final echo = ref.read(echoModeProvider);
    if (!echo.active) return;
    final lines = await _lines();
    if (lines.isEmpty) return;
    ref.read(echoModeProvider.notifier).shrinkEchoBackward(lines);
  }

  Future<void> shrinkEchoForward() async {
    final echo = ref.read(echoModeProvider);
    if (!echo.active) return;
    final lines = await _lines();
    if (lines.isEmpty) return;
    ref.read(echoModeProvider.notifier).shrinkEchoForward(lines);
  }

  Future<void> seekToProgressFraction(double fraction) async {
    final session = ref.read(playerControllerProvider);
    if (session == null) return;
    final d = session.durationSeconds;
    if (d <= 0) return;
    final clamped = fraction.clamp(0.0, 1.0);
    final target = (d * clamped).clamp(0.0, d).toDouble();
    await ref.read(playerControllerProvider.notifier).seekToSeconds(target);
  }

  Future<void> seekToLine(TranscriptLine line, int index) async {
    await _seekLine(line, index);
  }
}
