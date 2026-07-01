import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/ai/domain/ai_service_config.dart';
import 'package:enjoy_player/features/ai/domain/byok_config_validator.dart';
import 'package:enjoy_player/features/ai/domain/llm_api_spec.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = ByokConfigValidator();

  group('LLM BYOK', () {
    test('requires api key on first save', () {
      final result = validator.validate(
        modality: ModalityKind.llm,
        config: const AIServiceConfig(
          provider: AIProvider.byok,
          llmByok: LlmByokConfig(
            apiSpec: LlmApiSpec.openAiCompatible,
            baseUrl: 'https://api.openai.com/v1',
            model: 'gpt-4o-mini',
          ),
        ),
        hasExistingApiKey: false,
      );

      expect(result.isValid, isFalse);
      expect(result.errors, contains(ByokValidationError.apiKeyRequired));
    });

    test('accepts valid config with key', () {
      final result = validator.validate(
        modality: ModalityKind.llm,
        config: const AIServiceConfig(
          provider: AIProvider.byok,
          llmByok: LlmByokConfig(
            apiSpec: LlmApiSpec.openAiCompatible,
            baseUrl: 'https://api.deepseek.com/v1',
            model: 'deepseek-chat',
          ),
        ),
        hasExistingApiKey: false,
        apiKey: 'sk-test',
      );

      expect(result.isValid, isTrue);
    });

    test('rejects private base URL', () {
      final result = validator.validate(
        modality: ModalityKind.llm,
        config: const AIServiceConfig(
          provider: AIProvider.byok,
          llmByok: LlmByokConfig(
            apiSpec: LlmApiSpec.openAiCompatible,
            baseUrl: 'https://192.168.1.5/v1',
            model: 'gpt-4o-mini',
          ),
        ),
        hasExistingApiKey: true,
      );

      expect(result.errors, contains(ByokValidationError.baseUrlInvalid));
    });
  });

  group('Assessment BYOK', () {
    test('requires Azure kind and region', () {
      final result = validator.validate(
        modality: ModalityKind.assessment,
        config: const AIServiceConfig(
          provider: AIProvider.byok,
          speechByok: SpeechByokConfig(
            kind: SpeechByokKind.openAiCompatible,
          ),
        ),
        hasExistingApiKey: true,
      );

      expect(result.errors, contains(ByokValidationError.azureKindRequired));
    });

    test('accepts Azure assessment config', () {
      final result = validator.validate(
        modality: ModalityKind.assessment,
        config: const AIServiceConfig(
          provider: AIProvider.byok,
          speechByok: SpeechByokConfig(
            kind: SpeechByokKind.azureSpeech,
            region: 'eastus',
          ),
        ),
        hasExistingApiKey: true,
      );

      expect(result.isValid, isTrue);
    });
  });
}
