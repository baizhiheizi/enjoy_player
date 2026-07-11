import 'dart:convert';
import 'dart:typed_data';

import 'package:enjoy_player/features/ai/data/byok/byok_http_client.dart';
import 'package:http/http.dart' as http;

/// OpenAI-compatible `POST /audio/speech` with user credentials.
Future<Uint8List> postOpenAiSpeech({
  required String baseUrl,
  required String apiKey,
  required String model,
  required String input,
  String voice = 'alloy',
  http.Client? client,
}) async {
  final uri = guardByokBaseUrl(
    baseUrl: baseUrl,
    path: 'audio/speech',
    purpose: 'OpenAI speech synthesis',
  );
  final httpClient = client ?? http.Client();

  try {
    final response = await httpClient.post(
      uri,
      headers: {
        ...byokBearerHeaders(apiKey: apiKey, accept: 'audio/mpeg'),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, Object>{
        'model': model,
        'input': input,
        'voice': voice,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Uint8List.fromList(response.bodyBytes);
    }

    throwByokHttpError(
      purpose: 'Speech synthesis',
      statusCode: response.statusCode,
      body: response.body,
    );
  } finally {
    if (client == null) {
      httpClient.close();
    }
  }
}
