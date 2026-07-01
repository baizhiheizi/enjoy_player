import 'dart:io';

import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_assessment_azure_capability.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSecretStore implements ByokSecretStoreBase {
  _FakeSecretStore(this._key);

  final String? _key;

  @override
  Future<void> deleteApiKey(ModalityKind modality) async {}

  @override
  Future<bool> hasApiKey(ModalityKind modality) async =>
      _key != null && _key.isNotEmpty;

  @override
  Future<String?> readApiKey(ModalityKind modality) async => _key;

  @override
  Future<void> writeApiKey(ModalityKind modality, String apiKey) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('azure_speech');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'ByokAssessmentAzureCapability with mocked subscription key + native JSON',
    () async {
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
          .setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'assess');
        final args = call.arguments as Map<Object?, Object?>;
        expect(args['subscriptionKey'], 'azure-sub-key');
        expect(args['region'], 'eastus');
        expect(args.containsKey('token'), isFalse);
        return json;
      });

      final tmp = await Directory.systemTemp.createTemp('byok_assess_test');
      final wav = File('${tmp.path}/t.wav');
      await wav.writeAsBytes(<int>[1, 2, 3]);

      final cap = ByokAssessmentAzureCapability(
        config: const SpeechByokConfig(
          kind: SpeechByokKind.azureSpeech,
          region: 'eastus',
        ),
        secrets: _FakeSecretStore('azure-sub-key'),
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
    },
  );

  test('throws when subscription key is missing', () async {
    final cap = ByokAssessmentAzureCapability(
      config: const SpeechByokConfig(
        kind: SpeechByokKind.azureSpeech,
        region: 'eastus',
      ),
      secrets: _FakeSecretStore(null),
    );

    await expectLater(
      cap.assess(
        AssessmentRequest(
          audioPath: '/missing.wav',
          referenceText: 'Hi',
          language: 'en',
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });
}
