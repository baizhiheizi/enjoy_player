import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_speech_guards.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
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

void main() {
  group('guardAzureSpeechConfig', () {
    test(
      'returns trimmed region + apiKey on a valid azureSpeech config',
      () async {
        final creds = await guardAzureSpeechConfig(
          config: const SpeechByokConfig(
            kind: SpeechByokKind.azureSpeech,
            region: '  eastus  ',
          ),
          secrets: _FakeSecretStore('  azure-sub-key  '),
          kind: ModalityKind.asr,
          capabilityLabel: 'ASR',
        );
        expect(creds.region, 'eastus');
        expect(creds.apiKey, 'azure-sub-key');
      },
    );

    test(
      'throws ByokMisconfiguredFailure when kind is openAiCompatible',
      () async {
        await expectLater(
          guardAzureSpeechConfig(
            config: const SpeechByokConfig(
              kind: SpeechByokKind.openAiCompatible,
              region: 'eastus',
              baseUrl: 'https://api.openai.com/v1',
              model: 'whisper-1',
            ),
            secrets: _FakeSecretStore('azure-sub-key'),
            kind: ModalityKind.asr,
            capabilityLabel: 'ASR',
          ),
          throwsA(
            isA<ByokMisconfiguredFailure>()
                .having(
                  (f) => f.expected,
                  'expected',
                  SpeechByokKind.azureSpeech,
                )
                .having(
                  (f) => f.actual,
                  'actual',
                  SpeechByokKind.openAiCompatible,
                )
                .having((f) => f.capabilityLabel, 'capabilityLabel', 'ASR'),
          ),
        );
      },
    );

    test('throws ApiException(400) when region is empty', () async {
      await expectLater(
        guardAzureSpeechConfig(
          config: const SpeechByokConfig(
            kind: SpeechByokKind.azureSpeech,
            region: '   ',
          ),
          secrets: _FakeSecretStore('azure-sub-key'),
          kind: ModalityKind.tts,
          capabilityLabel: 'TTS',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.message,
                'message',
                contains('Azure region is not configured for TTS'),
              ),
        ),
      );
    });

    test('throws ByokNotConfiguredFailure when API key is missing', () async {
      await expectLater(
        guardAzureSpeechConfig(
          config: const SpeechByokConfig(
            kind: SpeechByokKind.azureSpeech,
            region: 'eastus',
          ),
          secrets: _FakeSecretStore(null),
          kind: ModalityKind.assessment,
          capabilityLabel: 'assessment',
        ),
        throwsA(
          isA<ByokNotConfiguredFailure>().having(
            (f) => f.modality,
            'modality',
            ModalityKind.assessment,
          ),
        ),
      );
    });
  });

  group('guardOpenAiSpeechConfig', () {
    test(
      'returns trimmed baseUrl + model + apiKey on a valid config',
      () async {
        final creds = await guardOpenAiSpeechConfig(
          config: const SpeechByokConfig(
            kind: SpeechByokKind.openAiCompatible,
            baseUrl: '  https://api.openai.com/v1  ',
            model: '  whisper-1  ',
          ),
          secrets: _FakeSecretStore('  sk-test  '),
          kind: ModalityKind.asr,
          capabilityLabel: 'ASR',
        );
        expect(creds.baseUrl, 'https://api.openai.com/v1');
        expect(creds.model, 'whisper-1');
        expect(creds.apiKey, 'sk-test');
      },
    );

    test('throws ByokMisconfiguredFailure when kind is azureSpeech', () async {
      await expectLater(
        guardOpenAiSpeechConfig(
          config: const SpeechByokConfig(
            kind: SpeechByokKind.azureSpeech,
            region: 'eastus',
          ),
          secrets: _FakeSecretStore('sk-test'),
          kind: ModalityKind.tts,
          capabilityLabel: 'TTS',
        ),
        throwsA(
          isA<ByokMisconfiguredFailure>().having(
            (f) => f.expected,
            'expected',
            SpeechByokKind.openAiCompatible,
          ),
        ),
      );
    });

    test('throws ApiException(400) when baseUrl or model is missing', () async {
      await expectLater(
        guardOpenAiSpeechConfig(
          config: const SpeechByokConfig(
            kind: SpeechByokKind.openAiCompatible,
            baseUrl: 'https://api.openai.com/v1',
          ),
          secrets: _FakeSecretStore('sk-test'),
          kind: ModalityKind.asr,
          capabilityLabel: 'ASR',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.message,
                'message',
                contains('ASR BYOK base URL and model'),
              ),
        ),
      );
    });

    test('throws ByokNotConfiguredFailure when API key is blank', () async {
      await expectLater(
        guardOpenAiSpeechConfig(
          config: const SpeechByokConfig(
            kind: SpeechByokKind.openAiCompatible,
            baseUrl: 'https://api.openai.com/v1',
            model: 'tts-1',
          ),
          secrets: _FakeSecretStore('   '),
          kind: ModalityKind.tts,
          capabilityLabel: 'TTS',
        ),
        throwsA(
          isA<ByokNotConfiguredFailure>().having(
            (f) => f.modality,
            'modality',
            ModalityKind.tts,
          ),
        ),
      );
    });
  });
}
