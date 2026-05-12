import 'package:azure_pronunciation_assessment/azure_pronunciation_assessment.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('azure_pronunciation_assessment');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('assess parses JSON from native channel', () async {
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
        "PronScore": 91,
        "ProsodyScore": 80
      },
      "Words": [
        {
          "Word": "hello",
          "Offset": 0,
          "Duration": 10000000,
          "PronunciationAssessment": {
            "AccuracyScore": 92,
            "ErrorType": "None"
          }
        }
      ]
    }
  ]
}''';

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'assess');
      return json;
    });

    final r = await AzurePronunciationAssessment.instance.assess(
      const AzurePronunciationAssessmentParams(
        audioPath: '/tmp/x.wav',
        referenceText: 'Hello',
        language: 'en-US',
        token: 't',
        region: 'eastus',
      ),
    );

    expect(r.displayText, 'Hello.');
    expect(r.nBest, isNotEmpty);
    expect(r.nBest.first.pronunciationAssessment.pronScore, 91);
    expect(r.nBest.first.words.single.word, 'hello');
  });
}
