/// Maps an assessed take's word errors onto the loop lines' aligned word
/// indexes, for the wavy mispronunciation underlines (D3.8).
library;

import 'dart:convert';

import 'package:azure_speech/azure_speech.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';

/// Word indexes per line index (absolute, over [lines]) that draw the wavy
/// underline, or null when there is nothing to note.
Map<int, Set<int>>? mispronouncedWordIndexes({
  required List<TranscriptLine> lines,
  required EchoState echo,
  required String? assessmentJson,
}) {
  if (assessmentJson == null || assessmentJson.trim().isEmpty) return null;
  final Map<String, dynamic> decoded;
  try {
    final value = jsonDecode(assessmentJson);
    if (value is! Map<String, dynamic>) return null;
    decoded = value;
  } on Object {
    return null;
  }
  final AzurePronunciationAssessmentResult result;
  try {
    result = AzurePronunciationAssessmentResult.fromJson(decoded);
  } on Object {
    return null;
  }
  if (result.nBest.isEmpty) return null;
  final bad = <String>{};
  for (final w in result.nBest.first.words) {
    final error = w.pronunciationAssessment.errorType;
    if (error != 'None' && error != 'Omission') {
      final key = _normalize(w.word);
      if (key.isNotEmpty) bad.add(key);
    }
  }
  if (bad.isEmpty) return null;
  final byLine = <int, Set<int>>{};
  for (var li = echo.startLineIndex; li <= echo.endLineIndex; li++) {
    final words = lines[li].timeline;
    if (words == null) continue;
    for (var wi = 0; wi < words.length; wi++) {
      if (bad.contains(_normalize(words[wi].text))) {
        (byLine[li] ??= {}).add(wi);
      }
    }
  }
  return byLine.isEmpty ? null : byLine;
}

String _normalize(String word) =>
    word.toLowerCase().replaceAll(RegExp(r'[^a-zà-ÿ]'), '');
