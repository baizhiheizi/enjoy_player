import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/features/ai/data/azure_language_mapper.dart';
import 'package:enjoy_player/features/ai/data/azure_tts_result_mapper.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_azure_speech_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/tts_capability.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_request.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_result.dart';

/// TTS via user Azure Speech subscription key + region (native synthesis).
final class ByokTtsAzureCapability extends ByokAzureSpeechCapability
    implements TtsCapability {
  ByokTtsAzureCapability({
    required super.config,
    required super.secrets,
    super.sdk,
  });

  @override
  ModalityKind get kind => ModalityKind.tts;

  @override
  String get capabilityLabel => 'TTS';

  @override
  Future<TtsResult> synthesize(TtsRequest request) async {
    final (:region, apiKey: subscriptionKey) = await resolveCredentials();

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
        : config.model?.trim();

    try {
      final outcome = await sdk.synthesize(
        AzureSpeechSynthesisParams(
          text: text,
          language: azureLanguage,
          subscriptionKey: subscriptionKey,
          region: region,
          voice: voice,
        ),
      );

      return ttsResultFromAzureOutcome(outcome);
    } on AzureSpeechException catch (e) {
      throw ApiException(message: e.message, statusCode: 502, body: e.code);
    }
  }
}
