/// Extracts embedded subtitle tracks from a media file using ffmpeg.
library;

import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:media_kit/media_kit.dart' show SubtitleTrack;

import '../../core/ids/enjoy_ids.dart';
import '../../core/logging/log.dart';
import '../db/app_database.dart';
import 'subtitle_parser.dart';

class EmbeddedSubtitleService {
  const EmbeddedSubtitleService();

  static final _log = logNamed('EmbeddedSubtitleService');

  /// Extracts text lines from [mediaSourceUri] for each [SubtitleTrack] that
  /// is embedded (not loaded from an external URI / data string).
  ///
  /// Already-imported embedded tracks can be excluded by passing their
  /// [existingTrackIndices] so we don't re-extract unchanged tracks.
  Future<List<TranscriptRow>> extractTracks({
    required String targetId,
    required String targetTypeDexie,
    required String mediaSourceUri,
    required List<SubtitleTrack> tracks,
    Set<int> existingTrackIndices = const {},
  }) async {
    // ffmpeg_kit_flutter_new has no stable Windows plugin implementation in our
    // current setup, so skip embedded extraction to avoid repeated runtime
    // MissingPluginException spam.
    if (Platform.isWindows) return const [];

    final results = <TranscriptRow>[];
    final localPath = Uri.parse(mediaSourceUri).toFilePath();

    for (var i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      // Skip external/data tracks (not embedded) and already imported ones.
      if (track.uri || track.data) continue;
      if (existingTrackIndices.contains(i)) continue;

      final srtText = await _extractTrackAsSrt(localPath, i);
      if (srtText == null || srtText.trim().isEmpty) continue;

      final cleaned = SubtitleParserFacade.stripAssTags(srtText);
      final lines = const SubtitleParserFacade().parseWithHint(
        cleaned,
        fileName: 'track.srt',
      );
      if (lines.isEmpty) continue;

      final label = _trackLabel(track, i);
      final json = jsonEncode(lines.map((e) => e.toJson()).toList());
      final now = DateTime.now();
      final language = track.language ?? 'und';
      const source = 'official';
      // Deterministic id: disambiguate multiple embedded streams (not in weapp v5 formula).
      final idKey = '${language}_emb$i';
      final id = enjoyTranscriptId(
        targetType: targetTypeDexie,
        targetId: targetId,
        language: idKey,
        source: source,
      );
      results.add(
        TranscriptRow(
          id: id,
          targetType: targetTypeDexie,
          targetId: targetId,
          language: language,
          source: source,
          timelineJson: json,
          referenceId: 'embedded:$i',
          label: label,
          trackIndex: i,
          isEmbedded: true,
          syncStatus: 'local',
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    return results;
  }

  Future<String?> _extractTrackAsSrt(String filePath, int streamIndex) async {
    // ffmpeg stream selector: subtitle stream by 0-based index (0:s:0, 0:s:1, …)
    try {
      final command = '-i "$filePath" -map 0:s:$streamIndex -f srt -';
      final session = await FFmpegKit.execute(command);
      final code = await session.getReturnCode();
      if (!ReturnCode.isSuccess(code)) return null;
      return session.getOutput();
    } catch (error, stackTrace) {
      _log.warning(
        'Embedded subtitle extraction failed for stream $streamIndex',
        error,
        stackTrace,
      );
      return null;
    }
  }

  static String _trackLabel(SubtitleTrack track, int index) {
    final parts = <String>[];
    if (track.title != null && track.title!.isNotEmpty) {
      parts.add(track.title!);
    }
    if (track.language != null &&
        track.language!.isNotEmpty &&
        track.language != 'und') {
      parts.add(track.language!.toUpperCase());
    }
    if (parts.isEmpty) parts.add('Track ${index + 1}');
    return '${parts.join(' · ')} (Embedded)';
  }
}
