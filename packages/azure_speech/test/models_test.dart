import 'dart:convert';

import 'package:azure_speech/azure_speech.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('primaryNBest returns the first hypothesis', () {
    const json = '''
{
  "RecognitionStatus": "Success",
  "Offset": 0,
  "Duration": 10000000,
  "DisplayText": "Hello.",
  "NBest": [
    {
      "Confidence": 0.9,
      "Lexical": "hello",
      "ITN": "hello",
      "MaskedITN": "hello",
      "Display": "Hello.",
      "PronunciationAssessment": {
        "AccuracyScore": 90,
        "FluencyScore": 88,
        "CompletenessScore": 95,
        "PronScore": 91
      },
      "Words": []
    }
  ]
}''';
    final result = AzurePronunciationAssessmentResult.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );

    expect(result.primaryNBest, same(result.nBest.first));
    expect(
      result.primaryScores,
      same(result.primaryNBest!.pronunciationAssessment),
    );
  });

  test('primaryNBest is null when nBest is empty', () {
    const json = '''
{
  "RecognitionStatus": "Success",
  "Offset": 0,
  "Duration": 0,
  "DisplayText": "",
  "NBest": []
}''';
    final result = AzurePronunciationAssessmentResult.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );

    expect(result.nBest, isEmpty);
    expect(result.primaryNBest, isNull);
    expect(result.primaryScores, isNull);
  });
}
