/// Extracts embedded subtitle tracks from a media file using ffmpeg.
library;

import 'dart:convert';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:media_kit/media_kit.dart' show SubtitleTrack;
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import 'subtitle_parser.dart';

class EmbeddedSubtitleService {
  const EmbeddedSubtitleService();

  // ignore: prefer_const_constructors
  static final Uuid _uuid = Uuid();

  /// Extracts text lines from [mediaSourceUri] for each [SubtitleTrack] that
  /// is embedded (not loaded from an external URI / data string).
  ///
  /// Already-imported embedded tracks can be excluded by passing their
  /// [existingTrackIndices] so we don't re-extract unchanged tracks.
  Future<List<TranscriptRow>> extractTracks({
    required String mediaId,
    required String mediaSourceUri,
    required List<SubtitleTrack> tracks,
    Set<int> existingTrackIndices = const {},
  }) async {
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
      results.add(
        TranscriptRow(
          id: _uuid.v4(),
          mediaId: mediaId,
          language: track.language ?? 'und',
          source: 'embedded',
          linesJson: json,
          label: label,
          trackIndex: i,
          isEmbedded: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    return results;
  }

  Future<String?> _extractTrackAsSrt(String filePath, int streamIndex) async {
    // ffmpeg stream selector: subtitle stream by 0-based index (0:s:0, 0:s:1, …)
    final command = '-i "$filePath" -map 0:s:$streamIndex -f srt -';
    final session = await FFmpegKit.execute(command);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code)) return null;
    return session.getOutput();
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
