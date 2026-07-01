import 'dart:convert';

import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_tts_azure_capability.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_request.dart';
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

  test('ByokTtsAzureCapability with mocked synthesize channel', () async {
    final audio = Uint8List.fromList([0x52, 0x49, 0x46, 0x46]);
    final encoded = base64Encode(audio);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'synthesize');
      final args = Map<String, dynamic>.from(
        call.arguments as Map<Object?, Object?>,
      );
      expect(args['subscriptionKey'], 'azure-sub-key');
      expect(args['region'], 'eastus');
      expect(args['language'], 'en-US');
      expect(args['text'], 'Hello');
      return encoded;
    });

    final cap = ByokTtsAzureCapability(
      config: const SpeechByokConfig(
        kind: SpeechByokKind.azureSpeech,
        region: 'eastus',
      ),
      secrets: _FakeSecretStore('azure-sub-key'),
      sdk: AzureSpeech.instance,
    );

    final result = await cap.synthesize(
      const TtsRequest(text: 'Hello', language: 'en'),
    );

    expect(result.format, 'wav');
    expect(result.audioBytes, audio);
  });

  test('throws when subscription key is missing', () async {
    final cap = ByokTtsAzureCapability(
      config: const SpeechByokConfig(
        kind: SpeechByokKind.azureSpeech,
        region: 'eastus',
      ),
      secrets: _FakeSecretStore(null),
    );

    await expectLater(
      cap.synthesize(const TtsRequest(text: 'Hello', language: 'en')),
      throwsA(isA<Exception>()),
    );
  });
}
