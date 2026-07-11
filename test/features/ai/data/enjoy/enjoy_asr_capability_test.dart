import 'dart:convert';
import 'dart:typed_data';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/ai/asr_api.dart';
import 'package:enjoy_player/features/ai/data/enjoy/enjoy_asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _RecordingClient extends http.BaseClient {
  http.BaseRequest? captured;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    captured = request;
    return http.StreamedResponse(
      Stream.fromIterable([
        utf8.encode(jsonEncode({'text': 'Hello world', 'language': 'en'})),
      ]),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  test('normalizes BCP-47 language tag to Whisper base tag', () async {
    final httpClient = _RecordingClient();
    final apiClient = ApiClient(
      httpClient: httpClient,
      getBaseUrl: () async => 'https://worker.enjoy.bot',
      getAccessToken: () async => 'token',
    );
    final cap = EnjoyAsrCapability(AsrApi(apiClient));

    final result = await cap.transcribe(
      AsrRequest(
        audioBytes: Uint8List.fromList([1, 2, 3]),
        filename: 'sample.wav',
        language: 'en-US',
        durationSeconds: 150.0,
      ),
    );

    final request = httpClient.captured;
    expect(result.text, 'Hello world');
    expect(request, isA<http.MultipartRequest>());
    final multipart = request! as http.MultipartRequest;
    expect(multipart.fields['language'], 'en');
    expect(multipart.fields['duration_seconds'], '150.0');

    httpClient.close();
  });

  test('leaves language null when auto-detect is requested', () async {
    final httpClient = _RecordingClient();
    final apiClient = ApiClient(
      httpClient: httpClient,
      getBaseUrl: () async => 'https://worker.enjoy.bot',
      getAccessToken: () async => 'token',
    );
    final cap = EnjoyAsrCapability(AsrApi(apiClient));

    await cap.transcribe(
      AsrRequest(
        audioBytes: Uint8List.fromList([1, 2, 3]),
        filename: 'sample.wav',
        language: null,
      ),
    );

    final request = httpClient.captured;
    expect(request, isA<http.MultipartRequest>());
    expect((request! as http.MultipartRequest).fields['language'], isNull);

    httpClient.close();
  });
}
