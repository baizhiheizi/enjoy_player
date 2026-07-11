import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_speech_guards.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_whisper_client.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
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
    final (:baseUrl, :model, :apiKey) = await guardOpenAiSpeechConfig(
      config: _config,
      secrets: _secrets,
      kind: ModalityKind.asr,
      capabilityLabel: 'ASR',
    );

    final map = await postWhisperTranscription(
      baseUrl: baseUrl,
      apiKey: apiKey,
      audioBytes: request.audioBytes,
      filename: request.filename,
      model: model,
      language: request.language == null
          ? null
          : workerLanguageBase(request.language!),
      prompt: request.prompt,
      responseFormat: request.responseFormat,
      client: _httpClient,
    );

    return AsrResult.fromJson(map);
  }
}
