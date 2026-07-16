import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/data/azure_assessment_staging_path.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_asr_azure_capability.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
import 'package:flutter/services.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('azure_speech');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('ByokAsrAzureCapability with mocked transcribe channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'transcribe');
          final args = Map<String, dynamic>.from(
            call.arguments as Map<Object?, Object?>,
          );
          expect(args['subscriptionKey'], 'azure-sub-key');
          expect(args['region'], 'eastus');
          expect(args['language'], 'en-US');
          final audioPath = args['audioPath'] as String;
          expect(audioPath, isNotEmpty);
          // Native FromWavFileInput must not see non-ASCII Windows profile paths.
          expect(pathContainsNonAscii(audioPath), isFalse);
          return 'Hello from Azure';
        });

    final cap = ByokAsrAzureCapability(
      config: const SpeechByokConfig(
        kind: SpeechByokKind.azureSpeech,
        region: 'eastus',
      ),
      secrets: _FakeSecretStore('azure-sub-key'),
      sdk: AzureSpeech.instance,
    );

    final result = await cap.transcribe(
      AsrRequest(
        audioBytes: Uint8List.fromList([1, 2, 3, 4]),
        filename: 'sample.wav',
        language: 'en',
      ),
    );

    expect(result.text, 'Hello from Azure');
  });

  test('throws when subscription key is missing', () async {
    final cap = ByokAsrAzureCapability(
      config: const SpeechByokConfig(
        kind: SpeechByokKind.azureSpeech,
        region: 'eastus',
      ),
      secrets: _FakeSecretStore(null),
    );

    await expectLater(
      cap.transcribe(
        AsrRequest(
          audioBytes: Uint8List.fromList([1]),
          filename: 'a.wav',
          language: 'en',
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });
}
