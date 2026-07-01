import 'dart:convert';

import 'package:azure_speech/azure_speech.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('azure_speech');

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

    final r = (await AzureSpeech.instance.assess(
      const AzurePronunciationAssessmentParams(
        audioPath: '/tmp/x.wav',
        referenceText: 'Hello',
        language: 'en-US',
        token: 't',
        region: 'eastus',
      ),
    )).detail;

    expect(r.displayText, 'Hello.');
    expect(r.nBest, isNotEmpty);
    expect(r.nBest.first.pronunciationAssessment.pronScore, 91);
    expect(r.nBest.first.words.single.word, 'hello');
  });

  test('assess sends subscriptionKey when provided', () async {
    const json = '{"RecognitionStatus":"Success","DisplayText":"Hi.","NBest":[]}';

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'assess');
          final args = Map<String, dynamic>.from(
            call.arguments as Map<Object?, Object?>,
          );
          expect(args['subscriptionKey'], 'sub-key');
          expect(args.containsKey('token'), isFalse);
          return json;
        });

    await AzureSpeech.instance.assess(
      const AzurePronunciationAssessmentParams(
        audioPath: '/tmp/x.wav',
        referenceText: 'Hi',
        language: 'en-US',
        subscriptionKey: 'sub-key',
        region: 'eastus',
      ),
    );
  });

  test('transcribe returns text from native channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'transcribe');
          final args = Map<String, dynamic>.from(
            call.arguments as Map<Object?, Object?>,
          );
          expect(args['subscriptionKey'], 'sub-key');
          expect(args['region'], 'eastus');
          return 'Recognized text.';
        });

    final outcome = await AzureSpeech.instance.transcribe(
      const AzureSpeechTranscriptionParams(
        audioPath: '/tmp/x.wav',
        language: 'en-US',
        subscriptionKey: 'sub-key',
        region: 'eastus',
      ),
    );

    expect(outcome.text, 'Recognized text.');
  });

  test('synthesize returns audio bytes from native channel', () async {
    final audio = Uint8List.fromList([1, 2, 3, 4]);
    final encoded = base64Encode(audio);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'synthesize');
          final args = Map<String, dynamic>.from(
            call.arguments as Map<Object?, Object?>,
          );
          expect(args['subscriptionKey'], 'sub-key');
          expect(args['region'], 'eastus');
          expect(args['text'], 'Hello');
          expect(args['language'], 'en-US');
          return encoded;
        });

    final outcome = await AzureSpeech.instance.synthesize(
      const AzureSpeechSynthesisParams(
        text: 'Hello',
        language: 'en-US',
        subscriptionKey: 'sub-key',
        region: 'eastus',
      ),
    );

    expect(outcome.audioBytes, audio);
    expect(outcome.format, 'wav');
  });

  test('toMap rejects missing auth', () {
    expect(
      () => const AzurePronunciationAssessmentParams(
        audioPath: '/tmp/x.wav',
        referenceText: 'Hi',
        language: 'en-US',
        region: 'eastus',
      ).toMap(),
      throwsArgumentError,
    );
  });

  test(
    'fromJson tolerates null word Offset/Duration (Azure omission edge case)',
    () {
      const raw = '''
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
        "PronScore": 91
      },
      "Words": [
        {
          "Word": "hi",
          "Offset": null,
          "Duration": null,
          "PronunciationAssessment": {
            "AccuracyScore": 92,
            "ErrorType": "None"
          }
        }
      ]
    }
  ]
}''';
      final r = AzurePronunciationAssessmentResult.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final w = r.nBest.first.words.single;
      expect(w.offset, 0);
      expect(w.duration, 0);
      expect(w.word, 'hi');
    },
  );

  test('fromJson tolerates null word PronunciationAssessment', () {
    const raw = '''
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
        "PronScore": 91
      },
      "Words": [
        {
          "Word": "hi",
          "Offset": 0,
          "Duration": 10000000,
          "PronunciationAssessment": null
        }
      ]
    }
  ]
}''';
    final r = AzurePronunciationAssessmentResult.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    final w = r.nBest.first.words.single;
    expect(w.pronunciationAssessment.accuracyScore, 0);
    expect(w.pronunciationAssessment.errorType, 'None');
  });

  test('fromJson tolerates missing NBest and string tick fields', () {
    const raw = '''
{
  "RecognitionStatus": "Success",
  "Offset": "0",
  "Duration": "10000000",
  "DisplayText": "Hi.",
  "NBest": null
}''';
    final r = AzurePronunciationAssessmentResult.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    expect(r.nBest, isEmpty);
    expect(r.offset, 0);
    expect(r.duration, 10000000);
  });
}
