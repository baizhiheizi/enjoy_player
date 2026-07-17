/// Builds transcript context for lookup AI and vocabulary persistence (web parity).
library;

import 'dart:math' as math;

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/lookup/application/sentence_boundaries.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_cue_selection.dart';

/// Resolved context span: joined text plus inclusive line indexes.
typedef VocabularyContextSpan = ({
  String text,
  int startLineIndex,
  int endLineIndex,
});

String plainCueText(String raw) {
  return raw
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

({int startArrayIndex, int endArrayIndex}) expandContextLines(
  int startArrayIndex,
  int endArrayIndex,
  int lineCount,
) {
  var expandedStart = startArrayIndex;
  var expandedEnd = endArrayIndex;

  final backwardExpansion = startArrayIndex < 3 ? startArrayIndex : 3;
  for (var i = 0; i < backwardExpansion; i++) {
    if (expandedStart > 0) expandedStart--;
  }

  final forwardExpansion = math.min(3, lineCount - 1 - endArrayIndex);
  for (var i = 0; i < forwardExpansion; i++) {
    if (expandedEnd < lineCount - 1) expandedEnd++;
  }

  return (startArrayIndex: expandedStart, endArrayIndex: expandedEnd);
}

/// Returns surrounding transcript text for contextual translation (LLM).
String? buildVocabularyContext({
  required List<TranscriptLine> lines,
  required EchoState echo,
  required double currentTimeSeconds,
  required String primaryLanguage,
}) => resolveVocabularyContextSpan(
  lines: lines,
  echo: echo,
  currentTimeSeconds: currentTimeSeconds,
  primaryLanguage: primaryLanguage,
)?.text;

/// Resolves context text and the inclusive cue line range used to build it.
VocabularyContextSpan? resolveVocabularyContextSpan({
  required List<TranscriptLine> lines,
  required EchoState echo,
  required double currentTimeSeconds,
  required String primaryLanguage,
}) {
  if (lines.isEmpty) return null;

  if (echo.active &&
      echo.startLineIndex >= 0 &&
      echo.endLineIndex >= 0 &&
      echo.startLineIndex < lines.length &&
      echo.endLineIndex < lines.length) {
    final echoLineCount = echo.endLineIndex - echo.startLineIndex + 1;
    if (echoLineCount >= 2) {
      final text = _joinLines(lines, echo.startLineIndex, echo.endLineIndex);
      if (text == null) return null;
      return (
        text: text,
        startLineIndex: echo.startLineIndex,
        endLineIndex: echo.endLineIndex,
      );
    }
  }

  final activeIdx = transcriptActiveIndex(lines, currentTimeSeconds);
  if (activeIdx < 0) return null;

  var contextStartArrayIndex = activeIdx;
  var contextEndArrayIndex = activeIdx;

  if (echo.active &&
      echo.startLineIndex >= 0 &&
      echo.endLineIndex >= 0 &&
      echo.startLineIndex < lines.length &&
      echo.endLineIndex < lines.length) {
    contextStartArrayIndex = echo.startLineIndex;
    contextEndArrayIndex = echo.endLineIndex;
  }

  final expanded = expandContextLines(
    contextStartArrayIndex,
    contextEndArrayIndex,
    lines.length,
  );
  final expStart = expanded.startArrayIndex;
  final expEnd = expanded.endArrayIndex;
  final expandedLines = lines.sublist(expStart, expEnd + 1);
  if (expandedLines.isEmpty) return null;

  final expandedText = expandedLines.map((l) => plainCueText(l.text)).join(' ');
  if (expandedText.isEmpty) return null;

  final sentenceBoundaries = getSentenceBoundaries(
    expandedText,
    primaryLanguage,
  );

  var charIndex = 0;
  final lineCharPositions = <({int start, int end, int lineIndex})>[];
  for (var i = 0; i < expandedLines.length; i++) {
    final line = expandedLines[i];
    final plain = plainCueText(line.text);
    final lineStart = charIndex;
    charIndex += plain.length;
    final lineEnd = charIndex;
    lineCharPositions.add((
      start: lineStart,
      end: lineEnd,
      lineIndex: expStart + i,
    ));
    if (i < expandedLines.length - 1) {
      charIndex += 1;
    }
  }

  final baseStartLineIndex = contextStartArrayIndex - expStart;
  final baseEndLineIndex = contextEndArrayIndex - expStart;

  if (baseStartLineIndex < 0 || baseEndLineIndex >= lineCharPositions.length) {
    return _fallbackSpan(lines, contextStartArrayIndex, contextEndArrayIndex);
  }

  final baseStartCharIndex = lineCharPositions[baseStartLineIndex].start;
  final baseEndCharIndex = lineCharPositions[baseEndLineIndex].end;

  var sentenceStartCharIndex = 0;
  var sentenceEndCharIndex = expandedText.length;

  if (sentenceBoundaries.isNotEmpty) {
    var prevBoundary = 0;
    for (var i = 0; i < sentenceBoundaries.length; i++) {
      if (sentenceBoundaries[i] > baseStartCharIndex) {
        sentenceStartCharIndex = prevBoundary;
        break;
      }
      prevBoundary = sentenceBoundaries[i];
    }
    if (baseStartCharIndex >= sentenceBoundaries.last) {
      sentenceStartCharIndex = sentenceBoundaries.last;
    }

    for (var i = 0; i < sentenceBoundaries.length; i++) {
      if (sentenceBoundaries[i] >= baseEndCharIndex) {
        sentenceEndCharIndex = sentenceBoundaries[i];
        break;
      }
    }
    if (baseEndCharIndex > sentenceBoundaries.last) {
      sentenceEndCharIndex = sentenceBoundaries.last;
    }
  }

  var contextStartLineIndex = expStart;
  var contextEndLineIndex = expEnd;

  for (var i = 0; i < lineCharPositions.length; i++) {
    final pos = lineCharPositions[i];
    final lineRangeEnd = i < lineCharPositions.length - 1
        ? lineCharPositions[i + 1].start
        : pos.end + 1;
    if (pos.start <= sentenceStartCharIndex &&
        sentenceStartCharIndex < lineRangeEnd) {
      contextStartLineIndex = pos.lineIndex;
      break;
    }
  }

  for (var i = lineCharPositions.length - 1; i >= 0; i--) {
    final pos = lineCharPositions[i];
    final lineRangeEnd = i < lineCharPositions.length - 1
        ? lineCharPositions[i + 1].start
        : pos.end + 1;
    if (pos.start < sentenceEndCharIndex &&
        sentenceEndCharIndex <= lineRangeEnd) {
      contextEndLineIndex = pos.lineIndex;
      break;
    }
  }

  if (contextStartLineIndex < 0) {
    contextStartLineIndex = expStart;
  }
  if (contextEndLineIndex >= lines.length) {
    contextEndLineIndex = expEnd;
  }
  if (contextStartLineIndex > contextEndLineIndex) {
    contextStartLineIndex = contextStartArrayIndex;
    contextEndLineIndex = contextEndArrayIndex;
  }

  final endExclusive = math.min(contextEndLineIndex + 1, lines.length);
  if (contextStartLineIndex < 0 || contextStartLineIndex >= endExclusive) {
    return _fallbackSpan(lines, contextStartArrayIndex, contextEndArrayIndex);
  }

  final text = _joinLines(lines, contextStartLineIndex, contextEndLineIndex);
  if (text == null) {
    return _fallbackSpan(lines, contextStartArrayIndex, contextEndArrayIndex);
  }
  return (
    text: text,
    startLineIndex: contextStartLineIndex,
    endLineIndex: contextEndLineIndex,
  );
}

VocabularyContextSpan? _fallbackSpan(
  List<TranscriptLine> lines,
  int start,
  int end,
) {
  final text = _joinLines(lines, start, end);
  if (text == null) return null;
  return (text: text, startLineIndex: start, endLineIndex: end);
}

String? _joinLines(List<TranscriptLine> lines, int start, int end) {
  if (start < 0 || end >= lines.length || start > end) return null;
  final buf = StringBuffer();
  for (var i = start; i <= end; i++) {
    if (i > start) buf.write(' ');
    buf.write(plainCueText(lines[i].text));
  }
  final s = buf.toString().trim();
  return s.isEmpty ? null : s;
}
