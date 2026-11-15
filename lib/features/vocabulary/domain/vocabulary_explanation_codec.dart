/// Encode/decode vocabulary explanation JSON blobs.
library;

import 'dart:convert';

import 'package:enjoy_player/core/cache/lru_store.dart';
import 'package:enjoy_player/features/ai/domain/models/contextual_translation_result.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:meta/meta.dart';

final L1Store<String, DictionaryResult> _dictionaryDecodes = L1Store(
  capacity: 8,
);

final L1Store<String, ContextualTranslationResult> _contextualDecodes = L1Store(
  capacity: 8,
);

@visibleForTesting
int dictionaryDecodeDerivationCount = 0;

@visibleForTesting
int contextualDecodeDerivationCount = 0;

String encodeDictionaryExplanation(DictionaryResult result) =>
    jsonEncode(result.toJson());

DictionaryResult? decodeDictionaryExplanation(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final cached = _dictionaryDecodes.peek(raw);
  if (cached != null) return cached;
  dictionaryDecodeDerivationCount++;
  try {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) return null;
    final result = DictionaryResult.fromJson(json);
    _dictionaryDecodes.put(raw, result);
    return result;
  } catch (_) {
    return null;
  }
}

String encodeContextualExplanation(ContextualTranslationResult result) =>
    jsonEncode(result.toJson());

ContextualTranslationResult? decodeContextualExplanation(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final cached = _contextualDecodes.peek(raw);
  if (cached != null) return cached;
  contextualDecodeDerivationCount++;
  try {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) return null;
    final result = ContextualTranslationResult.fromJson(json);
    _contextualDecodes.put(raw, result);
    return result;
  } catch (_) {
    return null;
  }
}
