/// `POST /audio/transcriptions` (OpenAI-compatible Whisper).
library;

import 'package:enjoy_player/data/api/api_client.dart';

class AsrApi {
  AsrApi(this._client);

  final ApiClient _client;

  static const _path = '/audio/transcriptions';

  Future<Map<String, dynamic>> transcribe({
    required List<int> audioBytes,
    required String filename,
    String? model,
    String? language,
    String? prompt,
    String responseFormat = 'json',
    double? durationSeconds,
  }) {
    final fields = <String, String>{
      'response_format': responseFormat,
      if (model != null && model.isNotEmpty) 'model': model,
      if (language != null && language.isNotEmpty) 'language': language,
      if (prompt != null && prompt.isNotEmpty) 'prompt': prompt,
      if (durationSeconds != null) 'duration_seconds': '$durationSeconds',
    };
    return _client.postMultipartJson(
      _path,
      fileFieldName: 'file',
      fileBytes: audioBytes,
      fileFilename: filename,
      fields: fields,
    );
  }
}
