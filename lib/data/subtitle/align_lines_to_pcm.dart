/// Shared forced-alignment pipeline: decode the media to 16 kHz mono PCM,
/// align the transcript lines against it, and attach the word / phone spans
/// back onto the lines.
///
/// The Craft save hook and the transcript CC-sheet enrich both run this
/// pipeline. Only their failure vocabularies differ — Craft fails closed and
/// keeps the original timeline JSON, the transcript reports a typed reason —
/// so the pipeline lives here and returns a typed outcome each feature maps
/// onto its own result.
library;

import 'dart:typed_data';

import 'package:forced_alignment/forced_alignment.dart';
import 'package:logging/logging.dart';

import 'package:enjoy_player/data/subtitle/attach_alignment_to_lines.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';

/// Aligns pre-timed segments against 16 kHz mono PCM.
typedef AlignSegmentsFn =
    Future<AlignmentOutcome> Function({
      required Float32List sourcePcm16k,
      required String language,
      required List<AlignmentSegment> segments,
    });

/// The result of running the shared alignment pipeline.
sealed class AlignLinesOutcome {
  const AlignLinesOutcome();
}

/// The alignment succeeded; [lines] carry their nested word / phone spans.
final class AlignLinesAttached extends AlignLinesOutcome {
  const AlignLinesAttached(this.lines);

  final List<TranscriptLine> lines;
}

/// The engine reported a failure; [reason] is its reason name.
final class AlignLinesRejected extends AlignLinesOutcome {
  const AlignLinesRejected(this.reason);

  final String reason;
}

/// The PCM could not be decoded, or decoded to an empty buffer.
final class AlignLinesUnavailable extends AlignLinesOutcome {
  const AlignLinesUnavailable();
}

/// The alignment threw, or the result could not be mapped onto the lines.
final class AlignLinesErrored extends AlignLinesOutcome {
  const AlignLinesErrored();
}

/// The run was cancelled before the lines could be attached.
final class AlignLinesCancelled extends AlignLinesOutcome {
  const AlignLinesCancelled();
}

/// The engine returned a different number of lines than it was given.
final class AlignLinesLineCountChanged extends AlignLinesOutcome {
  const AlignLinesLineCountChanged();
}

/// Decodes the media to 16 kHz mono PCM, aligns [lines] against it, and
/// attaches the resulting word / phone spans back onto the lines.
///
/// [decodePcm] supplies the PCM for the caller's media source and [align]
/// runs the engine. [cancel] is checked before the alignment and after it,
/// so a cancelled run never attaches spans. [log] receives the pipeline's
/// diagnostics, keeping the log channel per feature.
Future<AlignLinesOutcome> alignLinesToPcm({
  required Future<Float32List> Function() decodePcm,
  required String language,
  required List<TranscriptLine> lines,
  required AlignSegmentsFn align,
  required Logger log,
  AlignmentCancelToken? cancel,
}) async {
  late final Float32List pcm;
  try {
    pcm = await decodePcm();
  } on Object catch (e, st) {
    log.warning('PCM extract failed: $e', e, st);
    return const AlignLinesUnavailable();
  }
  if (pcm.isEmpty) {
    log.warning('empty PCM');
    return const AlignLinesUnavailable();
  }
  if (cancel?.isCancelled ?? false) {
    return const AlignLinesCancelled();
  }

  final segments = [
    for (var i = 0; i < lines.length; i++)
      AlignmentSegment(
        text: lines[i].text,
        startTime: lines[i].startSeconds,
        endTime: lines[i].endSeconds,
        id: i,
      ),
  ];

  late final AlignmentOutcome outcome;
  try {
    outcome = await align(
      sourcePcm16k: pcm,
      language: language,
      segments: segments,
    );
  } on Object catch (e, st) {
    log.warning('alignSegments threw: $e', e, st);
    return const AlignLinesErrored();
  }
  if (cancel?.isCancelled ?? false) {
    return const AlignLinesCancelled();
  }

  switch (outcome) {
    case AlignmentFailed(:final failure):
      return AlignLinesRejected(failure.reason.name);
    case AlignmentSuccess(:final result):
      try {
        final attached = attachAlignmentToLines(lines, result);
        if (attached.length != lines.length) {
          return const AlignLinesLineCountChanged();
        }
        return AlignLinesAttached(attached);
      } on Object catch (e, st) {
        log.warning('alignment mapping failed: $e', e, st);
        return const AlignLinesErrored();
      }
  }
}
