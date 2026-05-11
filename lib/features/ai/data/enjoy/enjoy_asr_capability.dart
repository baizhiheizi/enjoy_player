import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/services/ai/asr_api.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';

final class EnjoyAsrCapability implements AsrCapability {
  EnjoyAsrCapability(this._api);

  final AsrApi _api;

  @override
  Future<AsrResult> transcribe(AsrRequest request) async {
    try {
      final map = await _api.transcribe(
        audioBytes: request.audioBytes.toList(),
        filename: request.filename,
        model: request.model,
        language: request.language,
        prompt: request.prompt,
        responseFormat: request.responseFormat,
        durationSeconds: request.durationSeconds,
      );
      return AsrResult.fromJson(map);
    } on ApiException {
      rethrow;
    }
  }
}
