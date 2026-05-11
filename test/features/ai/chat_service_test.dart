import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/features/ai/application/ai_api_failures.dart';
import 'package:enjoy_player/features/ai/application/ai_capability_providers.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/llm_capability.dart';
import 'package:enjoy_player/features/ai/domain/chat_message.dart';

final class _FakeLlm implements LlmCapability {
  const _FakeLlm();
  @override
  Future<String> generateChatCompletion({
    required List<ChatMessage> messages,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? responseFormat,
  }) async {
    return 'echo:${messages.last.content}';
  }

  @override
  Future<String> generateText({
    String? systemPrompt,
    required String userPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    return 'echo:$userPrompt';
  }
}

void main() {
  test('mapApiExceptionToAppFailure maps 402 to CreditsFailure', () {
    final f = mapApiExceptionToAppFailure(
      const ApiException(message: 'pay', statusCode: 402),
    );
    expect(f, isA<CreditsFailure>());
  });

  test('ChatService uses overridden LlmCapability', () async {
    final container = ProviderContainer(
      overrides: [
        llmCapabilityProvider.overrideWithValue(const _FakeLlm()),
      ],
    );
    addTearDown(container.dispose);

    final chat = container.read(chatServiceProvider);
    final out = await chat.complete(
      messages: const [
        ChatMessage(role: ChatMessage.roleUser, content: 'ping'),
      ],
    );
    expect(out, 'echo:ping');
  });
}
