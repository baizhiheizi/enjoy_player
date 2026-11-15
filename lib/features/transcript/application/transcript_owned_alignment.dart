/// Owned-media alignment: turns a local audio file and cue lines into
/// timeline-attached lines.
///
/// A short clip is aligned in one whole-file pass; a long one is aligned
/// per cue against a padded window, because the engine's whole-clip path
/// rejects clips longer than `kMaxWholeClipSeconds`. Both strategies return
/// the attached lines or a typed rejection reason — persisting the result is
/// the caller's job.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:forced_alignment/forced_alignment.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/subtitle/align_lines_to_pcm.dart';
import 'package:enjoy_player/data/subtitle/attach_alignment_to_lines.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_enrichment_state.dart';
import 'package:enjoy_player/features/transcript/domain/enrichment_backend.dart';

/// Aligns owned media against [lines] and attaches the resulting word /
/// phone spans back onto them.
///
/// Clips up to `kMaxWholeClipSeconds` run the whole-file pipeline; longer ones
/// fall back to the per-cue windowed strategy. [onProgress] reports cue-level
/// progress, and [cancel] stops the run before any span is attached.
Future<EnrichAttachment> alignOwnedMedia({
  required EnrichmentBackend backend,
  required List<TranscriptLine> lines,
  required String language,
  required String localPath,
  AlignmentCancelToken? cancel,
  EnrichProgressFn? onProgress,
}) async {
  final lastEnd = lines
      .map((l) => l.endSeconds)
      .fold<double>(0, (a, b) => a > b ? a : b);
  if (lastEnd <= kMaxWholeClipSeconds) {
    return _alignWholeFile(
      backend: backend,
      lines: lines,
      language: language,
      localPath: localPath,
      cancel: cancel,
      onProgress: onProgress,
    );
  }
  return _alignWindows(
    backend: backend,
    lines: lines,
    language: language,
    localPath: localPath,
    cancel: cancel,
    onProgress: onProgress,
  );
}

Future<EnrichAttachment> _alignWholeFile({
  required EnrichmentBackend backend,
  required List<TranscriptLine> lines,
  required String language,
  required String localPath,
  AlignmentCancelToken? cancel,
  EnrichProgressFn? onProgress,
}) async {
  onProgress?.call(completed: 0, total: lines.length);

  final outcome = await alignLinesToPcm(
    decodePcm: () => backend.decodeFile(localPath),
    language: language,
    lines: lines,
    align: ({required sourcePcm16k, required language, required segments}) =>
        backend.alignSegments(
          sourcePcm16k: sourcePcm16k,
          language: language,
          segments: segments,
          cancel: cancel,
        ),
    log: logNamed('transcript.enrichment'),
    cancel: cancel,
  );

  switch (outcome) {
    case AlignLinesAttached(lines: final attached):
      onProgress?.call(completed: lines.length, total: lines.length);
      return EnrichAttached(attached);
    case AlignLinesRejected(:final reason):
      return EnrichRejected(reason);
    case AlignLinesUnavailable():
      return const EnrichRejected('audioUnavailable');
    case AlignLinesErrored():
      return const EnrichRejected('internal');
    case AlignLinesCancelled():
      return const EnrichRejected('cancelled');
    case AlignLinesLineCountChanged():
      return const EnrichRejected('line count changed');
  }
}

Future<EnrichAttachment> _alignWindows({
  required EnrichmentBackend backend,
  required List<TranscriptLine> lines,
  required String language,
  required String localPath,
  AlignmentCancelToken? cancel,
  EnrichProgressFn? onProgress,
}) async {
  onProgress?.call(completed: 0, total: lines.length);
  final segments = <TimelineEntry>[];
  for (var i = 0; i < lines.length; i++) {
    if (cancel?.isCancelled ?? false) {
      return const EnrichRejected('cancelled');
    }
    try {
      final line = lines[i];
      if (line.text.trim().isEmpty) continue;
      final start = math.max(0.0, line.startSeconds - kCuePadSeconds);
      final duration =
          (line.endSeconds - line.startSeconds) + (2 * kCuePadSeconds);
      late final Float32List pcm;
      try {
        pcm = await backend.decodeWindow(
          pathOrUri: localPath,
          startSeconds: start,
          durationSeconds: duration <= 0 ? kMinAudioSeconds : duration,
        );
      } on Object catch (e, st) {
        logNamed(
          'transcript.enrichment',
        ).warning('window extract failed for cue $i: $e', e, st);
        continue;
      }
      if (pcm.isEmpty) continue;

      late final AlignmentOutcome outcome;
      try {
        outcome = await backend.align(
          sourcePcm16k: pcm,
          transcript: line.text,
          language: language,
          cancel: cancel,
          timeOffset: start,
        );
      } on Object catch (e, st) {
        logNamed(
          'transcript.enrichment',
        ).warning('align threw for cue $i: $e', e, st);
        continue;
      }
      switch (outcome) {
        case AlignmentFailed():
          continue;
        case AlignmentSuccess(:final result):
          final tagged = result.timeline.where(
            (e) => e.type == TimelineEntryType.segment,
          );
          if (tagged.isEmpty) {
            segments.add(
              TimelineEntry(
                type: TimelineEntryType.segment,
                text: line.text,
                startTime: line.startSeconds,
                endTime: line.endSeconds,
                id: i,
                timeline: result.wordTimeline,
              ),
            );
          } else {
            segments.add(tagged.first.copyWithId(i));
          }
      }
    } finally {
      onProgress?.call(completed: i + 1, total: lines.length);
    }
  }

  if (segments.isEmpty) {
    return const EnrichRejected('internal');
  }
  final attached = attachAlignmentToLines(
    lines,
    AlignmentResult(
      timeline: segments,
      wordTimeline: const [],
      transcript: lines.map((l) => l.text).join(' '),
      language: language,
      durationSeconds: lines.last.endSeconds,
    ),
  );
  return EnrichAttached(attached);
}

extension on TimelineEntry {
  TimelineEntry copyWithId(int id) {
    return TimelineEntry(
      type: type,
      text: text,
      startTime: startTime,
      endTime: endTime,
      timeline: timeline,
      confidence: confidence,
      id: id,
    );
  }
}
