/// Subtitle serializers — the write-side inverse of `subtitle_parser.dart`.
library;

import 'transcript_line.dart';

/// Subtitle file formats offered by the transcript download flow.
enum SubtitleExportFormat { srt, vtt }

extension SubtitleExportFormatX on SubtitleExportFormat {
  String get fileExtension => switch (this) {
    SubtitleExportFormat.srt => 'srt',
    SubtitleExportFormat.vtt => 'vtt',
  };

  String get mimeType => switch (this) {
    SubtitleExportFormat.srt => 'application/x-subrip',
    SubtitleExportFormat.vtt => 'text/vtt',
  };

  String serialize(List<TranscriptLine> lines) => switch (this) {
    SubtitleExportFormat.srt => serializeSrt(lines),
    SubtitleExportFormat.vtt => serializeVtt(lines),
  };
}

/// SRT (SubRip): 1-based cue index, `HH:MM:SS,mmm` timestamps, blank-line
/// separated. Cues round-trip through `SrtParser` when their text has no
/// blank interior lines. Both serializers emit the per-format minimum for
/// empty input (`''` here, the `WEBVTT` header for [serializeVtt]).
String serializeSrt(List<TranscriptLine> lines) {
  final buffer = StringBuffer();
  var index = 0;
  for (final line in lines) {
    final text = _cueText(line);
    if (text == null) continue;
    index++;
    buffer
      ..writeln(index)
      ..writeln(
        '${_srtTimestamp(line.startMs)} --> '
        '${_srtTimestamp(line.startMs + line.durationMs)}',
      )
      ..writeln(text)
      ..writeln();
  }
  return buffer.toString();
}

/// WebVTT: `WEBVTT` header, `HH:MM:SS.mmm` timestamps, blank-line separated.
/// Cues round-trip through `VttParser` when their text carries no inline
/// `<…>` markup (the parser strips tags on read).
String serializeVtt(List<TranscriptLine> lines) {
  final buffer = StringBuffer('WEBVTT\n\n');
  for (final line in lines) {
    final text = _cueText(line);
    if (text == null) continue;
    buffer
      ..writeln(
        '${_vttTimestamp(line.startMs)} --> '
        '${_vttTimestamp(line.startMs + line.durationMs)}',
      )
      ..writeln(text)
      ..writeln();
  }
  return buffer.toString();
}

/// Null when the cue cannot round-trip through the parsers (blank text or
/// non-positive duration); otherwise the trimmed text with blank interior
/// lines dropped.
String? _cueText(TranscriptLine line) {
  final textLines = line.text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (textLines.isEmpty || line.durationMs <= 0) return null;
  return textLines.join('\n');
}

String _srtTimestamp(int totalMs) =>
    '${_twoDigits(totalMs ~/ 3600000)}:'
    '${_twoDigits((totalMs ~/ 60000) % 60)}:'
    '${_twoDigits((totalMs ~/ 1000) % 60)},'
    '${_threeDigits(totalMs % 1000)}';

String _vttTimestamp(int totalMs) =>
    '${_twoDigits(totalMs ~/ 3600000)}:'
    '${_twoDigits((totalMs ~/ 60000) % 60)}:'
    '${_twoDigits((totalMs ~/ 1000) % 60)}.'
    '${_threeDigits(totalMs % 1000)}';

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _threeDigits(int value) => value.toString().padLeft(3, '0');
