import 'dart:convert';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/json/json_from_llm.dart';
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

    final jsonText = extractJsonObject(raw);
    final map = jsonDecode(jsonText) as Map<String, dynamic>;
    map['sourceLanguage'] ??= workerLanguageBase(sourceLanguage);
    map['targetLanguage'] ??= workerLanguageBase(targetLanguage);
    map['word'] ??= word;
    return DictionaryResult.fromJson(map);
  }
}
