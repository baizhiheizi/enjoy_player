import 'dart:io';

import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/data/azure_assessment_wav_normalizer.dart';
import 'package:enjoy_player/features/ai/data/azure_language_mapper.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_speech_guards.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// ASR via user Azure Speech subscription key + region (native recognize-once).
final class ByokAsrAzureCapability implements AsrCapability {
  ByokAsrAzureCapability({
    required this._config,
    required this._secrets,
    AzureSpeech? sdk,
  }) : _sdk = sdk ?? AzureSpeech.instance;

  final SpeechByokConfig _config;
  final ByokSecretStoreBase _secrets;
  final AzureSpeech _sdk;

  @override
  Future<AsrResult> transcribe(AsrRequest request) async {
    final (:region, apiKey: subscriptionKey) = await guardAzureSpeechConfig(
      config: _config,
      secrets: _secrets,
      kind: ModalityKind.asr,
      capabilityLabel: 'ASR',
    );

    final azureLanguage = mapTranscriptLanguageToAzure(request.language);
    if (azureLanguage == null) {
      throw StateError(
        'Speech recognition is not supported for language "${request.language}"',
      );
    }

    final dir = Directory.systemTemp;
    final wavPath = p.join(dir.path, 'asr_${const Uuid().v4()}.wav');
    await File(wavPath).writeAsBytes(request.audioBytes, flush: true);

    String? normalizedPath;
    try {
      normalizedPath = await tryCreateNormalizedAzureAssessmentWav(wavPath);
      final audioPath = normalizedPath ?? wavPath;

      final outcome = await _sdk.transcribe(
        AzureSpeechTranscriptionParams(
          audioPath: audioPath,
          language: azureLanguage,
          subscriptionKey: subscriptionKey,
          region: region,
        ),
      );

      return AsrResult(text: outcome.text.trim(), language: request.language);
    } on AzureSpeechException catch (e) {
      throw ApiException(message: e.message, statusCode: 502, body: e.code);
    } finally {
      if (normalizedPath != null) {
        try {
          await File(normalizedPath).delete();
        } catch (_) {}
      }
      try {
        await File(wavPath).delete();
      } catch (_) {}
    }
  }
}
