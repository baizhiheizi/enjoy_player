import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/ai/application/ai_capability_providers.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/llm_capability.dart';
import 'package:enjoy_player/features/ai/domain/chat_message.dart';
import 'package:enjoy_player/features/craft/data/craft_translation_service_translator.dart';
import 'package:enjoy_player/features/craft/domain/translation_style.dart';

/// Captures the system message and echoes it back as the "response".
final class _PromptCapturingLlm implements LlmCapability {
  const _PromptCapturingLlm();

  @override
  Future<String> generateChatCompletion({
    required List<ChatMessage> messages,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? responseFormat,
  }) async {
    // The system prompt is always the first message in the list.
    return messages.first.content;
  }

  @override
  Future<String> generateText({
    String? systemPrompt,
    required String userPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    return systemPrompt ?? userPrompt;
  }
}

void main() {
  late ProviderContainer container;
  late CraftTranslationServiceTranslator translator;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        llmCapabilityProvider.overrideWithValue(const _PromptCapturingLlm()),
      ],
    );
    addTearDown(container.dispose);

    final chat = container.read(chatServiceProvider);
    translator = CraftTranslationServiceTranslator(chat);
  });

  group('TranslationStyle.auto prompt', () {
    test('contains "language partner" and "idiomatic" keywords', () async {
      final prompt = await translator.translate(
        text: 'I had a great day today.',
        sourceLanguage: 'en-US',
        targetLanguage: 'ja-JP',
        style: TranslationStyle.auto,
      );

      expect(prompt, contains('language partner'));
      expect(prompt, contains('idiomatic'));
      expect(prompt, contains('rewrite'));
    });

    test('mentions both source and target language bases', () async {
      final prompt = await translator.translate(
        text: 'Hello world',
        sourceLanguage: 'zh-CN',
        targetLanguage: 'en-US',
        style: TranslationStyle.auto,
      );

      expect(prompt, contains('zh'));
      expect(prompt, contains('en'));
    });

    test('is distinct from TranslationStyle.natural prompt', () async {
      final autoPrompt = await translator.translate(
        text: 'Test sentence.',
        sourceLanguage: 'en-US',
        targetLanguage: 'es-ES',
        style: TranslationStyle.auto,
      );

      final naturalPrompt = await translator.translate(
        text: 'Test sentence.',
        sourceLanguage: 'en-US',
        targetLanguage: 'es-ES',
        style: TranslationStyle.natural,
      );

      expect(autoPrompt, isNot(equals(naturalPrompt)));
      // Natural uses "professional translator", auto uses "language partner".
      expect(naturalPrompt, contains('professional translator'));
      expect(autoPrompt, isNot(contains('professional translator')));
    });
  });
}
