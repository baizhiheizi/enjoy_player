import 'dart:io';

import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/data/api/services/ai/azure_token_cache.dart';
import 'package:enjoy_player/features/ai/data/enjoy/enjoy_assessment_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('azure_speech');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('EnjoyAssessmentCapability with mocked token + native JSON', () async {
    const json = '''
{
  "RecognitionStatus": "Success",
  "Offset": 0,
  "Duration": 10000000,
  "DisplayText": "Hi.",
  "NBest": [
    {
      "Confidence": 0.9,
      "Lexical": "hi",
      "ITN": "hi",
      "MaskedITN": "hi",
      "Display": "Hi.",
      "PronunciationAssessment": {
        "AccuracyScore": 90,
        "FluencyScore": 88,
        "CompletenessScore": 95,
        "PronScore": 91,
        "ProsodyScore": 80
      },
      "Words": [
        {
          "Word": "hi",
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
        .setMockMethodCallHandler(channel, (call) async => json);

    final tmp = await Directory.systemTemp.createTemp('assess_cap_test');
    final wav = File('${tmp.path}/t.wav');
    await wav.writeAsBytes(<int>[1, 2, 3]);

    final cache = AzureTokenCache(
      debugOverrideFetch: () async => const <String, dynamic>{
        'token': 'fake-token',
        'region': 'eastus',
      },
    );

    final cap = EnjoyAssessmentCapability(
      tokenCache: cache,
      sdk: AzureSpeech.instance,
    );

    final result = await cap.assess(
      AssessmentRequest(
        audioPath: wav.path,
        referenceText: 'Hi there',
        language: 'en',
      ),
    );

    expect(result.detail.displayText, 'Hi.');
    expect(result.rawJson['DisplayText'], 'Hi.');
    await tmp.delete(recursive: true);
  });
}
