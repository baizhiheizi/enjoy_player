/// Line-level controls: prev / next / replay / echo toggle (maps web `usePlayerControls`).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/subtitle/transcript_line.dart';
import '../../transcript/application/transcript_repository_provider.dart';
import 'echo_mode_provider.dart';
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
    final idx = indexOfActiveLine(lines, session.currentTimeSeconds);
    final prev = idx > 0 ? idx - 1 : 0;
    await _seekLine(lines[prev], prev);
  }

  Future<void> nextLine() async {
    final lines = await _lines();
    if (lines.isEmpty) return;
    final session = ref.read(playerControllerProvider);
    if (session == null) return;
    final idx = indexOfActiveLine(lines, session.currentTimeSeconds);
    final next = idx < lines.length - 1 ? idx + 1 : lines.length - 1;
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
      ref.read(echoModeProvider.notifier).activate(
            startLineIndex: index,
            endLineIndex: index,
            startTimeSeconds: line.startSeconds,
            endTimeSeconds: line.endSeconds,
          );
    }
    await ref
        .read(playerControllerProvider.notifier)
        .seekToSeconds(line.startSeconds);
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
    ref.read(echoModeProvider.notifier).activate(
          startLineIndex: idx,
          endLineIndex: idx,
          startTimeSeconds: line.startSeconds,
          endTimeSeconds: line.endSeconds,
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
