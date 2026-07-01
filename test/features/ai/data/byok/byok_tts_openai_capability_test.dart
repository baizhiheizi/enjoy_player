import 'dart:convert';
import 'dart:typed_data';

import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_tts_openai_capability.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_request.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
  test('ByokTtsOpenAiCapability synthesizes via OpenAI speech endpoint', () async {
    final audio = Uint8List.fromList([0xFF, 0xFB, 0x90]);

    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/v1/audio/speech');
      expect(request.headers['Authorization'], 'Bearer sk-test');
      expect(request.headers['Accept'], 'audio/mpeg');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['model'], 'tts-1');
      expect(body['input'], 'Hello');
      expect(body['voice'], 'alloy');
      return http.Response.bytes(audio, 200, headers: {'content-type': 'audio/mpeg'});
    });

    final cap = ByokTtsOpenAiCapability(
      config: const SpeechByokConfig(
        kind: SpeechByokKind.openAiCompatible,
        baseUrl: 'https://api.openai.com/v1',
        model: 'tts-1',
      ),
      secrets: _FakeSecretStore('sk-test'),
      httpClient: client,
    );

    final result = await cap.synthesize(
      const TtsRequest(text: 'Hello', language: 'en'),
    );

    expect(result.format, 'mp3');
    expect(result.audioBytes, audio);
    client.close();
  });

  test('uses request voice when provided', () async {
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['voice'], 'nova');
      return http.Response.bytes(Uint8List(0), 200);
    });

    final cap = ByokTtsOpenAiCapability(
      config: const SpeechByokConfig(
        kind: SpeechByokKind.openAiCompatible,
        baseUrl: 'https://api.openai.com/v1',
        model: 'tts-1',
      ),
      secrets: _FakeSecretStore('sk-test'),
      httpClient: client,
    );

    await cap.synthesize(
      const TtsRequest(text: 'Hi', language: 'en', voice: 'nova'),
    );
    client.close();
  });

  test('throws when API key is missing', () async {
    final cap = ByokTtsOpenAiCapability(
      config: const SpeechByokConfig(
        kind: SpeechByokKind.openAiCompatible,
        baseUrl: 'https://api.openai.com/v1',
        model: 'tts-1',
      ),
      secrets: _FakeSecretStore(null),
    );

    await expectLater(
      cap.synthesize(const TtsRequest(text: 'Hello', language: 'en')),
      throwsA(isA<Exception>()),
    );
  });
}
