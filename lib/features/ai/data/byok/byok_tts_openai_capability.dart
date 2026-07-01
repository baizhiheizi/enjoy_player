import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_openai_speech_client.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/tts_capability.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_request.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_result.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
import 'package:http/http.dart' as http;

/// TTS via user OpenAI-compatible speech endpoint.
final class ByokTtsOpenAiCapability implements TtsCapability {
  ByokTtsOpenAiCapability({
    required this._config,
    required this._secrets,
    this._httpClient,
  });

  final SpeechByokConfig _config;
  final ByokSecretStoreBase _secrets;
  final http.Client? _httpClient;

  @override
  Future<TtsResult> synthesize(TtsRequest request) async {
    if (_config.kind != SpeechByokKind.openAiCompatible) {
      throw StateError('OpenAI TTS BYOK requires openAiCompatible configuration');
    }

    final baseUrl = _config.baseUrl?.trim();
    final model = _config.model?.trim();
    if (baseUrl == null || baseUrl.isEmpty || model == null || model.isEmpty) {
      throw const ApiException(
        message: 'TTS BYOK base URL and model are not configured',
        statusCode: 400,
      );
    }

    final apiKey = await _secrets.readApiKey(ModalityKind.tts);
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const ByokNotConfiguredFailure(ModalityKind.tts);
    }

    final text = request.text.trim();
    if (text.isEmpty) {
      throw const ApiException(
        message: 'TTS input text is empty',
        statusCode: 400,
      );
    }

    final audioBytes = await postOpenAiSpeech(
      baseUrl: baseUrl,
      apiKey: apiKey.trim(),
      model: model,
      input: text,
      voice: request.voice?.trim().isNotEmpty == true ? request.voice!.trim() : 'alloy',
      client: _httpClient,
    );

    return TtsResult(audioBytes: audioBytes, format: 'mp3');
  }
}
