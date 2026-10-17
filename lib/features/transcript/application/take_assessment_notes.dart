/// Decoded pronunciation notes for an assessed shadow-reading take.
library;

import 'dart:convert';

import 'package:azure_speech/azure_speech.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';

/// Above this payload size the assessment JSON decodes off the UI isolate.
const int kTakeAssessmentDecodeIsolateGate = 32 * 1024;

final RegExp _nonWordCharacter = RegExp(r'[^a-zà-ÿ]');

String normalizeAssessmentWord(String word) =>
    word.toLowerCase().replaceAll(_nonWordCharacter, '');

/// Normalized mispronounced words in one Azure assessment payload.
///
/// Parse failures yield an empty set (no underlines), matching the historical
/// fail-closed behavior. The function is isolate-safe: it touches only plain
/// data and the Azure result model.
Set<String> takeAssessmentErrorWords(String assessmentJson) {
  final Map<String, dynamic> decoded;
  try {
    final value = jsonDecode(assessmentJson);
    if (value is! Map<String, dynamic>) return const <String>{};
    decoded = value;
  } on Object {
    return const <String>{};
  }
  final AzurePronunciationAssessmentResult result;
  try {
    result = AzurePronunciationAssessmentResult.fromJson(decoded);
  } on Object {
    return const <String>{};
  }
  if (result.nBest.isEmpty) return const <String>{};
  final bad = <String>{};
  for (final word in result.nBest.first.words) {
    final error = word.pronunciationAssessment.errorType;
    if (error == 'None' || error == 'Omission') continue;
    final key = normalizeAssessmentWord(word.word);
    if (key.isNotEmpty) bad.add(key);
  }
  return bad;
}

/// Word indexes per transcript line that should draw the wavy underline.
class TakeAssessmentNotes {
  const TakeAssessmentNotes._(this.byLine);

  final Map<int, Set<int>> byLine;

  static TakeAssessmentNotes? from({
    required List<TranscriptLine> lines,
    required EchoState echo,
    required Set<String> errorWords,
  }) {
    if (errorWords.isEmpty || lines.isEmpty) return null;
    final start = echo.startLineIndex < 0 ? 0 : echo.startLineIndex;
    final end = echo.endLineIndex >= lines.length
        ? lines.length - 1
        : echo.endLineIndex;
    final byLine = <int, Set<int>>{};
    for (var lineIndex = start; lineIndex <= end; lineIndex++) {
      final words = lines[lineIndex].timeline;
      if (words == null) continue;
      for (var wordIndex = 0; wordIndex < words.length; wordIndex++) {
        if (errorWords.contains(
          normalizeAssessmentWord(words[wordIndex].text),
        )) {
          (byLine[lineIndex] ??= <int>{}).add(wordIndex);
        }
      }
    }
    return byLine.isEmpty ? null : TakeAssessmentNotes._(byLine);
  }
}
