/// YouTube IPA-only phonemization for the transcript enrich.
///
/// YouTube captions carry no audio to align against, so the enrich path
/// phonemizes the cue text and attaches the IPA labels onto the lines.
library;

import 'package:forced_alignment/forced_alignment.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/subtitle/attach_phonemes_to_lines.dart';
import 'package:enjoy_player/data/subtitle/subtitle_markup_parser.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_enrichment_state.dart';
import 'package:enjoy_player/features/transcript/domain/enrichment_backend.dart';

/// Phonemizes [lines] and attaches the IPA labels onto them.
///
/// [onProgress] reports cue-level progress, and [cancel] stops the run before
/// any label is attached.
Future<EnrichAttachment> phonemizeTranscriptLines({
  required EnrichmentBackend backend,
  required List<TranscriptLine> lines,
  required String language,
  AlignmentCancelToken? cancel,
  EnrichProgressFn? onProgress,
}) async {
  onProgress?.call(completed: 0, total: lines.length);
  late final PhonemizeOutcome outcome;
  try {
    outcome = await backend.phonemize(
      texts: [for (final line in lines) plainTextFromSubtitleMarkup(line.text)],
      language: language,
      cancel: cancel,
    );
  } on Object catch (e, st) {
    logNamed('transcript.enrichment').warning('phonemize threw: $e', e, st);
    return const EnrichRejected('internal');
  }
  if (cancel?.isCancelled ?? false) {
    return const EnrichRejected('cancelled');
  }
  switch (outcome) {
    case PhonemizeFailed(:final failure):
      logNamed(
        'transcript.enrichment',
      ).warning('phonemize failed: ${failure.reason.name}');
      return EnrichRejected(failure.reason.name);
    case PhonemizeSuccess(lines: final phonemeLines):
      try {
        final attached = attachPhonemesToLines(lines, phonemeLines);
        onProgress?.call(completed: lines.length, total: lines.length);
        return EnrichAttached(attached);
      } on Object catch (e, st) {
        logNamed(
          'transcript.enrichment',
        ).warning('phoneme mapping failed: $e', e, st);
        return const EnrichRejected('internal');
      }
  }
}
