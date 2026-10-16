import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_azure_speech_capability.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_speech_guards.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeAzureCapability extends ByokAzureSpeechCapability {
  _FakeAzureCapability({
    required super.config,
    required super.secrets,
    required this.stubbedKind,
    required this.stubbedLabel,
  });

  final ModalityKind stubbedKind;
  final String stubbedLabel;

  AzureSpeech get exposedSdk => sdk;

  @override
  ModalityKind get kind => stubbedKind;

  @override
  String get capabilityLabel => stubbedLabel;
}

final class _RecordingSecretStore implements ByokSecretStoreBase {
  _RecordingSecretStore(this._key);

  final String? _key;
  ModalityKind? lastReadModality;

  @override
  Future<void> deleteApiKey(ModalityKind modality) async {}

  @override
  Future<bool> hasApiKey(ModalityKind modality) async =>
      _key != null && _key.isNotEmpty;

  @override
  Future<String?> readApiKey(ModalityKind modality) async {
    lastReadModality = modality;
    return _key;
  }

  @override
  Future<void> writeApiKey(ModalityKind modality, String apiKey) async {}
}

void main() {
  const azureConfig = SpeechByokConfig(
    kind: SpeechByokKind.azureSpeech,
    region: 'eastus',
  );

  _FakeAzureCapability cap(
    SpeechByokConfig config,
    _RecordingSecretStore secrets,
  ) => _FakeAzureCapability(
    config: config,
    secrets: secrets,
    stubbedKind: ModalityKind.tts,
    stubbedLabel: 'TTS',
  );

  test(
    'resolveCredentials trims region and key, reads the subclass kind',
    () async {
      final secrets = _RecordingSecretStore('  azure-sub-key  ');
      final subject = cap(azureConfig, secrets);

      final (:region, apiKey: subscriptionKey) = await subject
          .resolveCredentials();

      expect(region, 'eastus');
      expect(subscriptionKey, 'azure-sub-key');
      expect(secrets.lastReadModality, ModalityKind.tts);
    },
  );

  test('resolveCredentials rejects a config of another speech kind', () async {
    final subject = cap(
      const SpeechByokConfig(
        kind: SpeechByokKind.openAiCompatible,
        baseUrl: 'https://example.invalid/v1',
        model: 'tts-1',
      ),
      _RecordingSecretStore('key'),
    );

    await expectLater(
      subject.resolveCredentials(),
      throwsA(
        isA<ByokMisconfiguredFailure>().having(
          (e) => e.capabilityLabel,
          'capabilityLabel',
          'TTS',
        ),
      ),
    );
  });

  test('resolveCredentials requires a configured api key', () async {
    final subject = cap(azureConfig, _RecordingSecretStore(null));

    await expectLater(
      subject.resolveCredentials(),
      throwsA(isA<ByokNotConfiguredFailure>()),
    );
  });

  test('resolveCredentials requires a region', () async {
    final subject = cap(
      const SpeechByokConfig(kind: SpeechByokKind.azureSpeech),
      _RecordingSecretStore('key'),
    );

    await expectLater(
      subject.resolveCredentials(),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400),
      ),
    );
  });

  test('sdk falls back to the shared AzureSpeech instance', () {
    final subject = cap(azureConfig, _RecordingSecretStore('key'));

    expect(subject.exposedSdk, same(AzureSpeech.instance));
  });
}
