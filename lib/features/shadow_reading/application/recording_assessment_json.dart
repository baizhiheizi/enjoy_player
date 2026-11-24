/// Readers for a recording's stored Azure assessment payload
/// (`RecordingRow.assessmentJson`).
library;

import 'dart:convert';

import 'package:azure_speech/azure_speech.dart';

/// The typed `NBest` document in [raw], or null when [raw] is not one.
AzurePronunciationAssessmentResult? tryParseStoredAssessment(String raw) {
  try {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) return null;
    return AzurePronunciationAssessmentResult.fromJson(json);
  } on Object {
    return null;
  }
}

/// The first hypothesis's `PronScore`, rounded; null when it is absent or not
/// a number. Reads that one field instead of building the typed tree, and
/// unlike [tryParseStoredAssessment] does not read a missing score as 0.
int? decodeStoredPronScore(String raw) {
  try {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    final nb = m['NBest'] as List<dynamic>?;
    if (nb == null || nb.isEmpty) return null;
    final first = nb.first;
    if (first is! Map<String, dynamic>) return null;
    final pa = first['PronunciationAssessment'];
    if (pa is! Map<String, dynamic>) return null;
    final v = pa['PronScore'];
    if (v is num) return v.round();
    return null;
  } on Object {
    return null;
  }
}
