import 'dart:convert';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/dictionary_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/llm_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/ai/domain/prompts/dictionary_prompt.dart';

final class ByokDictionaryCapability implements DictionaryCapability {
  ByokDictionaryCapability(this._llm);

  final LlmCapability _llm;

  @override
  Future<DictionaryResult> lookupDictionary({
    required String word,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) async {
    final raw = await _llm.generateText(
      systemPrompt: buildDictionarySystemPrompt(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      ),
      userPrompt: buildDictionaryUserPrompt(word),
      temperature: 0.2,
      maxTokens: 2048,
    );

    final jsonText = _extractJsonObject(raw);
    final map = jsonDecode(jsonText) as Map<String, dynamic>;
    map['sourceLanguage'] ??= workerLanguageBase(sourceLanguage);
    map['targetLanguage'] ??= workerLanguageBase(targetLanguage);
    map['word'] ??= word;
    return DictionaryResult.fromJson(map);
  }

  String _extractJsonObject(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('{')) return trimmed;

    final fenceStart = trimmed.indexOf('```');
    if (fenceStart >= 0) {
      final afterFence = trimmed.indexOf('\n', fenceStart);
      final endFence = trimmed.lastIndexOf('```');
      if (afterFence >= 0 && endFence > afterFence) {
        return trimmed.substring(afterFence + 1, endFence).trim();
      }
    }

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return trimmed.substring(start, end + 1);
    }

    throw const FormatException('Dictionary BYOK response is not JSON');
  }
}
