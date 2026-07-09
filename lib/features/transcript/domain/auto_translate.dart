/// Domain models and pure helpers for transcript auto-translate.
library;

import 'package:meta/meta.dart';

import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';

enum AutoTranslateJobStatus {
  idle,
  running,
  paused,
  blocked,
  completed,
  failed,
}

enum AutoTranslateBlockReason {
  signedOut,
  noPrimary,
  sameLanguage,
  credits,
  auth,
  stalePrimary,
  /// Worker/network kept failing; job paused until the learner retries.
  serviceUnavailable,
}

enum AutoTranslateLineStatus { pending, inFlight, ready, failed }

/// UI-facing job state for a media item's auto-translate run.
@immutable
class AutoTranslateUiState {
  const AutoTranslateUiState({
    this.status = AutoTranslateJobStatus.idle,
    this.blockReason,
    this.aiTranscriptId,
    this.primaryTranscriptId,
    this.targetLanguage,
    this.generation = 0,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.readyCount = 0,
    this.priorityAnchorIndex = -1,
    this.failedLineIndexes = const {},
  });

  final AutoTranslateJobStatus status;
  final AutoTranslateBlockReason? blockReason;
  final String? aiTranscriptId;
  final String? primaryTranscriptId;
  final String? targetLanguage;
  final int generation;
  final int pendingCount;
  final int failedCount;
  final int readyCount;
  final int priorityAnchorIndex;

  /// Lines that exhausted retries (or were skipped). Not scheduled again until
  /// the learner explicitly re-translates that line.
  final Set<int> failedLineIndexes;

  bool get isActive =>
      status == AutoTranslateJobStatus.running ||
      status == AutoTranslateJobStatus.paused;

  bool isLineFailed(int lineIndex) => failedLineIndexes.contains(lineIndex);

  AutoTranslateUiState copyWith({
    AutoTranslateJobStatus? status,
    AutoTranslateBlockReason? blockReason,
    bool clearBlockReason = false,
    String? aiTranscriptId,
    bool clearAiTranscriptId = false,
    String? primaryTranscriptId,
    bool clearPrimaryTranscriptId = false,
    String? targetLanguage,
    bool clearTargetLanguage = false,
    int? generation,
    int? pendingCount,
    int? failedCount,
    int? readyCount,
    int? priorityAnchorIndex,
    Set<int>? failedLineIndexes,
  }) {
    return AutoTranslateUiState(
      status: status ?? this.status,
      blockReason: clearBlockReason ? null : (blockReason ?? this.blockReason),
      aiTranscriptId: clearAiTranscriptId
          ? null
          : (aiTranscriptId ?? this.aiTranscriptId),
      primaryTranscriptId: clearPrimaryTranscriptId
          ? null
          : (primaryTranscriptId ?? this.primaryTranscriptId),
      targetLanguage: clearTargetLanguage
          ? null
          : (targetLanguage ?? this.targetLanguage),
      generation: generation ?? this.generation,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      readyCount: readyCount ?? this.readyCount,
      priorityAnchorIndex: priorityAnchorIndex ?? this.priorityAnchorIndex,
      failedLineIndexes: failedLineIndexes ?? this.failedLineIndexes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutoTranslateUiState &&
          other.status == status &&
          other.blockReason == blockReason &&
          other.aiTranscriptId == aiTranscriptId &&
          other.primaryTranscriptId == primaryTranscriptId &&
          other.targetLanguage == targetLanguage &&
          other.generation == generation &&
          other.pendingCount == pendingCount &&
          other.failedCount == failedCount &&
          other.readyCount == readyCount &&
          other.priorityAnchorIndex == priorityAnchorIndex &&
          _setEquals(other.failedLineIndexes, failedLineIndexes);

  @override
  int get hashCode => Object.hash(
    status,
    blockReason,
    aiTranscriptId,
    primaryTranscriptId,
    targetLanguage,
    generation,
    pendingCount,
    failedCount,
    readyCount,
    priorityAnchorIndex,
    Object.hashAllUnordered(failedLineIndexes),
  );
}

bool _setEquals(Set<int> a, Set<int> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  return a.containsAll(b);
}

/// Deterministic AI translation track id for a media + target language.
String autoTranslateAiTrackId({
  required String targetType,
  required String mediaId,
  required String targetLanguage,
}) =>
    enjoyTranscriptId(
      targetType: targetType,
      targetId: mediaId,
      language: targetLanguage,
      source: 'ai',
    );

/// Orders pending line indexes by distance from [anchorIndex] (ties: lower index first).
List<int> orderPendingLineIndexes({
  required int anchorIndex,
  required List<int> pending,
}) {
  if (pending.isEmpty) return const [];
  final copy = List<int>.from(pending);
  copy.sort((a, b) {
    final da = (a - anchorIndex).abs();
    final db = (b - anchorIndex).abs();
    if (da != db) return da.compareTo(db);
    return a.compareTo(b);
  });
  return copy;
}

/// Returns indexes with empty [text] in [aiLines], excluding [exclude].
List<int> pendingLineIndexes(
  List<TranscriptLine> aiLines, {
  Set<int> exclude = const {},
}) {
  final out = <int>[];
  for (var i = 0; i < aiLines.length; i++) {
    if (exclude.contains(i)) continue;
    if (aiLines[i].text.trim().isEmpty) out.add(i);
  }
  return out;
}

/// Counts non-empty translated lines.
int readyLineCount(List<TranscriptLine> aiLines) {
  var n = 0;
  for (final line in aiLines) {
    if (line.text.trim().isNotEmpty) n++;
  }
  return n;
}

/// Whether [aiLines] no longer matches [primaryLines] timings/count or [primaryId].
bool isAutoTranslateTimelineStale({
  required String? referencePrimaryId,
  required String primaryId,
  required List<TranscriptLine> primaryLines,
  required List<TranscriptLine> aiLines,
}) {
  if (referencePrimaryId != primaryId) return true;
  if (primaryLines.length != aiLines.length) return true;
  for (var i = 0; i < primaryLines.length; i++) {
    if (primaryLines[i].startMs != aiLines[i].startMs ||
        primaryLines[i].durationMs != aiLines[i].durationMs) {
      return true;
    }
  }
  return false;
}

/// Builds a skeleton timeline mirroring primary timings with empty text.
List<TranscriptLine> buildAutoTranslateSkeleton(List<TranscriptLine> primaryLines) {
  return primaryLines
      .map(
        (p) => TranscriptLine(
          text: '',
          startMs: p.startMs,
          durationMs: p.durationMs,
        ),
      )
      .toList();
}

/// Max concurrent in-flight translation requests per job.
const kAutoTranslateMaxConcurrency = 2;

/// Per-line retry budget before marking failed (no further auto-scheduling).
const kAutoTranslateMaxLineRetries = 3;

/// Base backoff for line retries.
const kAutoTranslateRetryBaseDelay = Duration(seconds: 1);

/// Consecutive worker/network failures before pausing the whole job.
const kAutoTranslateCircuitBreakerThreshold = 5;

/// Pause duration after the circuit breaker trips.
const kAutoTranslateCircuitBreakerCooldown = Duration(seconds: 30);
