import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/data/azure_language_mapper.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_speech_guards.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/tts_capability.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_request.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_result.dart';

/// TTS via user Azure Speech subscription key + region (native synthesis).
final class ByokTtsAzureCapability implements TtsCapability {
  ByokTtsAzureCapability({
    required this._config,
    required this._secrets,
    AzureSpeech? sdk,
  }) : _sdk = sdk ?? AzureSpeech.instance;

  final SpeechByokConfig _config;
  final ByokSecretStoreBase _secrets;
  final AzureSpeech _sdk;

  @override
  Future<TtsResult> synthesize(TtsRequest request) async {
    final (:region, apiKey: subscriptionKey) = await guardAzureSpeechConfig(
      config: _config,
      secrets: _secrets,
      kind: ModalityKind.tts,
      capabilityLabel: 'TTS',
    );

    final text = request.text.trim();
    if (text.isEmpty) {
      throw const ApiException(
        message: 'TTS input text is empty',
        statusCode: 400,
      );
    }

    final azureLanguage = mapTranscriptLanguageToAzure(request.language);
    if (azureLanguage == null) {
      throw StateError(
        'Speech synthesis is not supported for language "${request.language}"',
      );
    }

    final voice = request.voice?.trim().isNotEmpty == true
        ? request.voice!.trim()
        : _config.model?.trim();

    try {
      final outcome = await _sdk.synthesize(
        AzureSpeechSynthesisParams(
          text: text,
          language: azureLanguage,
          subscriptionKey: subscriptionKey,
          region: region,
          voice: voice,
        ),
      );

      return TtsResult(
        audioBytes: outcome.audioBytes,
        format: outcome.format,
        wordBoundaries: outcome.wordBoundaries
            .map(
              (w) => TtsWordBoundary(
                text: w.text,
                audioOffsetMs: w.audioOffsetMs,
                durationMs: w.durationMs,
              ),
            )
            .toList(),
      );
    } on AzureSpeechException catch (e) {
      throw ApiException(message: e.message, statusCode: 502, body: e.code);
    }
  }
}
