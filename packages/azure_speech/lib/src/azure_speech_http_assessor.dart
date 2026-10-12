/// REST pronunciation assessment for Linux, where the vendored plugin ships no
/// native Speech SDK implementation.
///
/// One POST of the WAV to the short-audio recognition endpoint with a
/// `Pronunciation-Assessment` header. The REST response carries scores flat on
/// each NBest / word / syllable / phoneme entry; [normalizeRestAssessmentJson]
/// re-nests them under `PronunciationAssessment` so the stored JSON and
/// [AzurePronunciationAssessmentResult.fromJson] see the Speech SDK shape on
/// every platform. Short-audio REST accepts up to 30 s of audio.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'azure_speech_assessment_outcome.dart';
import 'azure_speech_exception.dart';
import 'azure_speech_params.dart';
import 'models.dart';

/// Assesses pronunciation over Azure's REST short-audio endpoint.
final class AzureSpeechHttpAssessor {
  AzureSpeechHttpAssessor({
    HttpClient? client,
    Uri Function(String region, String language)? endpointFor,
  }) : _client = client ?? HttpClient(),
       _endpointFor =
           endpointFor ??
           ((region, language) => Uri.https(
             '$region.stt.speech.microsoft.com',
             '/speech/recognition/conversation/cognitiveservices/v1',
             {'language': language, 'format': 'detailed'},
           ));

  final HttpClient _client;
  final Uri Function(String region, String language) _endpointFor;

  Future<AzureSpeechAssessmentOutcome> assess(
    AzurePronunciationAssessmentParams params,
  ) async {
    final map = params.toMap();
    final audio = await File(params.audioPath).readAsBytes();
    final request = await _client.postUrl(
      _endpointFor(params.region, params.language),
    );
    final token = map['token'] as String?;
    if (token != null && token.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    final key = map['subscriptionKey'] as String?;
    if (key != null && key.isNotEmpty) {
      request.headers.set('Ocp-Apim-Subscription-Key', key);
    }
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'audio/wav; codecs=audio/pcm; samplerate=16000',
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(
      'Pronunciation-Assessment',
      base64Encode(utf8.encode(jsonEncode(_assessmentConfig(map)))),
    );
    request.headers.set('User-Agent', 'enjoy-player-azure-speech');
    request.contentLength = audio.length;
    request.add(audio);

    final response = await request.close();
    final bytes = await response
        .fold(BytesBuilder(), (builder, chunk) => builder..add(chunk))
        .then((builder) => builder.takeBytes());
    final body = utf8.decode(bytes, allowMalformed: true);
    if (response.statusCode != HttpStatus.ok) {
      throw AzureSpeechException(
        code: 'assess_http_${response.statusCode}',
        message:
            'Azure pronunciation assessment returned ${response.statusCode}: '
            '${body.length > 200 ? body.substring(0, 200) : body}',
      );
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw AzureSpeechException(
        code: 'parse_error',
        message: 'Assessment JSON root was not an object.',
        details: body,
      );
    }
    final root = normalizeRestAssessmentJson(
      Map<String, dynamic>.from(decoded),
    );
    return AzureSpeechAssessmentOutcome(
      detail: AzurePronunciationAssessmentResult.fromJson(root),
      rawJson: root,
    );
  }

  Map<String, Object?> _assessmentConfig(Map<String, Object?> map) => {
    'ReferenceText': map['referenceText'],
    'GradingSystem': 'HundredMark',
    'Granularity': map['granularity'],
    'Dimension': 'Comprehensive',
    'EnableMiscue': map['enableMiscue'] == true ? 'True' : 'False',
    'EnableProsodyAssessment': map['enableProsody'] == true ? 'True' : 'False',
    'PhonemeAlphabet': map['phonemeAlphabet'],
    'NBestPhonemeCount': map['nbestPhonemeCount'],
  };
}

const _scoreKeys = {
  'AccuracyScore',
  'FluencyScore',
  'CompletenessScore',
  'PronScore',
  'ProsodyScore',
  'ErrorType',
  'NBestPhonemes',
  'Feedback',
};

/// Re-nests the flat REST score fields of every NBest, word, syllable and
/// phoneme entry under `PronunciationAssessment` (the Speech SDK JSON shape).
/// Entries that already carry `PronunciationAssessment` are left as they are.
Map<String, dynamic> normalizeRestAssessmentJson(Map<String, dynamic> root) {
  Map<String, dynamic> nest(Map<String, dynamic> entry) {
    final out = <String, dynamic>{};
    final scores = <String, dynamic>{};
    for (final MapEntry(:key, :value) in entry.entries) {
      if (_scoreKeys.contains(key)) {
        scores[key] = value;
      } else if (value is List &&
          (key == 'Words' || key == 'Syllables' || key == 'Phonemes')) {
        out[key] = [
          for (final item in value)
            item is Map ? nest(Map<String, dynamic>.from(item)) : item,
        ];
      } else {
        out[key] = value;
      }
    }
    if (scores.isNotEmpty && !entry.containsKey('PronunciationAssessment')) {
      out['PronunciationAssessment'] = scores;
    } else {
      out.addAll(scores);
    }
    return out;
  }

  final nBest = root['NBest'];
  if (nBest is! List) return root;
  return {
    ...root,
    'NBest': [
      for (final item in nBest)
        item is Map ? nest(Map<String, dynamic>.from(item)) : item,
    ],
  };
}
