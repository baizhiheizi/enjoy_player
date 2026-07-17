/// Encode/decode vocabulary explanation JSON blobs.
library;

import 'dart:convert';

import 'package:enjoy_player/features/ai/domain/models/contextual_translation_result.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';

String encodeDictionaryExplanation(DictionaryResult result) =>
    jsonEncode(result.toJson());

DictionaryResult? decodeDictionaryExplanation(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) return null;
    return DictionaryResult.fromJson(json);
  } catch (_) {
    return null;
  }
}

String encodeContextualExplanation(ContextualTranslationResult result) =>
    jsonEncode(result.toJson());

ContextualTranslationResult? decodeContextualExplanation(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) return null;
    return ContextualTranslationResult.fromJson(json);
  } catch (_) {
    return null;
  }
}
