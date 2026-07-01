import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_whisper_client.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
import 'package:http/http.dart' as http;

/// ASR via user OpenAI-compatible Whisper endpoint.
final class ByokAsrOpenAiCapability implements AsrCapability {
  ByokAsrOpenAiCapability({
    required this._config,
    required this._secrets,
    this._httpClient,
  });

  final SpeechByokConfig _config;
  final ByokSecretStoreBase _secrets;
  final http.Client? _httpClient;

  @override
  Future<AsrResult> transcribe(AsrRequest request) async {
    if (_config.kind != SpeechByokKind.openAiCompatible) {
      throw StateError('OpenAI ASR BYOK requires openAiCompatible configuration');
    }

    final baseUrl = _config.baseUrl?.trim();
    final model = _config.model?.trim();
    if (baseUrl == null || baseUrl.isEmpty || model == null || model.isEmpty) {
      throw const ApiException(
        message: 'ASR BYOK base URL and model are not configured',
        statusCode: 400,
      );
    }

    final apiKey = await _secrets.readApiKey(ModalityKind.asr);
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const ByokNotConfiguredFailure(ModalityKind.asr);
    }

    final map = await postWhisperTranscription(
      baseUrl: baseUrl,
      apiKey: apiKey.trim(),
      audioBytes: request.audioBytes,
      filename: request.filename,
      model: model,
      language: request.language,
      prompt: request.prompt,
      responseFormat: request.responseFormat,
      client: _httpClient,
    );

    return AsrResult.fromJson(map);
  }
}
