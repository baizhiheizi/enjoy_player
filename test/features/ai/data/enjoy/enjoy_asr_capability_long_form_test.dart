import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/ai/asr_api.dart';
import 'package:enjoy_player/data/api/services/ai/asr_media_upload_api.dart';
import 'package:enjoy_player/features/ai/data/enjoy/enjoy_asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_long_form_phase.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class _ScriptedClient extends http.BaseClient {
  _ScriptedClient(this._handlers);

  final List<http.StreamedResponse Function(http.BaseRequest)> _handlers;
  final List<http.BaseRequest> requests = [];
  var _i = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    if (_i >= _handlers.length) {
      throw StateError('Unexpected request: ${request.method} ${request.url}');
    }
    return _handlers[_i++](request);
  }
}

http.StreamedResponse _jsonResponse(Object body, {int status = 200}) {
  return http.StreamedResponse(
    Stream.fromIterable([utf8.encode(jsonEncode(body))]),
    status,
    headers: {'content-type': 'application/json'},
  );
}

void main() {
  test('duration under 900 uses multipart short-clip path', () async {
    final httpClient = _ScriptedClient([
      (_) => _jsonResponse({'text': 'hi', 'language': 'en'}),
    ]);
    final apiClient = ApiClient(
      httpClient: httpClient,
      getBaseUrl: () async => 'https://worker.enjoy.bot',
      getAccessToken: () async => 'token',
    );
    final cap = EnjoyAsrCapability(
      AsrApi(apiClient),
      uploadApi: AsrMediaUploadApi(apiClient),
    );

    await cap.transcribe(
      AsrRequest(
        audioBytes: Uint8List.fromList([1, 2, 3]),
        filename: 'a.wav',
        language: 'en-US',
        durationSeconds: kLongFormMinDurationSeconds - 1,
      ),
    );

    expect(httpClient.requests.single, isA<http.MultipartRequest>());
    httpClient.close();
  });

  test('duration >= 900 uploads, submits JSON, and polls', () async {
    final phases = <AsrLongFormClientPhase>[];
    final httpClient = _ScriptedClient([
      // upload
      (_) => _jsonResponse({
        'media_reference': 'ref.wav',
        'byte_length': 3,
      }, status: 201),
      // submit
      (_) => _jsonResponse({
        'job_id': 'job-1',
        'status': 'accepted',
        'created_at': '2026-07-19T00:00:00.000Z',
      }, status: 202),
      // poll processing
      (_) => _jsonResponse({'job_id': 'job-1', 'status': 'processing'}),
      // poll completed
      (_) => _jsonResponse({
        'job_id': 'job-1',
        'status': 'completed',
        'transcript': {
          'text': 'Long form',
          'language': 'en',
          'segments': [
            {'start': 0.0, 'end': 1.0, 'text': 'Long'},
            {'start': 1.0, 'end': 2.0, 'text': 'form'},
          ],
        },
        'usage': {'actual_duration_seconds': 900, 'credits_charged': 18480},
      }),
    ]);
    final apiClient = ApiClient(
      httpClient: httpClient,
      getBaseUrl: () async => 'https://worker.enjoy.bot',
      getAccessToken: () async => 'token',
    );
    final cap = EnjoyAsrCapability(
      AsrApi(apiClient),
      uploadApi: AsrMediaUploadApi(apiClient),
      uuid: const Uuid(),
      pollInitialDelay: Duration.zero,
      pollMaxDelay: Duration.zero,
    );

    final result = await cap.transcribe(
      AsrRequest(
        audioBytes: Uint8List.fromList([1, 2, 3]),
        filename: 'a.wav',
        language: 'en',
        durationSeconds: 900,
        idempotencyKey: 'idem-1',
        onLongFormPhase: phases.add,
      ),
    );

    expect(result.text, 'Long form');
    expect(result.segments, isNotNull);
    expect(phases, contains(AsrLongFormClientPhase.uploading));
    expect(phases, contains(AsrLongFormClientPhase.polling));
    expect(httpClient.requests[0].method, 'PUT');
    expect(httpClient.requests[1].method, 'POST');
    expect(httpClient.requests[1], isNot(isA<http.MultipartRequest>()));
    httpClient.close();
  });

  test('omitted language is omitted from JSON submit body', () async {
    final httpClient = _ScriptedClient([
      (_) => _jsonResponse({
        'media_reference': 'ref.wav',
        'byte_length': 1,
      }, status: 201),
      (req) {
        expect(req, isA<http.Request>());
        final body =
            jsonDecode(utf8.decode((req as http.Request).bodyBytes))
                as Map<String, dynamic>;
        expect(body.containsKey('language'), isFalse);
        return _jsonResponse({
          'job_id': 'job-2',
          'status': 'completed',
          'transcript': {'text': 'x', 'language': 'en'},
        }, status: 202);
      },
    ]);
    final apiClient = ApiClient(
      httpClient: httpClient,
      getBaseUrl: () async => 'https://worker.enjoy.bot',
      getAccessToken: () async => 'token',
    );
    final cap = EnjoyAsrCapability(
      AsrApi(apiClient),
      uploadApi: AsrMediaUploadApi(apiClient),
      pollInitialDelay: Duration.zero,
      pollMaxDelay: Duration.zero,
    );

    await cap.transcribe(
      AsrRequest(
        audioBytes: Uint8List.fromList([1]),
        filename: 'a.wav',
        language: null,
        durationSeconds: 900,
        idempotencyKey: 'idem-2',
      ),
    );
    httpClient.close();
  });
}
