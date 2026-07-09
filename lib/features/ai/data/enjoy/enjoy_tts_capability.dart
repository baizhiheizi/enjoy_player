import 'dart:math';

import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/services/ai/azure_token_cache.dart';
import 'package:enjoy_player/features/ai/data/azure_language_mapper.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/tts_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_request.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_result.dart';

/// Enjoy TTS: worker-issued Azure token + native Speech SDK synthesis.
///
/// Mirrors [EnjoyAssessmentCapability] — fetches a short-lived token via
/// [AzureTokenCache], then calls [AzureSpeech.instance.synthesize] on the
/// native plugin. The token route keeps credit accounting on the Enjoy side.
final class EnjoyTtsCapability implements TtsCapability {
  EnjoyTtsCapability({required this._tokenCache, AzureSpeech? sdk})
    : _sdk = sdk ?? AzureSpeech.instance;

  final AzureTokenCache _tokenCache;
  final AzureSpeech _sdk;

  @override
  Future<TtsResult> synthesize(TtsRequest request) async {
    final text = request.text.trim();
    if (text.isEmpty) {
      throw const ApiException(
        message: 'TTS input text is empty',
        statusCode: 400,
      );
    }

    final azureLanguage = mapTranscriptLanguageToAzure(request.language);
    if (azureLanguage == null) {
      throw ApiException(
        message:
            'Speech synthesis is not supported for language '
            '"${request.language}"',
        statusCode: 400,
      );
    }

    // Estimate duration for worker cost attribution: ~150 words per minute,
    // ~5 chars per word → ~750 chars per minute → ~12.5 chars per second.
    final estimatedSeconds = max(1, (text.length / 12.5).ceil());

    final token = await _tokenCache.getToken(
      durationSeconds: estimatedSeconds,
      purpose: 'tts',
    );

    try {
      final outcome = await _sdk.synthesize(
        AzureSpeechSynthesisParams(
          text: text,
          language: azureLanguage,
          subscriptionKey: token.token,
          region: token.region,
          voice: request.voice,
        ),
      );

      return TtsResult(audioBytes: outcome.audioBytes, format: outcome.format);
    } on AzureSpeechException catch (e) {
      throw ApiException(message: e.message, statusCode: 502, body: e.code);
    }
  }
}
