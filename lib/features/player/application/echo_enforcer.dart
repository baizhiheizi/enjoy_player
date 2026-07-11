/// Single-flight coordinator for echo (shadow-reading) playback enforcement.
///
/// Consolidates the two previously uncoordinated enforcement paths (the
/// reactive per-tick correction and the proactive seek clamp) behind one gate
/// so concurrent seeks can't interleave into an audible stutter. Runs the
/// decision on every position event — pause-and-rewind fires within ~50 ms of
/// the segment end instead of up to ~360 ms late under the old 400 ms bucket
/// gate (issue #280, P1/P6/M3).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/domain/echo_window.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';

/// Serializes echo enforcement for one open generation.
///
/// Constructed by [PlayerController] with the same collaborators as
/// [PlayerPositionTracker]. Engine mutations (seek / pause) from both
/// [enforceTick] (reactive) and [clampAndSeek] (proactive) flow through one
/// in-flight slot: while one runs, concurrent ticks are dropped and concurrent
/// clamps wait. [reset] must be called on media switch / clear so a pending
/// pause-and-rewind neither seeks a stale engine nor leaves the slot held.
class EchoEnforcer {
  EchoEnforcer({
    required this.ref,
    required this.getEngine,
    required this.getSession,
    required this.getLines,
  });

  final Ref ref;
  final PlayerEngine Function() getEngine;
  final PlaybackSession? Function() getSession;

  /// Cached primary transcript lines for the open media (cheap read of the
  /// `transcriptLinesForMediaProvider` family while a watcher keeps it warm).
  /// Used to re-derive echo window seconds from line indices at enforcement
  /// time so a re-segmented transcript yields fresh boundaries (M4).
  final List<TranscriptLine>? Function() getLines;

  /// Bumped by [reset]; in-flight ops capture the value at start and bail if
  /// it changed, so a media switch mid-enforcement is a no-op rather than a
  /// stray seek on the next media.
  int _epoch = 0;

  /// Non-null while an enforcement op is running. Set synchronously before the
  /// first await, so the "is something in flight?" check is race-free across
  /// two synchronous position events.
  Future<void>? _inFlight;

  /// Reactive per-tick enforcement. Called on every position event — the
  /// decision is cheap (pure reads), so the segment-end pause fires promptly.
  /// If enforcement is already in flight, this tick is dropped (single-flight):
  /// the in-flight action already corrected playback and the next tick
  /// re-evaluates against the post-correction position.
  Future<void> enforceTick(double positionSeconds) async {
    if (_inFlight != null) return;
    final window = _resolveWindow();
    if (window == null) return;
    final decision = decideEchoPlaybackTime(positionSeconds, window);
    if (decision is EchoOk) return;
    final epoch = _epoch;
    final future = _applyDecision(decision, epoch);
    _inFlight = future;
    try {
      await future;
    } finally {
      if (_inFlight == future) _inFlight = null;
    }
  }

  /// Proactive seek clamp (user tapped a cue / scrubbed). Clamps the requested
  /// target into the echo window and seeks, serialized against reactive ticks.
  /// Returns the (possibly clamped) target actually sought.
  Future<double> clampAndSeek(
    double requestedSeconds, {
    EchoWindow? override,
  }) async {
    while (true) {
      final pending = _inFlight;
      if (pending == null) {
        final window = _resolveWindow(override: override);
        final target = window == null
            ? requestedSeconds
            : clampSeekTimeToEchoWindow(requestedSeconds, window);
        final epoch = _epoch;
        final future = _seek(target, epoch);
        _inFlight = future;
        try {
          await future;
        } finally {
          if (_inFlight == future) _inFlight = null;
        }
        return target;
      }
      // An enforcement is running; wait for it, then re-check.
      await pending;
    }
  }

  /// Neutralizes any in-flight enforcement and releases the slot. Called on
  /// media switch / clear so a pending pause-and-rewind can't seek a stale
  /// engine or hold the slot forever (which would block all future enforcement).
  void reset() {
    _epoch++;
    _inFlight = null;
  }

  Future<void> _applyDecision(EchoPlaybackDecision decision, int epoch) async {
    if (_epoch != epoch) return;
    switch (decision) {
      case EchoOk():
        return;
      case EchoClamp(:final timeSeconds):
        await getEngine().seek(durationFromSeconds(timeSeconds));
      case EchoPauseAndRewind(:final timeSeconds):
        await getEngine().pause();
        // A reset may have landed between pause and seek; don't seek a stale
        // engine onto the next media.
        if (_epoch != epoch) return;
        await getEngine().seek(durationFromSeconds(timeSeconds));
    }
  }

  Future<void> _seek(double targetSeconds, int epoch) async {
    if (_epoch != epoch) return;
    await getEngine().seek(durationFromSeconds(targetSeconds));
  }

  /// Resolves the effective echo window. When [override] is given (a freshly
  /// tapped cue) it wins; otherwise seconds are re-derived from the line
  /// indices + current transcript (single source of truth), falling back to the
  /// cached seconds captured at activation / expand / shrink time when no
  /// transcript is available.
  EchoWindow? _resolveWindow({EchoWindow? override}) {
    final echo = ref.read(echoModeProvider);
    if (!echo.active) return null;
    final durationSeconds = getSession()?.durationSeconds;

    final double startSeconds;
    final double endSeconds;
    if (override != null) {
      startSeconds = override.start;
      endSeconds = override.end;
    } else {
      final lines = getLines();
      startSeconds =
          _lineStartSeconds(lines, echo.startLineIndex) ??
          echo.startTimeSeconds;
      endSeconds =
          _lineEndSeconds(lines, echo.endLineIndex) ?? echo.endTimeSeconds;
    }

    return normalizeEchoWindow((
      active: true,
      startTimeSeconds: startSeconds,
      endTimeSeconds: endSeconds,
      durationSeconds: durationSeconds != null && durationSeconds > 0
          ? durationSeconds
          : null,
    ));
  }

  static double? _lineStartSeconds(List<TranscriptLine>? lines, int index) {
    if (lines == null || index < 0 || index >= lines.length) return null;
    return lines[index].startSeconds;
  }

  static double? _lineEndSeconds(List<TranscriptLine>? lines, int index) {
    if (lines == null || index < 0 || index >= lines.length) return null;
    return lines[index].endSeconds;
  }
}
