/// Craft-save hook: attach nested word/phone spans via alignSegments.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forced_alignment/forced_alignment.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/audio/pcm16k_mono.dart';
import 'package:enjoy_player/data/subtitle/align_lines_to_pcm.dart';
import 'package:enjoy_player/data/subtitle/alignment_language.dart';
import 'package:enjoy_player/features/transcript/data/transcript_timeline_codec.dart';

typedef DecodePcm16k = Future<Float32List> Function(Uint8List bytes);

/// Maps a Craft synth language onto an alignment catalog tag.
///
/// Delegates to [alignmentLanguageForTranscript].
String? alignmentLanguageForCraft(String language) =>
    alignmentLanguageForTranscript(language);

/// Extract + [alignSegments] + attach for Craft save.
///
/// Always attempts enrichment on a real Craft write. When [timelineJson] is
/// null or extract/alignment fails, returns the original spec 030 JSON
/// unchanged (fail-closed). Pass [enabled] `false` only in tests.
final class CraftTimelineEnricher {
  CraftTimelineEnricher({
    this.enabled = true,
    DecodePcm16k? decodePcm,
    AlignSegmentsFn? alignSegmentsFn,
  }) : _decodePcm = decodePcm ?? decodeToPcm16kMono,
       _alignSegments = alignSegmentsFn ?? _productionAlignSegments;

  /// Production is always on. Tests may pass `false` to skip alignment.
  final bool enabled;
  final DecodePcm16k _decodePcm;
  final AlignSegmentsFn _alignSegments;

  Future<String?> enrich({
    required String? timelineJson,
    required Uint8List audioBytes,
    required String language,
  }) async {
    if (!enabled) return timelineJson;
    if (timelineJson == null) return null;

    final lines = tryDecodeTimelineJson(timelineJson);
    if (lines == null) {
      return _fallback(timelineJson, 'invalid timeline JSON');
    }
    if (lines.isEmpty) {
      return _fallback(timelineJson, 'empty timeline JSON');
    }

    final alignmentLanguage = alignmentLanguageForCraft(language);
    if (alignmentLanguage == null) {
      return _fallback(timelineJson, 'unsupportedLanguage');
    }

    final outcome = await alignLinesToPcm(
      decodePcm: () => _decodePcm(audioBytes),
      language: alignmentLanguage,
      lines: lines,
      align: _alignSegments,
      log: logNamed('craft.enrichment'),
    );

    switch (outcome) {
      case AlignLinesAttached(lines: final attached):
        try {
          return await encodeTimelineJsonGated(attached);
        } on Object catch (e, st) {
          logNamed('craft.enrichment').warning('mapping failed: $e', e, st);
          return timelineJson;
        }
      case AlignLinesRejected(:final reason):
        return _fallback(timelineJson, reason);
      case AlignLinesLineCountChanged():
        return _fallback(timelineJson, 'line count changed');
      case AlignLinesUnavailable():
      case AlignLinesErrored():
      case AlignLinesCancelled():
        return timelineJson;
    }
  }

  String _fallback(String original, String reason) {
    logNamed('craft.enrichment').warning('fallback: $reason');
    return original;
  }
}

Future<AlignmentOutcome> _productionAlignSegments({
  required Float32List sourcePcm16k,
  required String language,
  required List<AlignmentSegment> segments,
}) {
  return alignSegments(
    sourcePcm16k: sourcePcm16k,
    language: language,
    segments: segments,
  );
}

final craftTimelineEnricherProvider = Provider<CraftTimelineEnricher>((ref) {
  return CraftTimelineEnricher();
});
