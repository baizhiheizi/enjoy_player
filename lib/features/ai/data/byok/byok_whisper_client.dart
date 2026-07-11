import 'dart:convert';

import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_http_client.dart';
import 'package:http/http.dart' as http;

/// OpenAI-compatible Whisper `POST /audio/transcriptions` with user credentials.
Future<Map<String, dynamic>> postWhisperTranscription({
  required String baseUrl,
  required String apiKey,
  required List<int> audioBytes,
  required String filename,
  String? model,
  String? language,
  String? prompt,
  String responseFormat = 'json',
  http.Client? client,
}) async {
  final uri = guardByokBaseUrl(
    baseUrl: baseUrl,
    path: 'audio/transcriptions',
    purpose: 'Whisper transcription',
  );

  final request = http.MultipartRequest('POST', uri);
  request.headers.addAll(byokBearerHeaders(apiKey: apiKey));
  request.files.add(
    http.MultipartFile.fromBytes('file', audioBytes, filename: filename),
  );

  final fields = <String, String>{
    'response_format': responseFormat,
    if (model != null && model.isNotEmpty) 'model': model,
    if (language != null && language.isNotEmpty) 'language': language,
    if (prompt != null && prompt.isNotEmpty) 'prompt': prompt,
  };
  request.fields.addAll(fields);

  final httpClient = client ?? http.Client();
  try {
    final streamed = await httpClient.send(request);
    final bodyBytes = await streamed.stream.toBytes();
    final body = utf8.decode(bodyBytes);

    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      if (responseFormat == 'text') {
        return {'text': body.trim()};
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw ApiException(
          message: 'Expected JSON object from Whisper',
          statusCode: streamed.statusCode,
        );
      }
      return Map<String, dynamic>.from(
        decoded.map((k, v) => MapEntry(k.toString(), v)),
      );
    }

    throwByokHttpError(
      purpose: 'Whisper transcription',
      statusCode: streamed.statusCode,
      body: body,
    );
  } finally {
    if (client == null) {
      httpClient.close();
    }
  }
}
