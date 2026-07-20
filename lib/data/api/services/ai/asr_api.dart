/// `POST /audio/transcriptions` (Whisper short-clip + Deepgram long-form).
library;

import 'package:enjoy_player/data/api/rest_api.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_models.dart';

class AsrApi extends RestApi {
  AsrApi(super.client);

  static const _path = '/audio/transcriptions';

  /// Short-clip Whisper path (`multipart/form-data`).
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
    return client.postMultipartJson(
      _path,
      fileFieldName: 'file',
      fileBytes: audioBytes,
      fileFilename: filename,
      fields: fields,
    );
  }

  /// Long-form Deepgram job submit (`application/json`).
  Future<AsrLongFormJob> submitLongForm({
    required String mediaReference,
    required double durationSeconds,
    required String idempotencyKey,
    String? language,
  }) async {
    final map = await client.postJson(
      _path,
      body: {
        'mediaReference': mediaReference,
        'durationSeconds': durationSeconds,
        'idempotencyKey': idempotencyKey,
        if (language != null && language.isNotEmpty) 'language': language,
      },
    );
    return AsrLongFormJob.fromJson(map);
  }

  /// Poll long-form job status.
  Future<AsrLongFormJob> getTranscriptionJob(String jobId) async {
    final map = await client.getJson('$_path/$jobId');
    return AsrLongFormJob.fromJson(map);
  }
}
