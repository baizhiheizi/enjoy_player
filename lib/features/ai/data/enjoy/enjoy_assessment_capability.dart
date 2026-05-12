import 'dart:io';

import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/api/services/ai/azure_token_cache.dart';
import 'package:enjoy_player/features/ai/data/azure_assessment_wav_normalizer.dart';
import 'package:enjoy_player/features/ai/data/azure_language_mapper.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/assessment_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

final Logger _log = logNamed('ai.enjoy.assessment');

/// Enjoy pronunciation assessment: worker Azure token + native Speech SDK.
final class EnjoyAssessmentCapability implements AssessmentCapability {
  EnjoyAssessmentCapability({
    required AzureTokenCache tokenCache,
    AzureSpeech? sdk,
  }) : _tokenCache = tokenCache,
       _sdk = sdk ?? AzureSpeech.instance;

  final AzureTokenCache _tokenCache;
  final AzureSpeech _sdk;

  @override
  Future<AssessmentResult> assess(AssessmentRequest request) async {
    if (kIsWeb) {
      throw UnimplementedError(
        'Enjoy pronunciation assessment is not available on web.',
      );
    }

    final durationSeconds = _estimateDurationSeconds(request);
    final token = await _tokenCache.getToken(durationSeconds: durationSeconds);

    final (wavPath, deleteMaterialized) = await _materializeWav(request);
    String? normalizedPath;
    try {
      normalizedPath = await tryCreateNormalizedAzureAssessmentWav(wavPath);
      _log.fine(
        normalizedPath == null
            ? 'Azure assessment: using original WAV (normalization unavailable / silent)'
            : 'Azure assessment: using normalized WAV $normalizedPath',
      );

      final azureLanguage = mapTranscriptLanguageToAzure(request.language);
      final referenceText = _cleanReferenceText(request.referenceText);

      AzureSpeechAssessmentOutcome outcome = await _assessPath(
        audioPath: normalizedPath ?? wavPath,
        referenceText: referenceText,
        language: azureLanguage,
        token: token.token,
        region: token.region,
        usedNormalizedWav: normalizedPath != null,
        attempt: normalizedPath != null ? 'normalized' : 'original',
      );

      // Defense in depth: if the normalized take came back blank (all zero
      // scores / all omissions / displayText="."), retry against the original
      // file to rule out a bad FFmpeg decode masking real audio.
      if (normalizedPath != null && _looksLikeEmptyAssessment(outcome)) {
        _log.warning(
          'Azure assessment normalized run came back blank; retrying with the '
          'original recording to rule out a bad FFmpeg decode.',
        );
        try {
          final originalOutcome = await _assessPath(
            audioPath: wavPath,
            referenceText: referenceText,
            language: azureLanguage,
            token: token.token,
            region: token.region,
            usedNormalizedWav: false,
            attempt: 'original-fallback',
          );
          if (!_looksLikeEmptyAssessment(originalOutcome)) {
            outcome = originalOutcome;
          }
        } on AzureSpeechException catch (e, st) {
          _log.warning(
            'Azure assessment original fallback failed; keeping normalized result',
            e,
            st,
          );
        }
      }

      return AssessmentResult(
        detail: outcome.detail,
        rawJson: Map<String, dynamic>.from(outcome.rawJson),
      );
    } on AzureSpeechException catch (e, st) {
      _log.warning('Azure assessment failed', e, st);
      rethrow;
    } finally {
      if (normalizedPath != null) {
        try {
          await File(normalizedPath).delete();
        } catch (e, st) {
          _log.fine('normalized wav cleanup failed: $normalizedPath', e, st);
        }
      }
      if (deleteMaterialized) {
        try {
          await File(wavPath).delete();
        } catch (e, st) {
          _log.fine('temp wav cleanup failed: $wavPath', e, st);
        }
      }
    }
  }

  Future<AzureSpeechAssessmentOutcome> _assessPath({
    required String audioPath,
    required String referenceText,
    required String language,
    required String token,
    required String region,
    required bool usedNormalizedWav,
    required String attempt,
  }) async {
    final params = AzurePronunciationAssessmentParams(
      audioPath: audioPath,
      referenceText: referenceText,
      language: language,
      token: token,
      region: region,
    );
    final audioBytes = await File(audioPath).length();
    final outcome = await _sdk.assess(params);
    _logAssessmentOutcome(
      outcome: outcome,
      audioPath: audioPath,
      audioBytes: audioBytes,
      usedNormalizedWav: usedNormalizedWav,
      language: language,
      referenceChars: referenceText.length,
      attempt: attempt,
    );
    return outcome;
  }

  static void _logAssessmentOutcome({
    required AzureSpeechAssessmentOutcome outcome,
    required String audioPath,
    required int audioBytes,
    required bool usedNormalizedWav,
    required String language,
    required int referenceChars,
    required String attempt,
  }) {
    final d = outcome.detail;
    final nb = d.nBest.isEmpty ? null : d.nBest.first;
    final sc = nb?.pronunciationAssessment;
    final words = nb?.words ?? const <AzureWordAssessment>[];
    var omissions = 0;
    for (final w in words) {
      if (w.pronunciationAssessment.errorType == 'Omission') omissions++;
    }
    _log.fine(
      'Azure assessment attempt=$attempt audio=${p.basename(audioPath)} '
      'path=$audioPath bytes=$audioBytes normalized=$usedNormalizedWav '
      'language=$language refChars=$referenceChars',
    );
    _log.fine(
      'Azure assessment result status=${d.recognitionStatus} '
      'displayText="${d.displayText}" nBest=${d.nBest.length} '
      'pronScore=${sc?.pronScore} accuracy=${sc?.accuracyScore} '
      'fluency=${sc?.fluencyScore} completeness=${sc?.completenessScore} '
      'words=${words.length} omissions=$omissions',
    );
    if (sc != null &&
        sc.pronScore == 0 &&
        sc.accuracyScore == 0 &&
        sc.fluencyScore == 0 &&
        sc.completenessScore == 0) {
      _log.warning(
        'Azure assessment returned all-zero segment scores — often means '
        'no usable speech matched the reference (silent/wrong file, format, '
        'or language). If playback of the take sounds fine, capture logs above '
        'and check FFmpeg normalization and transcript language.',
      );
    }
  }

  static bool _looksLikeEmptyAssessment(AzureSpeechAssessmentOutcome outcome) {
    final nb = outcome.detail.nBest.isEmpty ? null : outcome.detail.nBest.first;
    final sc = nb?.pronunciationAssessment;
    if (sc == null) return true;
    final words = nb?.words ?? const <AzureWordAssessment>[];
    final allScoresZero =
        sc.pronScore == 0 &&
        sc.accuracyScore == 0 &&
        sc.fluencyScore == 0 &&
        sc.completenessScore == 0;
    final allWordsOmitted =
        words.isNotEmpty &&
        words.every((w) => w.pronunciationAssessment.errorType == 'Omission');
    final displayLooksEmpty = outcome.detail.displayText.trim() == '.';
    return allScoresZero && (allWordsOmitted || displayLooksEmpty);
  }

  static int _estimateDurationSeconds(AssessmentRequest request) {
    if (request.durationMs != null && request.durationMs! > 0) {
      return (request.durationMs! / 1000).ceil().clamp(1, 300);
    }
    final bytes = request.audioBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return (bytes.length ~/ 32000).clamp(1, 300);
    }
    try {
      final len = File(request.audioPath!.trim()).lengthSync();
      return (len ~/ 32000).clamp(1, 300);
    } catch (_) {
      return 15;
    }
  }

  static String _cleanReferenceText(String referenceText) {
    return referenceText
        .trim()
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Returns `(path, shouldDeleteAfter)`.
  static Future<(String, bool)> _materializeWav(AssessmentRequest request) async {
    final pathArg = request.audioPath?.trim();
    if (pathArg != null && pathArg.isNotEmpty) {
      final f = File(pathArg);
      if (await f.exists()) {
        return (f.absolute.path, false);
      }
      throw StateError('Recording file not found: $pathArg');
    }

    final bytes = request.audioBytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('No audio bytes and no valid audioPath');
    }

    final dir = await getTemporaryDirectory();
    final out = p.join(dir.path, 'assess_${const Uuid().v4()}.wav');
    await File(out).writeAsBytes(bytes, flush: true);
    return (out, true);
  }
}
