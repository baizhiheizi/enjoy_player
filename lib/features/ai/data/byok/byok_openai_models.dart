import 'dart:convert';

import 'package:enjoy_player/features/ai/data/byok/byok_http_client.dart';
import 'package:http/http.dart' as http;

/// Lists models from an OpenAI-compatible `GET /models` endpoint.
Future<List<String>> fetchOpenAiCompatibleModels({
  required String baseUrl,
  required String apiKey,
}) async {
  final uri = guardByokBaseUrl(
    baseUrl: baseUrl,
    path: 'models',
    purpose: 'model fetch',
  );

  final response = await http.get(
    uri,
    headers: byokBearerHeaders(apiKey: apiKey),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throwByokHttpError(
      purpose: 'Failed to fetch models',
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  final data = decoded['data'];
  if (data is! List) return const [];

  final ids =
      data
          .map((row) => (row as Map)['id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList()
        ..sort();
  return ids;
}
