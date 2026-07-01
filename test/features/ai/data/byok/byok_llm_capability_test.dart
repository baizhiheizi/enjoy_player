import 'package:ai_sdk_dart/ai_sdk_dart.dart' as ai_sdk;
import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_llm_capability.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_llm_model_factory.dart';
import 'package:enjoy_player/features/ai/domain/chat_message.dart';
import 'package:enjoy_player/features/ai/domain/llm_api_spec.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSecretStore implements ByokSecretStoreBase {
  _FakeSecretStore(this._key);

  final String? _key;

  @override
  Future<void> deleteApiKey(ModalityKind modality) async {}

  @override
  Future<bool> hasApiKey(ModalityKind modality) async =>
      _key != null && _key.isNotEmpty;

  @override
  Future<String?> readApiKey(ModalityKind modality) async => _key;

  @override
  Future<void> writeApiKey(ModalityKind modality, String apiKey) async {}
}

ai_sdk.GenerateTextResult<String> _fakeResult(String text) {
  return ai_sdk.GenerateTextResult<String>(
    text: text,
    output: text,
    content: const [],
    toolCalls: const [],
    toolResults: const [],
    toolApprovalRequests: const [],
    steps: const [],
    sources: const [],
    files: const [],
    reasoning: const [],
    reasoningText: '',
    requestMessages: const [],
    responseMessages: const [],
    request: const ai_sdk.GenerateTextRequest(system: null, messages: []),
    responseInfo: const ai_sdk.GenerateTextResponse(
      messages: [],
      body: null,
      metadata: null,
    ),
  );
}

void main() {
  group('createByokLanguageModel', () {
    test('maps OpenAI-compatible config to openai provider', () {
      final model = createByokLanguageModel(
        config: const LlmByokConfig(
          apiSpec: LlmApiSpec.openAiCompatible,
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
        ),
        apiKey: 'sk-test',
      );
      expect(model.provider, 'openai');
      expect(model.modelId, 'deepseek-chat');
    });

    test('normalizes trailing slash on base URL', () {
      expect(
        normalizeByokBaseUrl('https://api.openai.com/v1/'),
        'https://api.openai.com/v1',
      );
    });
  });

  group('ByokLlmCapability', () {
    test('generateText returns trimmed model output', () async {
      final capability = ByokLlmCapability(
        const LlmByokConfig(
          apiSpec: LlmApiSpec.openAiCompatible,
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-4o-mini',
        ),
        _FakeSecretStore('sk-test'),
        generateTextRunner: ({
          required LanguageModelV3 model,
          String? system,
          List<ai_sdk.ModelMessage>? messages,
          int? maxOutputTokens,
          double? temperature,
        }) async {
          expect(model.modelId, 'gpt-4o-mini');
          expect(system, 'sys');
          expect(messages?.single.content, 'hello');
          return _fakeResult('  world  ');
        },
      );

      final out = await capability.generateText(
        systemPrompt: 'sys',
        userPrompt: 'hello',
      );
      expect(out, 'world');
    });

    test('generateChatCompletion forwards messages', () async {
      final capability = ByokLlmCapability(
        const LlmByokConfig(
          apiSpec: LlmApiSpec.anthropicCompatible,
          baseUrl: 'https://api.anthropic.com/v1',
          model: 'claude-sonnet-4-20250514',
        ),
        _FakeSecretStore('key'),
        generateTextRunner: ({
          required LanguageModelV3 model,
          String? system,
          List<ai_sdk.ModelMessage>? messages,
          int? maxOutputTokens,
          double? temperature,
        }) async {
          expect(messages, hasLength(2));
          return _fakeResult('ok');
        },
      );

      final out = await capability.generateChatCompletion(
        messages: const [
          ChatMessage(role: ChatMessage.roleSystem, content: 's'),
          ChatMessage(role: ChatMessage.roleUser, content: 'u'),
        ],
      );
      expect(out, 'ok');
    });
  });
}
