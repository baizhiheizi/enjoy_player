/// Strategy interface + dispatcher for subtitle formats.
library;

import 'package:enjoy_player/core/utils/duration_parsing.dart';
import 'package:enjoy_player/data/subtitle/subtitle_markup_parser.dart'
    show tagStripRegExp;
import 'transcript_line.dart';

/// Splits [content] into lines, normalizing CRLF and lone CR separators.
List<String> _splitLines(String content) {
  if (!content.contains('\r')) return content.split('\n');
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final carriageReturn = line.indexOf('\r');
    if (carriageReturn < 0) continue;
    if (carriageReturn != line.length - 1) return _splitLegacyLines(content);
    final stripped = line.substring(0, carriageReturn);
    if (stripped.contains('\r')) return _splitLegacyLines(content);
    lines[i] = stripped;
  }
  return lines;
}

List<String> _splitLegacyLines(String content) =>
    content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

/// True when [line] is non-empty and holds only ASCII digits.
bool _isAllDigits(String line) {
  if (line.isEmpty) return false;
  for (var i = 0; i < line.length; i++) {
    final unit = line.codeUnitAt(i);
    if (unit < 48 || unit > 57) return false;
  }
  return true;
}

/// Reads the digits of `source[start, end)` as a decimal integer.
int _digitsToInt(String source, int start, int end) {
  var value = 0;
  for (var i = start; i < end; i++) {
    value = value * 10 + (source.codeUnitAt(i) - 48);
  }
  return value;
}

/// Matches an SRT timestamp arrow line (HH:MM:SS,mmm --> HH:MM:SS,mmm).
final RegExp _kSrtArrow = RegExp(
  r'(\d{1,2}:\d{2}:\d{2}[,.]\d{3})\s*-->\s*(\d{1,2}:\d{2}:\d{2}[,.]\d{3})',
);

/// Matches a VTT timestamp arrow line (with optional hours, MM:SS.mmm).
final RegExp _kVttArrow = RegExp(
  r'(\d{1,2}:)?(\d{2}):(\d{2})\.(\d{3})\s*-->\s*'
  r'(\d{1,2}:)?(\d{2}):(\d{2})\.(\d{3})',
);

/// Routes by filename extension or content sniffing.
class SubtitleParserFacade {
  const SubtitleParserFacade();

  static const SrtParser srt = SrtParser();
  static const VttParser vtt = VttParser();

  /// Strips ASS/SSA override tags like {\an8}, {\pos(...)}, {\c&H...&}, etc.
  static String stripAssTags(String text) =>
      text.replaceAll(RegExp(r'\{[^}]*\}'), '').trim();

  List<TranscriptLine> parseWithHint(String content, {String? fileName}) {
    final lower = fileName?.toLowerCase() ?? '';
    if (lower.endsWith('.vtt')) return vtt.parse(content);
    if (lower.endsWith('.srt')) return srt.parse(content);
    if (content.trimLeft().startsWith('WEBVTT')) return vtt.parse(content);
    return srt.parse(content);
  }

  List<TranscriptLine> parse(String content) =>
      parseWithHint(content, fileName: null);
}

/// Minimal SRT parser (supports multi-line cues and CRLF).
class SrtParser {
  const SrtParser();

  List<TranscriptLine> parse(String content) {
    final lines = _splitLines(content);
    final cues = <TranscriptLine>[];
    var i = 0;
    while (i < lines.length) {
      while (i < lines.length && lines[i].trim().isEmpty) {
        i++;
      }
      if (i >= lines.length) break;

      if (_isAllDigits(lines[i].trim())) {
        i++;
      }
      if (i >= lines.length) break;

      final timeLine = lines[i];
      final arrowMatch = _kSrtArrow.firstMatch(timeLine);
      if (arrowMatch == null) {
        i++;
        continue;
      }
      final start = _parseTs(arrowMatch.group(1)!);
      final end = _parseTs(arrowMatch.group(2)!);
      i++;
      final textBuf = StringBuffer();
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        if (textBuf.isNotEmpty) textBuf.writeln();
        textBuf.write(lines[i]);
        i++;
      }
      final text = textBuf.toString().trim();
      if (text.isNotEmpty && end > start) {
        cues.add(
          TranscriptLine(text: text, startMs: start, durationMs: end - start),
        );
      }
    }
    cues.sort((a, b) => a.startMs.compareTo(b.startMs));
    return cues;
  }

  static int _parseTs(String raw) {
    final firstColon = raw.indexOf(':');
    final secondColon = raw.indexOf(':', firstColon + 1);
    final hours = _digitsToInt(raw, 0, firstColon);
    final minutes = _digitsToInt(raw, firstColon + 1, secondColon);
    final seconds = _digitsToInt(raw, secondColon + 1, secondColon + 3);
    final millis = _digitsToInt(raw, secondColon + 4, raw.length);
    if (minutes > 59 || seconds > 59) return 0;
    return hours * 3600000 + minutes * 60000 + seconds * 1000 + millis;
  }
}

/// Minimal WebVTT cue parser (skips headers and NOTE regions).
class VttParser {
  const VttParser();

  List<TranscriptLine> parse(String content) {
    var text = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (text.startsWith('\uFEFF')) text = text.substring(1);

    final lines = text.split('\n');
    var i = 0;
    if (lines.isNotEmpty && lines[0].startsWith('WEBVTT')) {
      i = 1;
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        i++;
      }
      while (i < lines.length && lines[i].trim().isEmpty) {
        i++;
      }
    }

    final cues = <TranscriptLine>[];
    while (i < lines.length) {
      while (i < lines.length && lines[i].trim().isEmpty) {
        i++;
      }
      if (i >= lines.length) break;

      var line = lines[i];
      if (line.startsWith('NOTE') ||
          line.startsWith('STYLE') ||
          line.startsWith('REGION')) {
        i++;
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          i++;
        }
        continue;
      }

      if (!line.contains('-->')) {
        i++;
        if (i >= lines.length) break;
        line = lines[i];
      }

      final arrowMatch = _kVttArrow.firstMatch(line);
      if (arrowMatch == null) {
        i++;
        continue;
      }

      final start = _parseVttTs(
        arrowMatch.group(1),
        arrowMatch.group(2)!,
        arrowMatch.group(3)!,
        arrowMatch.group(4)!,
      );
      final end = _parseVttTs(
        arrowMatch.group(5),
        arrowMatch.group(6)!,
        arrowMatch.group(7)!,
        arrowMatch.group(8)!,
      );

      i++;
      final textBuf = StringBuffer();
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        if (textBuf.isNotEmpty) textBuf.writeln();
        textBuf.write(_stripTags(lines[i]));
        i++;
      }
      final cueText = textBuf.toString().trim();
      if (cueText.isNotEmpty && end > start) {
        cues.add(
          TranscriptLine(
            text: cueText,
            startMs: start,
            durationMs: end - start,
          ),
        );
      }
    }
    cues.sort((a, b) => a.startMs.compareTo(b.startMs));
    return cues;
  }

  static String _stripTags(String l) => l.replaceAll(tagStripRegExp, '').trim();

  static int _parseVttTs(String? hOpt, String mm, String ss, String ms) {
    final h = hOpt != null ? int.tryParse(hOpt.replaceAll(':', '')) ?? 0 : 0;
    return tryParseHmsDuration('$h:$mm:$ss.$ms')?.inMilliseconds ?? 0;
  }
}
