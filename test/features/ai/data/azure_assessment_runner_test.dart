import 'dart:convert';
import 'dart:io';

import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/features/ai/data/azure_assessment_runner.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('azure_speech_assessment_runner_test');
  final invoked = <MethodCall>[];
  Future<Object?> Function(MethodCall call)? handler;

  setUp(() {
    invoked.clear();
    handler = null;
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          invoked.add(call);
          final h = handler;
          if (h == null) return null;
          return h(call);
        });
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<Directory> tempDir() async {
    final dir = await Directory.systemTemp.createTemp('azure_runner_test_');
    addTearDown(() => dir.delete(recursive: true));
    return dir;
  }

  Future<String> writeGarbageWav(Directory dir) async {
    final file = File('${dir.path}/recording.wav');
    await file.writeAsBytes(
      Uint8List.fromList(utf8.encode('definitely not a riff header')),
    );
    return file.path;
  }

  Map<String, dynamic> scoresJson({
    double pron = 82,
    double accuracy = 80,
    double fluency = 84,
    double completeness = 90,
  }) => {
    'AccuracyScore': accuracy,
    'FluencyScore': fluency,
    'CompletenessScore': completeness,
    'PronScore': pron,
  };

  Map<String, dynamic> wordJson({String errorType = 'None'}) => {
    'Word': 'hello',
    'Offset': 0,
    'Duration': 3000000,
    'PronunciationAssessment': {'AccuracyScore': 70.0, 'ErrorType': errorType},
  };

  Map<String, dynamic> outcomeJson({
    String displayText = 'Good morning world.',
    List<Map<String, dynamic>> words = const [],
    double pron = 82,
  }) => {
    'RecognitionStatus': 'Success',
    'Offset': 0,
    'Duration': 12000000,
    'DisplayText': displayText,
    'NBest': [
      {
        'Confidence': 0.9,
        'Lexical': 'Good morning world.',
        'ITN': 'Good morning world.',
        'MaskedITN': 'Good morning world.',
        'Display': displayText,
        'PronunciationAssessment': scoresJson(pron: pron),
        'Words': words,
      },
    ],
  };

  AzureSpeechAssessmentOutcome outcomeFrom(Map<String, dynamic> json) =>
      AzureSpeechAssessmentOutcome(
        detail: AzurePronunciationAssessmentResult.fromJson(json),
        rawJson: json,
      );

  group('cleanAssessmentReferenceText', () {
    test('collapses whitespace runs and trims', () {
      expect(
        cleanAssessmentReferenceText('  good \t morning\n world  '),
        'good morning world',
      );
    });
  });

  group('estimateAssessmentDurationSeconds', () {
    test('ceil of durationMs', () {
      expect(
        estimateAssessmentDurationSeconds(
          AssessmentRequest(
            audioBytes: Uint8List.fromList([1]),
            referenceText: 'a',
            language: 'en',
            durationMs: 1500,
          ),
        ),
        2,
      );
    });

    test('durationMs clamps to [1, 300]', () {
      final tiny = AssessmentRequest(
        audioBytes: Uint8List.fromList([1]),
        referenceText: 'a',
        language: 'en',
        durationMs: 1,
      );
      final huge = AssessmentRequest(
        audioBytes: Uint8List.fromList([1]),
        referenceText: 'a',
        language: 'en',
        durationMs: 999999999,
      );
      expect(estimateAssessmentDurationSeconds(tiny), 1);
      expect(estimateAssessmentDurationSeconds(huge), 300);
    });

    test('bytes path divides by 32000', () {
      final request = AssessmentRequest(
        audioBytes: Uint8List(64000),
        referenceText: 'a',
        language: 'en',
      );
      expect(estimateAssessmentDurationSeconds(request), 2);
    });

    test('file length path divides by 32000', () async {
      final dir = await tempDir();
      final file = File('${dir.path}/clip.wav');
      await file.writeAsBytes(Uint8List(96000));
      final request = AssessmentRequest(
        audioPath: file.path,
        referenceText: 'a',
        language: 'en',
      );
      expect(estimateAssessmentDurationSeconds(request), 3);
    });

    test('unreadable file falls back to 15', () async {
      final request = AssessmentRequest(
        audioPath:
            '/tmp/__definitely_missing_${DateTime.now().microsecondsSinceEpoch}.wav',
        referenceText: 'a',
        language: 'en',
      );
      expect(estimateAssessmentDurationSeconds(request), 15);
    });
  });

  group('looksLikeEmptyAzureAssessment', () {
    test('empty NBest looks empty', () {
      final json = outcomeJson();
      json['NBest'] = <Map<String, dynamic>>[];
      expect(looksLikeEmptyAzureAssessment(outcomeFrom(json)), isTrue);
    });

    test('all-zero scores with lone period display looks empty', () {
      final json = outcomeJson(displayText: '.', pron: 0);
      (json['NBest'][0]['PronunciationAssessment'] as Map<String, dynamic>)
          .addAll({
            'AccuracyScore': 0.0,
            'FluencyScore': 0.0,
            'CompletenessScore': 0.0,
          });
      expect(looksLikeEmptyAzureAssessment(outcomeFrom(json)), isTrue);
    });

    test('all-zero scores with every word omitted looks empty', () {
      final json = outcomeJson(
        displayText: 'Good.',
        pron: 0,
        words: [wordJson(errorType: 'Omission')],
      );
      (json['NBest'][0]['PronunciationAssessment'] as Map<String, dynamic>)
          .addAll({
            'AccuracyScore': 0.0,
            'FluencyScore': 0.0,
            'CompletenessScore': 0.0,
          });
      expect(looksLikeEmptyAzureAssessment(outcomeFrom(json)), isTrue);
    });

    test('all-zero scores with a recognized word does not look empty', () {
      final json = outcomeJson(
        displayText: 'Hello.',
        pron: 0,
        words: [wordJson(errorType: 'None')],
      );
      (json['NBest'][0]['PronunciationAssessment'] as Map<String, dynamic>)
          .addAll({
            'AccuracyScore': 0.0,
            'FluencyScore': 0.0,
            'CompletenessScore': 0.0,
          });
      expect(looksLikeEmptyAzureAssessment(outcomeFrom(json)), isFalse);
    });

    test('nonzero pron score does not look empty', () {
      final json = outcomeJson(pron: 50);
      expect(looksLikeEmptyAzureAssessment(outcomeFrom(json)), isFalse);
    });
  });

  group('materializeAssessmentWav', () {
    test('existing audioPath is used in place', () async {
      final dir = await tempDir();
      final file = File('${dir.path}/rec.wav');
      await file.writeAsBytes(Uint8List.fromList([1, 2, 3]));
      final request = AssessmentRequest(
        audioPath: file.path,
        referenceText: 'a',
        language: 'en',
      );
      final (path, deleteAfter) = await materializeAssessmentWav(request);
      expect(deleteAfter, isFalse);
      expect(path, File(file.path).absolute.path);
    });

    test('missing audioPath throws StateError', () async {
      final request = AssessmentRequest(
        audioPath:
            '/tmp/__definitely_missing_${DateTime.now().microsecondsSinceEpoch}.wav',
        referenceText: 'a',
        language: 'en',
      );
      await expectLater(
        materializeAssessmentWav(request),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Recording file not found'),
          ),
        ),
      );
    });

    test('audioBytes are written to a temp wav marked for deletion', () async {
      final bytes = Uint8List.fromList(utf8.encode('bytes wav'));
      final request = AssessmentRequest(
        audioBytes: bytes,
        referenceText: 'a',
        language: 'en',
      );
      final (path, deleteAfter) = await materializeAssessmentWav(request);
      expect(deleteAfter, isTrue);
      expect(File(path).readAsBytesSync(), bytes);
      expect(File(path).existsSync(), isTrue);
      addTearDown(() {
        if (File(path).existsSync()) File(path).deleteSync();
      });
    });
  });

  group('runAzurePronunciationAssessment', () {
    test('assesses the original recording and maps the outcome', () async {
      final dir = await tempDir();
      final sourcePath = await writeGarbageWav(dir);
      final sourceBytes = await File(sourcePath).readAsBytes();
      final json = outcomeJson();
      Uint8List? assessedBytes;
      handler = (call) async {
        final callArgs = Map<String, dynamic>.from(call.arguments as Map);
        assessedBytes = File(callArgs['audioPath'] as String).readAsBytesSync();
        return jsonEncode(json);
      };

      final result = await runAzurePronunciationAssessment(
        request: AssessmentRequest(
          audioPath: sourcePath,
          referenceText: '  good \t morning\n world  ',
          language: 'en',
          durationMs: 4000,
        ),
        sdk: AzureSpeech(channel: channel),
        region: 'westus2',
        token: 'token-1',
      );

      expect(invoked, hasLength(1));
      expect(invoked.single.method, 'assess');
      final args = Map<String, dynamic>.from(invoked.single.arguments as Map);
      expect(args['audioPath'], isNotEmpty);
      expect(args['referenceText'], 'good morning world');
      expect(args['language'], 'en-US');
      expect(args['region'], 'westus2');
      expect(args['token'], 'token-1');
      expect(args.containsKey('subscriptionKey'), isFalse);

      expect(assessedBytes, sourceBytes);
      expect(result.detail.primaryScores!.pronScore, 82);
      expect(result.rawJson['RecognitionStatus'], 'Success');
      expect(File(sourcePath).existsSync(), isTrue);
    });

    test('throws StateError for an unsupported language', () async {
      final dir = await tempDir();
      final sourcePath = await writeGarbageWav(dir);
      handler = (_) async => jsonEncode(outcomeJson());

      await expectLater(
        runAzurePronunciationAssessment(
          request: AssessmentRequest(
            audioPath: sourcePath,
            referenceText: 'a',
            language: 'xx',
          ),
          sdk: AzureSpeech(channel: channel),
          region: 'westus2',
          token: 'token-1',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not supported'),
          ),
        ),
      );
      expect(invoked, isEmpty);
    });

    test('throws StateError when the recording file is missing', () async {
      handler = (_) async => jsonEncode(outcomeJson());

      await expectLater(
        runAzurePronunciationAssessment(
          request: AssessmentRequest(
            audioPath:
                '/tmp/__definitely_missing_${DateTime.now().microsecondsSinceEpoch}.wav',
            referenceText: 'a',
            language: 'en',
          ),
          sdk: AzureSpeech(channel: channel),
          region: 'westus2',
          token: 'token-1',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Recording file not found'),
          ),
        ),
      );
      expect(invoked, isEmpty);
    });

    test('requires exactly one of token or subscriptionKey', () async {
      final dir = await tempDir();
      final sourcePath = await writeGarbageWav(dir);
      final base = {
        'request': AssessmentRequest(
          audioPath: sourcePath,
          referenceText: 'a',
          language: 'en',
        ),
        'sdk': AzureSpeech(channel: channel),
        'region': 'westus2',
      };

      await expectLater(
        runAzurePronunciationAssessment(
          request: base['request'] as AssessmentRequest,
          sdk: base['sdk'] as AzureSpeech,
          region: 'westus2',
          token: 'token-1',
          subscriptionKey: 'key-1',
        ),
        throwsA(isA<AssertionError>()),
      );
      await expectLater(
        runAzurePronunciationAssessment(
          request: base['request'] as AssessmentRequest,
          sdk: base['sdk'] as AzureSpeech,
          region: 'westus2',
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(invoked, isEmpty);
    });

    test('propagates AzureSpeechException from a PlatformException', () async {
      final dir = await tempDir();
      final sourcePath = await writeGarbageWav(dir);
      handler = (_) async =>
          throw PlatformException(code: 'spx_error', message: 'native failure');

      await expectLater(
        runAzurePronunciationAssessment(
          request: AssessmentRequest(
            audioPath: sourcePath,
            referenceText: 'a',
            language: 'en',
          ),
          sdk: AzureSpeech(channel: channel),
          region: 'westus2',
          token: 'token-1',
        ),
        throwsA(
          isA<AzureSpeechException>()
              .having((e) => e.code, 'code', 'spx_error')
              .having((e) => e.message, 'message', 'native failure'),
        ),
      );
    });

    test('blank native result raises the empty_result exception', () async {
      final dir = await tempDir();
      final sourcePath = await writeGarbageWav(dir);
      handler = (_) async => '';

      await expectLater(
        runAzurePronunciationAssessment(
          request: AssessmentRequest(
            audioPath: sourcePath,
            referenceText: 'a',
            language: 'en',
          ),
          sdk: AzureSpeech(channel: channel),
          region: 'westus2',
          token: 'token-1',
        ),
        throwsA(
          isA<AzureSpeechException>().having(
            (e) => e.code,
            'code',
            'empty_result',
          ),
        ),
      );
    });

    test(
      'materialized audioBytes temp file is deleted after the run',
      () async {
        final json = outcomeJson();
        handler = (_) async => jsonEncode(json);

        final result = await runAzurePronunciationAssessment(
          request: AssessmentRequest(
            audioBytes: Uint8List.fromList(
              utf8.encode('definitely not a riff'),
            ),
            referenceText: 'a',
            language: 'en',
            durationMs: 4000,
          ),
          sdk: AzureSpeech(channel: channel),
          region: 'westus2',
          subscriptionKey: 'key-1',
        );

        expect(result.detail.primaryScores!.pronScore, 82);
        final args = Map<String, dynamic>.from(invoked.single.arguments as Map);
        final stagedPath = args['audioPath'] as String;
        expect(File(stagedPath).existsSync(), isFalse);
        expect(args['subscriptionKey'], 'key-1');
        expect(args.containsKey('token'), isFalse);
      },
    );
  });
}
