/// Enrichment state and outcome vocabulary for the on-demand transcript
/// enrich.
library;

import 'package:flutter/foundation.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';

enum TranscriptEnrichmentPhase { idle, running, failed, succeeded }

@immutable
class TranscriptEnrichmentState {
  const TranscriptEnrichmentState({
    required this.phase,
    this.failureReason,
    this.completed = 0,
    this.total = 0,
  });

  const TranscriptEnrichmentState.idle()
    : phase = TranscriptEnrichmentPhase.idle,
      failureReason = null,
      completed = 0,
      total = 0;

  const TranscriptEnrichmentState.running({this.completed = 0, this.total = 0})
    : phase = TranscriptEnrichmentPhase.running,
      failureReason = null;

  const TranscriptEnrichmentState.succeeded()
    : phase = TranscriptEnrichmentPhase.succeeded,
      failureReason = null,
      completed = 0,
      total = 0;

  const TranscriptEnrichmentState.failed(this.failureReason)
    : phase = TranscriptEnrichmentPhase.failed,
      completed = 0,
      total = 0;

  final TranscriptEnrichmentPhase phase;
  final String? failureReason;

  /// Cues finished in the current run. Meaningful while [isRunning].
  final int completed;

  /// Cue count for the current run. `0` means progress is still unknown.
  final int total;

  bool get isRunning => phase == TranscriptEnrichmentPhase.running;
  bool get isFailed => phase == TranscriptEnrichmentPhase.failed;

  /// `0…1` while running with a known total; otherwise null (indeterminate).
  double? get fraction {
    if (!isRunning || total <= 0) return null;
    return (completed / total).clamp(0.0, 1.0);
  }
}

/// Cue-level progress for a long owned-media align (hundreds of windows).
typedef EnrichProgressFn =
    void Function({required int completed, required int total});

typedef ReplaceTimelineFn =
    Future<bool> Function({
      required String transcriptId,
      required List<TranscriptLine> lines,
    });

sealed class TranscriptEnrichmentOutcome {
  const TranscriptEnrichmentOutcome();
}

final class TranscriptEnrichmentOk extends TranscriptEnrichmentOutcome {
  const TranscriptEnrichmentOk(this.lines);

  final List<TranscriptLine> lines;
}

final class TranscriptEnrichmentErr extends TranscriptEnrichmentOutcome {
  const TranscriptEnrichmentErr(this.reason);

  final String reason;
}

/// The result of one enrichment engine run: the engine either attaches nested
/// spans onto the lines or reports a typed reason.
sealed class EnrichAttachment {
  const EnrichAttachment();
}

/// The engine attached nested spans onto [lines].
final class EnrichAttached extends EnrichAttachment {
  const EnrichAttached(this.lines);

  final List<TranscriptLine> lines;
}

/// The engine could not attach spans; [reason] is the typed failure reason.
final class EnrichRejected extends EnrichAttachment {
  const EnrichRejected(this.reason);

  final String reason;
}
