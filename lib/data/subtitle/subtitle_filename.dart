/// Filename helpers for subtitle import and sidecar discovery.
library;

import 'package:path/path.dart' as p;

/// Guess BCP-47-ish code from filename (e.g. `movie.en.srt` → `en`).
String languageHintFromSubtitleFileName(String fileName) {
  final base = p.basenameWithoutExtension(fileName).toLowerCase();
  final m = RegExp(
    r'(?:^|[._-])([a-z]{2}(?:-[a-z]{2,4})?)(?:[._-]|$)',
    caseSensitive: false,
  ).firstMatch(base);
  if (m != null) return m.group(1)!;
  return 'und';
}

/// File base name (no extension) for an exported transcript derived from the
/// media title: characters invalid in desktop filenames become spaces,
/// whitespace runs collapse, and an empty result falls back to `transcript`.
String transcriptExportBaseName(String mediaTitle) {
  final cleaned = mediaTitle
      .replaceAll(_kInvalidFileNameChars, ' ')
      .replaceAll(_kWhitespaceRun, ' ')
      .trim();
  return cleaned.isEmpty ? 'transcript' : cleaned;
}

final RegExp _kInvalidFileNameChars = RegExp(r'[\\/:*?"<>|\x00-\x1f]');
final RegExp _kWhitespaceRun = RegExp(r'\s+');
