/// The transcript enrich worker: picks the owned-align or the YouTube-phonemize
/// path and persists the result.
library;

import 'package:forced_alignment/forced_alignment.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/audio/http_media_download.dart';
import 'package:enjoy_player/data/audio/pcm16k_mono.dart';
import 'package:enjoy_player/data/subtitle/alignment_language.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_enricher_phonemize.dart';
import 'package:enjoy_player/features/transcript/application/transcript_enrichment_state.dart';
import 'package:enjoy_player/features/transcript/application/transcript_owned_alignment.dart';
import 'package:enjoy_player/features/transcript/domain/enrichment_backend.dart';

/// Injectable owned-align / YouTube-phonemize worker. No work until [enrich].
final class TranscriptEnricher {
  TranscriptEnricher({required this.replaceTimeline, required this.backend});

  final ReplaceTimelineFn replaceTimeline;

  /// Decode / align / phonemize / download machinery for this run.
  final EnrichmentBackend backend;

  /// Owned media: timed words + phones. YouTube: untimed IPA labels.
  Future<TranscriptEnrichmentOutcome> enrich({
    required String transcriptId,
    required List<TranscriptLine> lines,
    required String language,
    required bool extractable,
    String? localPath,
    AlignmentCancelToken? cancel,
    EnrichProgressFn? onProgress,
  }) async {
    if (lines.isEmpty) {
      return const TranscriptEnrichmentErr('empty');
    }
    final alignmentLanguage = alignmentLanguageForTranscript(language);
    logNamed('transcript.enrichment').info(
      'enrich start id=$transcriptId lang=$language '
      'mapped=$alignmentLanguage extractable=$extractable lines=${lines.length}',
    );
    if (alignmentLanguage == null) {
      logNamed(
        'transcript.enrichment',
      ).warning('enrich failed: unsupportedLanguage lang=$language');
      return const TranscriptEnrichmentErr('unsupportedLanguage');
    }
    if (cancel?.isCancelled ?? false) {
      return const TranscriptEnrichmentErr('cancelled');
    }

    if (!extractable) {
      return _enrichPhonemes(
        transcriptId: transcriptId,
        lines: lines,
        language: alignmentLanguage,
        cancel: cancel,
        onProgress: onProgress,
      );
    }
    if (localPath == null || localPath.isEmpty) {
      return const TranscriptEnrichmentErr('audioUnavailable');
    }
    var ownedPath = localPath;
    String? downloaded;
    if (pcm16kInputIsRemoteHttp(ownedPath)) {
      try {
        downloaded = await backend.downloadHttp(ownedPath, cancel: cancel);
        ownedPath = downloaded;
      } on Object catch (e, st) {
        if (cancel?.isCancelled ?? false) {
          return const TranscriptEnrichmentErr('cancelled');
        }
        logNamed(
          'transcript.enrichment',
        ).warning('HTTP media download failed: $e', e, st);
        return const TranscriptEnrichmentErr('audioUnavailable');
      }
    }
    try {
      return await _enrichOwned(
        transcriptId: transcriptId,
        lines: lines,
        language: alignmentLanguage,
        localPath: ownedPath,
        cancel: cancel,
        onProgress: onProgress,
      );
    } finally {
      if (downloaded != null) {
        await deleteDownloadedHttpMedia(downloaded);
      }
    }
  }

  Future<TranscriptEnrichmentOutcome> _enrichPhonemes({
    required String transcriptId,
    required List<TranscriptLine> lines,
    required String language,
    AlignmentCancelToken? cancel,
    EnrichProgressFn? onProgress,
  }) async {
    final phonemes = await phonemizeTranscriptLines(
      backend: backend,
      lines: lines,
      language: language,
      cancel: cancel,
      onProgress: onProgress,
    );
    switch (phonemes) {
      case EnrichAttached(lines: final attached):
        try {
          return await _persistIfChanged(
            transcriptId: transcriptId,
            original: lines,
            attached: attached,
            cancel: cancel,
          );
        } on Object catch (e, st) {
          logNamed(
            'transcript.enrichment',
          ).warning('phoneme mapping failed: $e', e, st);
          return const TranscriptEnrichmentErr('internal');
        }
      case EnrichRejected(:final reason):
        return TranscriptEnrichmentErr(reason);
    }
  }

  Future<TranscriptEnrichmentOutcome> _enrichOwned({
    required String transcriptId,
    required List<TranscriptLine> lines,
    required String language,
    required String localPath,
    AlignmentCancelToken? cancel,
    EnrichProgressFn? onProgress,
  }) async {
    final alignment = await alignOwnedMedia(
      backend: backend,
      lines: lines,
      language: language,
      localPath: localPath,
      cancel: cancel,
      onProgress: onProgress,
    );
    switch (alignment) {
      case EnrichAttached(lines: final attached):
        return _persistIfChanged(
          transcriptId: transcriptId,
          original: lines,
          attached: attached,
          cancel: cancel,
        );
      case EnrichRejected(:final reason):
        return TranscriptEnrichmentErr(reason);
    }
  }

  Future<TranscriptEnrichmentOutcome> _persistIfChanged({
    required String transcriptId,
    required List<TranscriptLine> original,
    required List<TranscriptLine> attached,
    AlignmentCancelToken? cancel,
  }) async {
    if (attached.length != original.length) {
      return const TranscriptEnrichmentErr('line count changed');
    }
    final anyNested = attached.any(
      (line) => line.timeline != null && line.timeline!.isNotEmpty,
    );
    if (!anyNested) {
      logNamed(
        'transcript.enrichment',
      ).warning('enrich failed: noNestedWords id=$transcriptId');
      return const TranscriptEnrichmentErr('noNestedWords');
    }
    if (cancel?.isCancelled ?? false) {
      return const TranscriptEnrichmentErr('cancelled');
    }
    final ok = await replaceTimeline(
      transcriptId: transcriptId,
      lines: attached,
    );
    if (!ok) return const TranscriptEnrichmentErr('missingRow');
    return TranscriptEnrichmentOk(attached);
  }
}
