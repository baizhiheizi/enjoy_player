import 'dart:io';

import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/api/services/ai/azure_token_cache.dart';
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

    final (wavPath, deleteAfter) = await _materializeWav(request);
    try {
      final azureLanguage = mapTranscriptLanguageToAzure(request.language);
      final params = AzurePronunciationAssessmentParams(
        audioPath: wavPath,
        referenceText: _cleanReferenceText(request.referenceText),
        language: azureLanguage,
        token: token.token,
        region: token.region,
      );
      final detail = await _sdk.assess(params);
      return AssessmentResult(
        detail: detail,
        rawJson: Map<String, dynamic>.from(detail.toJson()),
      );
    } on AzureSpeechException catch (e, st) {
      _log.warning('Azure assessment failed', e, st);
      rethrow;
    } finally {
      if (deleteAfter) {
        try {
          await File(wavPath).delete();
        } catch (e, st) {
          _log.fine('temp wav cleanup failed: $wavPath', e, st);
        }
      }
    }
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
