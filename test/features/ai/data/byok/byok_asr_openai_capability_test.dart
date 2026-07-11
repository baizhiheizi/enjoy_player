import 'dart:convert';
import 'dart:typed_data';

import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_asr_openai_capability.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _RecordingClient extends http.BaseClient {
  http.BaseRequest? captured;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    captured = request;
    return http.StreamedResponse(
      Stream.fromIterable([
        utf8.encode(jsonEncode({'text': 'Hello world'})),
      ]),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

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
  test('ByokAsrOpenAiCapability transcribes via Whisper multipart', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/v1/audio/transcriptions');
      expect(request.headers['Authorization'], 'Bearer sk-test');
      return http.Response(
        jsonEncode({'text': 'Hello world'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final cap = ByokAsrOpenAiCapability(
      config: const SpeechByokConfig(
        kind: SpeechByokKind.openAiCompatible,
        baseUrl: 'https://api.openai.com/v1',
        model: 'whisper-1',
      ),
      secrets: _FakeSecretStore('sk-test'),
      httpClient: client,
    );

    final result = await cap.transcribe(
      AsrRequest(
        audioBytes: Uint8List.fromList([1, 2, 3]),
        filename: 'sample.wav',
        language: 'en',
      ),
    );

    expect(result.text, 'Hello world');
    client.close();
  });

  test('normalizes BCP-47 language tag to Whisper base tag', () async {
    final client = _RecordingClient();

    final cap = ByokAsrOpenAiCapability(
      config: const SpeechByokConfig(
        kind: SpeechByokKind.openAiCompatible,
        baseUrl: 'https://api.openai.com/v1',
        model: 'whisper-1',
      ),
      secrets: _FakeSecretStore('sk-test'),
      httpClient: client,
    );

    final result = await cap.transcribe(
      AsrRequest(
        audioBytes: Uint8List.fromList([1, 2, 3]),
        filename: 'sample.wav',
        language: 'en-US',
      ),
    );

    expect(result.text, 'Hello world');
    expect(client.captured, isA<http.MultipartRequest>());
    final multipart = client.captured! as http.MultipartRequest;
    expect(multipart.method, 'POST');
    expect(multipart.url.path, '/v1/audio/transcriptions');
    expect(multipart.headers['Authorization'], 'Bearer sk-test');
    expect(multipart.fields['language'], 'en');
    client.close();
  });

  test('throws when API key is missing', () async {
    final cap = ByokAsrOpenAiCapability(
      config: const SpeechByokConfig(
        kind: SpeechByokKind.openAiCompatible,
        baseUrl: 'https://api.openai.com/v1',
        model: 'whisper-1',
      ),
      secrets: _FakeSecretStore(null),
    );

    await expectLater(
      cap.transcribe(
        AsrRequest(audioBytes: Uint8List.fromList([1]), filename: 'a.wav'),
      ),
      throwsA(isA<Exception>()),
    );
  });
}
