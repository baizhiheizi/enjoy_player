import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'azure_speech_exception.dart';
import 'azure_speech_params.dart';
import 'azure_speech_platform.dart';
import 'models.dart';

/// Default [MethodChannel] implementation (`azure_speech`).
final class MethodChannelAzureSpeech extends AzureSpeechPlatform {
  MethodChannelAzureSpeech({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('azure_speech');

  final MethodChannel _channel;

  @override
  Future<AzurePronunciationAssessmentResult> assess(
    AzurePronunciationAssessmentParams params,
  ) async {
    if (kIsWeb) {
      throw const AzureSpeechException(
        code: 'unsupported',
        message: 'Azure Speech is not supported on web.',
      );
    }
    try {
      final raw = await _channel.invokeMethod<String>('assess', params.toMap());
      if (raw == null || raw.isEmpty) {
        throw const AzureSpeechException(
          code: 'empty_result',
          message: 'Native layer returned no JSON.',
        );
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw AzureSpeechException(
          code: 'parse_error',
          message: 'Assessment JSON root was not an object.',
          details: raw,
        );
      }
      return AzurePronunciationAssessmentResult.fromJson(decoded);
    } on PlatformException catch (e, st) {
      Error.throwWithStackTrace(
        AzureSpeechException(
          code: e.code,
          message: e.message ?? e.code,
          details: e.details,
        ),
        st,
      );
    } on FormatException catch (e, st) {
      Error.throwWithStackTrace(
        AzureSpeechException(
          code: 'parse_error',
          message: e.message,
        ),
        st,
      );
    }
  }
}
