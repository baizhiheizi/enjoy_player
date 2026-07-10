/// Adapter: [CraftTranslator] backed by [ChatService] (LLM API).
///
/// Uses `/chat/completions` (via the LLM capability layer) with style-specific
/// system prompts, NOT the `/translations` worker endpoint. This gives the
/// learner control over translation style (literal, natural, casual, etc.).
library;

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/chat_message.dart';
import 'package:enjoy_player/features/craft/domain/craft_translator.dart';
import 'package:enjoy_player/features/craft/domain/translation_style.dart';

final class CraftTranslationServiceTranslator implements CraftTranslator {
  CraftTranslationServiceTranslator(this._chat);

  final ChatService _chat;

  @override
  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    TranslationStyle style = TranslationStyle.natural,
    String? customPrompt,
  }) async {
    final sourceBase = workerLanguageBase(sourceLanguage);
    final targetBase = workerLanguageBase(targetLanguage);

    // Build the system prompt based on the selected style.
    final String systemPrompt;
    if (style == TranslationStyle.custom &&
        customPrompt != null &&
        customPrompt.trim().isNotEmpty) {
      systemPrompt =
          '$customPrompt\n\n'
          'Translate from $sourceBase to $targetBase. '
          'Reply with only the translated text.';
    } else {
      systemPrompt =
          'You are a professional translator. '
          'Translate from $sourceBase to $targetBase. '
          '${style.promptSuffix} '
          'Reply with only the translated text — no quotes, labels, or explanation.';
    }

    final response = await _chat.complete(
      messages: [
        ChatMessage(role: ChatMessage.roleSystem, content: systemPrompt),
        ChatMessage(role: ChatMessage.roleUser, content: text),
      ],
    );
    return response.trim();
  }
}
