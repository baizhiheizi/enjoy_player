/// Pure decisions for exporting the active Echo loop as a media clip
/// (canvas v30 "Export the loop as a clip…" in the ⋯ More menu): the loop
/// range derivation, the output file name, and the FFmpeg invocation shape.
///
/// The FFmpeg run itself lives in `loop_clip_export_runner.dart`; the user
/// flow (save dialog / share sheet) in `presentation/loop_clip_export_flow.dart`.
library;

import 'package:enjoy_player/data/files/ffmpeg_media_probe.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/domain/echo_window.dart';

/// One export job: trim `[startSeconds, startSeconds + durationSeconds)`
/// from [inputPath] into [outputPath].
class LoopClipExportRequest {
  const LoopClipExportRequest({
    required this.inputPath,
    required this.outputPath,
    required this.startSeconds,
    required this.durationSeconds,
    required this.video,
  });

  /// Local file path or direct `http(s)` media URL (never a YouTube page).
  final String inputPath;
  final String outputPath;
  final double startSeconds;
  final double durationSeconds;

  /// Video export (`.mp4`); `false` exports the audio track (`.m4a`).
  final bool video;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoopClipExportRequest &&
          other.inputPath == inputPath &&
          other.outputPath == outputPath &&
          other.startSeconds == startSeconds &&
          other.durationSeconds == durationSeconds &&
          other.video == video;

  @override
  int get hashCode =>
      Object.hash(inputPath, outputPath, startSeconds, durationSeconds, video);
}

/// Effective loop range for a clip export, mirroring `EchoEnforcer`'s
/// derivation: transcript line bounds win over the cached seconds, then the
/// window is normalized (clamped to the media duration, widened to the
/// minimum playable length, dropped when inverted). Returns `null` when
/// nothing is exportable.
EchoWindow? resolveLoopClipRange({
  required bool echoActive,
  required double startTimeSeconds,
  required double endTimeSeconds,
  int startLineIndex = -1,
  int endLineIndex = -1,
  List<TranscriptLine>? lines,
  double? durationSeconds,
}) {
  final startSeconds =
      _lineStartSeconds(lines, startLineIndex) ?? startTimeSeconds;
  final endSeconds = _lineEndSeconds(lines, endLineIndex) ?? endTimeSeconds;
  return normalizeEchoWindow((
    active: echoActive,
    startTimeSeconds: startSeconds,
    endTimeSeconds: endSeconds,
    durationSeconds: durationSeconds != null && durationSeconds > 0
        ? durationSeconds
        : null,
  ));
}

double? _lineStartSeconds(List<TranscriptLine>? lines, int index) {
  if (lines == null || index < 0 || index >= lines.length) return null;
  return lines[index].startSeconds;
}

double? _lineEndSeconds(List<TranscriptLine>? lines, int index) {
  if (lines == null || index < 0 || index >= lines.length) return null;
  return lines[index].endSeconds;
}

const String _fallbackClipBaseName = 'loop-clip';
const int _maxClipBaseNameLength = 80;

/// Suggested file name for the exported clip, e.g.
/// `The Ferry at Six-clip-12.5-18s.mp4`. File-system-unsafe title characters
/// become spaces; an empty title falls back to `loop-clip`; the range is
/// absolute start–end seconds.
String loopClipFileName({
  required String title,
  required bool video,
  required EchoWindow window,
}) {
  final base = _sanitizeClipBaseName(title);
  final range =
      '${_formatSeconds(window.start)}-${_formatSeconds(window.end)}s';
  return '$base-clip-$range.${video ? 'mp4' : 'm4a'}';
}

String _sanitizeClipBaseName(String title) {
  final cleaned = title
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) return _fallbackClipBaseName;
  if (cleaned.length <= _maxClipBaseNameLength) return cleaned;
  return cleaned.substring(0, _maxClipBaseNameLength).trim();
}

String _formatSeconds(double seconds) {
  final rounded = (seconds * 10).roundToDouble() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.round().toString()
      : rounded.toStringAsFixed(1);
}

const String _networkProtocolWhitelist = 'file,http,https,tcp,tls,crypto';

/// Whether [input] is an `http(s)` media URL rather than a local file path.
bool loopClipInputIsNetwork(String input) {
  final lower = input.trimLeft().toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

/// The FFmpeg argv for [request] (the CLI path on Windows / Linux). The
/// output format is pinned (`mp4` / `ipod`) so a save dialog that drops the
/// suggested extension still encodes; the loop is re-encoded (libx264 +
/// AAC / AAC only) so cut points are exact rather than keyframe-snapped.
List<String> buildLoopClipFfmpegArgs(LoopClipExportRequest request) {
  final network = loopClipInputIsNetwork(request.inputPath);
  return [
    '-nostdin',
    '-hide_banner',
    '-loglevel',
    'error',
    '-y',
    '-ss',
    request.startSeconds.toStringAsFixed(4),
    if (network) ...['-protocol_whitelist', _networkProtocolWhitelist],
    '-i',
    request.inputPath,
    '-t',
    request.durationSeconds.toStringAsFixed(4),
    if (request.video) ...[
      '-map',
      '0:v:0?',
      '-map',
      '0:a:0?',
      '-c:v',
      'libx264',
      '-preset',
      'veryfast',
      '-crf',
      '20',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
      '-movflags',
      '+faststart',
      '-f',
      'mp4',
    ] else ...[
      '-vn',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
      '-f',
      'ipod',
    ],
    request.outputPath,
  ];
}

/// The FFmpegKit command string for [request] (Android / iOS / macOS),
/// quoting paths with whitespace or quotes via the shared [shellEscape] rule
/// so it matches [buildLoopClipFfmpegArgs] argument for argument.
String buildLoopClipFfmpegCommand(LoopClipExportRequest request) =>
    buildLoopClipFfmpegArgs(request).map(shellEscape).join(' ');
