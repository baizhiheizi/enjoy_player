import 'dart:io';

import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/features/ai/data/azure_assessment_staging_path.dart';
import 'package:enjoy_player/features/ai/data/azure_assessment_wav_normalizer.dart';
import 'package:enjoy_player/features/ai/data/azure_language_mapper.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_azure_speech_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';

final _log = logNamed('ai.byok.asr.azure');

/// ASR via user Azure Speech subscription key + region (native recognize-once).
final class ByokAsrAzureCapability extends ByokAzureSpeechCapability
    implements AsrCapability {
  ByokAsrAzureCapability({
    required super.config,
    required super.secrets,
    super.sdk,
  });

  @override
  ModalityKind get kind => ModalityKind.asr;

  @override
  String get capabilityLabel => 'ASR';

  @override
  Future<AsrResult> transcribe(AsrRequest request) async {
    final (:region, apiKey: subscriptionKey) = await resolveCredentials();

    final azureLanguage = mapTranscriptLanguageToAzure(request.language);
    if (azureLanguage == null) {
      throw StateError(
        'Speech recognition is not supported for language "${request.language}"',
      );
    }

    final reqPath = request.audioPath;
    String? tempWavPath;
    late final String sourceWavPath;
    if (reqPath != null && reqPath.isNotEmpty) {
      sourceWavPath = reqPath;
    } else {
      tempWavPath = await newAzureAssessmentStagingWavPath();
      await File(
        tempWavPath,
      ).writeAsBytes(request.audioBytes ?? const [], flush: true);
      sourceWavPath = tempWavPath;
    }

    String? normalizedPath;
    String? stagedPath;
    try {
      normalizedPath = await tryCreateNormalizedAzureAssessmentWav(
        sourceWavPath,
      );
      final candidate = normalizedPath ?? sourceWavPath;
      final staged = await stageWavForAzureAssessment(candidate);
      stagedPath = staged.$2 ? staged.$1 : null;
      final audioPath = staged.$1;
      _log.info('BYOK Azure ASR: staging path=$audioPath');

      final outcome = await sdk.transcribe(
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
      for (final path in <String?>[stagedPath, normalizedPath, tempWavPath]) {
        if (path == null) continue;
        try {
          await File(path).delete();
        } catch (_) {}
      }
    }
  }
}
