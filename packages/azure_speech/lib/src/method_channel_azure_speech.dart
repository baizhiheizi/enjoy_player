import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'azure_pronunciation_assessment_exception.dart';
import 'azure_pronunciation_assessment_params.dart';
import 'azure_pronunciation_assessment_platform.dart';
import 'models.dart';

/// Default [MethodChannel] implementation.
final class MethodChannelAzurePronunciationAssessment
    extends AzurePronunciationAssessmentPlatform {
  MethodChannelAzurePronunciationAssessment({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('azure_pronunciation_assessment');

  final MethodChannel _channel;

  @override
  Future<AzurePronunciationAssessmentResult> assess(
    AzurePronunciationAssessmentParams params,
  ) async {
    if (kIsWeb) {
      throw const AzurePronunciationAssessmentException(
        code: 'unsupported',
        message: 'Azure pronunciation assessment is not supported on web.',
      );
    }
    try {
      final raw = await _channel.invokeMethod<String>('assess', params.toMap());
      if (raw == null || raw.isEmpty) {
        throw const AzurePronunciationAssessmentException(
          code: 'empty_result',
          message: 'Native layer returned no JSON.',
        );
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw AzurePronunciationAssessmentException(
          code: 'parse_error',
          message: 'Assessment JSON root was not an object.',
          details: raw,
        );
      }
      return AzurePronunciationAssessmentResult.fromJson(decoded);
    } on PlatformException catch (e, st) {
      Error.throwWithStackTrace(
        AzurePronunciationAssessmentException(
          code: e.code,
          message: e.message ?? e.code,
          details: e.details,
        ),
        st,
      );
    } on FormatException catch (e, st) {
      Error.throwWithStackTrace(
        AzurePronunciationAssessmentException(
          code: 'parse_error',
          message: e.message,
        ),
        st,
      );
    }
  }
}
