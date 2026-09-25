/// Line-level controls: prev / next / replay / echo toggle (maps web `usePlayerControls`).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/subtitle/current_transcript_word.dart';
import '../../../data/subtitle/transcript_line.dart';
import '../../transcript/application/transcript_blur_mode_provider.dart';
import '../../transcript/application/transcript_repository_provider.dart';
import '../../transcript/application/word_practice_session.dart';
import '../../transcript/data/transcript_timeline_codec.dart';
import '../domain/transport_decisions.dart';
import 'echo_mode_provider.dart';
import 'playback_session_persister.dart';
import 'player_controller.dart';

part 'player_interactions.g.dart';

/// Builds the line-control service.
///
/// A state-less service (issue #668): [PlayerInteractions] holds a lines cache
/// but exposes no provider state, so it is handed out by a plain keepAlive
/// [Provider] rather than a `build() => 0` notifier wearing dummy state.
@Riverpod(keepAlive: true)
PlayerInteractions playerInteractions(Ref ref) => PlayerInteractions(ref);

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

/// Line-level controls service: prev / next / replay / echo toggle (maps web
/// `usePlayerControls`).
///
/// Holds no provider state and no decode cache of its own: `linesForRow`
/// memoizes on row identity + content hash in the timeline codec (issue
/// #766), which already covers the re-segmentation case — a re-import
/// changes `timelineJson`, the content hash changes with it, and a fresh
/// decode is served (the issue-#659 guard, now the codec's concern).
class PlayerInteractions {
  PlayerInteractions(this.ref);

  final Ref ref;

  Future<List<TranscriptLine>> _lines() async {
    final mediaId = ref.read(playerControllerProvider)?.mediaId;
    if (mediaId == null) return const [];

    final row = await ref
        .read(transcriptRepositoryProvider)
        .primaryTranscriptRowForMedia(mediaId);
    if (row == null) return const [];
    return ref.read(transcriptRepositoryProvider).linesForRow(row);
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
    final idx = indexOfActiveLine(lines, session.currentTimeSeconds);
    final activeLineStart = idx >= 0
        ? lines[idx].startSeconds
        : session.currentTimeSeconds;
    final target = decideReplayTarget(
      echoActive: echo.active,
      echoStartTimeSeconds: echo.startTimeSeconds,
      activeLineStartSeconds: activeLineStart,
    );
    final seconds = switch (target) {
      ReplayToEchoStart(:final timeSeconds) => timeSeconds,
      ReplayToLineStart(:final timeSeconds) => timeSeconds,
    };
    await ref.read(playerControllerProvider.notifier).seekToSeconds(seconds);
    await ref.read(playerControllerProvider.notifier).play();
  }

  void _clearWordLoop() {
    final mediaId = ref.read(playerControllerProvider)?.mediaId;
    if (mediaId == null) return;
    if (!ref.exists(wordPracticeSessionProvider(mediaId))) return;
    ref.read(wordPracticeSessionProvider(mediaId).notifier).clearLoop();
  }

  Future<void> _seekLine(TranscriptLine line, int index) async {
    _clearWordLoop();
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
    final timeSeconds = decideProgressSeekTime(
      fraction: fraction,
      durationSeconds: session.durationSeconds,
    );
    if (timeSeconds == null) return;
    _clearWordLoop();
    await ref
        .read(playerControllerProvider.notifier)
        .seekToSeconds(timeSeconds);
  }

  Future<void> seekToLine(TranscriptLine line, int index) async {
    await _seekLine(line, index);
  }

  /// Seek to a timed word's media start. Echo already on retargets echo to
  /// [line] (same as line tap) but lands on the word, not the line start.
  Future<void> seekToWord(
    TranscriptLine line,
    int lineIndex,
    int wordIndex, {
    bool keepLoop = false,
  }) async {
    final window = wordMediaWindowMs(line, wordIndex);
    if (window == null) {
      await _seekLine(line, lineIndex);
      return;
    }
    final session = ref.read(playerControllerProvider);
    if (session == null) return;
    final mediaId = session.mediaId;
    final practice = ref.read(wordPracticeSessionProvider(mediaId).notifier);
    if (!keepLoop) practice.clearLoop();
    practice.chooseWord(lineIndex: lineIndex, wordIndex: wordIndex);
    final seconds = window.startMs / 1000.0;
    final echo = ref.read(echoModeProvider);
    if (echo.active) {
      ref
          .read(echoModeProvider.notifier)
          .activate(
            startLineIndex: lineIndex,
            endLineIndex: lineIndex,
            startTimeSeconds: line.startSeconds,
            endTimeSeconds: line.endSeconds,
          );
      await ref
          .read(playerControllerProvider.notifier)
          .seekToSeconds(
            seconds,
            echoWindowForSeekClamp: (
              start: line.startSeconds,
              end: line.endSeconds,
            ),
          );
    } else {
      await ref.read(playerControllerProvider.notifier).seekToSeconds(seconds);
    }
    await ref.read(playerControllerProvider.notifier).play();
  }
}
