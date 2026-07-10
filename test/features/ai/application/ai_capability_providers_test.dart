import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/ai/ai_api_providers.dart';
import 'package:enjoy_player/data/api/services/ai/asr_api.dart';
import 'package:enjoy_player/data/api/services/ai/chat_api.dart';
import 'package:enjoy_player/features/ai/application/ai_capability_providers.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_configs.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_asr_azure_capability.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_asr_openai_capability.dart';
import 'package:enjoy_player/features/ai/data/enjoy/enjoy_asr_capability.dart';
import 'package:enjoy_player/features/ai/data/enjoy/enjoy_llm_capability.dart';
import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/ai/domain/ai_service_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _NullApiClient extends ApiClient {
  _NullApiClient()
    : super(
        httpClient: _NullHttpClient(),
        getBaseUrl: () async => 'https://test.invalid',
        getAccessToken: () async => null,
      );
}

class _NullHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnsupportedError('Not used in capability routing test');
  }
}

void main() {
  test(
    'llmCapabilityProvider returns EnjoyLlmCapability for default config',
    () {
      final container = ProviderContainer(
        overrides: [
          aiModalityConfigsProvider.overrideWithValue(
            AiModalityConfigs.defaults,
          ),
          chatApiProvider.overrideWithValue(ChatApi(_NullApiClient())),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(llmCapabilityProvider), isA<EnjoyLlmCapability>());
    },
  );

  test('asrCapabilityProvider resolves Enjoy, OpenAI, and Azure paths', () {
    final api = AsrApi(_NullApiClient());
    final configs = <AIServiceConfig>[
      const AIServiceConfig(provider: AIProvider.enjoy),
      const AIServiceConfig(
        provider: AIProvider.byok,
        speechByok: SpeechByokConfig(
          kind: SpeechByokKind.openAiCompatible,
          baseUrl: 'https://example.invalid/v1',
          model: 'whisper-1',
        ),
      ),
      const AIServiceConfig(
        provider: AIProvider.byok,
        speechByok: SpeechByokConfig(
          kind: SpeechByokKind.azureSpeech,
          region: 'eastus',
        ),
      ),
    ];
    final expected = <Type>[
      EnjoyAsrCapability,
      ByokAsrOpenAiCapability,
      ByokAsrAzureCapability,
    ];

    for (var i = 0; i < configs.length; i++) {
      final container = ProviderContainer(
        overrides: [
          aiModalityConfigsProvider.overrideWithValue(
            AiModalityConfigs(
              asr: configs[i],
              tts: AiModalityConfigs.defaults.tts,
              llm: AiModalityConfigs.defaults.llm,
              translation: AiModalityConfigs.defaults.translation,
              dictionary: AiModalityConfigs.defaults.dictionary,
              assessment: AiModalityConfigs.defaults.assessment,
            ),
          ),
          asrApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(asrCapabilityProvider).runtimeType, expected[i]);
    }
  });
}
