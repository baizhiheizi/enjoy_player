/// Resolve `ffmpeg` and parse its `-i` probe output (stderr).
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Shared helpers for `ffmpeg -hide_banner -i …` stderr parsing.
class FfmpegMediaProbe {
  FfmpegMediaProbe._();

  /// Bundled `ffmpeg.exe` next to the app, or `ffmpeg` on PATH (Windows),
  /// or `ffmpeg` on PATH elsewhere.
  static Future<String?> resolveFfmpegExecutable() async {
    if (Platform.isWindows) {
      final bundled = p.join(
        p.dirname(Platform.resolvedExecutable),
        'ffmpeg.exe',
      );
      if (File(bundled).existsSync()) return bundled;
      try {
        final r = await Process.run('ffmpeg', ['-version']);
        if (r.exitCode == 0) return 'ffmpeg';
      } on Object catch (_) {}
      return null;
    }
    try {
      final r = await Process.run('ffmpeg', ['-version']);
      if (r.exitCode == 0) return 'ffmpeg';
    } on Object catch (_) {}
    return null;
  }

  /// Path for local `file:` URIs; otherwise returns [mediaSourceUri] (e.g. https).
  static String mediaInputForFfmpeg(String mediaSourceUri) {
    final uri = Uri.tryParse(mediaSourceUri);
    if (uri != null && uri.isScheme('file')) {
      return uri.toFilePath(windows: Platform.isWindows);
    }
    return mediaSourceUri;
  }

  /// `Duration: HH:MM:SS.xx` from ffmpeg identify stderr.
  static int? parseDurationSeconds(String stderr) {
    final m = RegExp(
      r'Duration:\s*(\d+):(\d+):(\d+)\.(\d+)',
    ).firstMatch(stderr);
    if (m == null) return null;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final s = int.parse(m.group(3)!);
    return h * 3600 + min * 60 + s;
  }

  /// ffmpeg stderr lines, e.g.
  /// `Stream #0:3(eng): Subtitle: subrip` or
  /// `Stream #0:3[0x1200](eng): Subtitle: hdmv_pgs_subtitle`.
  static final _subtitleStreamLine = RegExp(
    r'Stream #0:\d+(?:\[[^\]]*\])?(?:\(([^)]*)\))?\s*:\s*Subtitle\s*:',
    caseSensitive: false,
    multiLine: true,
  );

  /// Number of subtitle streams, in `0:s:N` order.
  static int countSubtitleStreams(String stderr) =>
      _subtitleStreamLine.allMatches(stderr).length;

  /// Optional language tags from parentheses, same order as [countSubtitleStreams].
  static List<String?> subtitleLanguageHints(String stderr) =>
      _subtitleStreamLine.allMatches(stderr).map((m) {
        final raw = m.group(1)?.trim();
        if (raw == null || raw.isEmpty) return null;
        final lower = raw.toLowerCase();
        if (lower == 'und' || lower == 'unknown') return null;
        return lower;
      }).toList();

  static Future<String?> loadIdentifyStderr(
    String ffmpegExecutable,
    String input,
  ) async {
    try {
      final r = await Process.run(ffmpegExecutable, [
        '-hide_banner',
        '-i',
        input,
      ], stderrEncoding: utf8);
      return r.stderr as String?;
    } on Object catch (_) {
      return null;
    }
  }
}
