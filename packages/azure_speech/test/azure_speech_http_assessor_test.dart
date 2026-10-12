import 'dart:convert';
import 'dart:io';

import 'package:azure_speech/azure_speech.dart';
import 'package:azure_speech/src/azure_speech_http_assessor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _restResponse = {
  'RecognitionStatus': 'Success',
  'Offset': 100000,
  'Duration': 9000000,
  'DisplayText': 'Hello world.',
  'NBest': [
    {
      'Confidence': 0.9,
      'Lexical': 'hello world',
      'ITN': 'hello world',
      'MaskedITN': 'hello world',
      'Display': 'Hello world.',
      'AccuracyScore': 88.0,
      'FluencyScore': 91.0,
      'CompletenessScore': 100.0,
      'PronScore': 90.5,
      'ProsodyScore': 76.0,
      'Words': [
        {
          'Word': 'hello',
          'Offset': 100000,
          'Duration': 4000000,
          'AccuracyScore': 95.0,
          'ErrorType': 'None',
          'Phonemes': [
            {'Phoneme': 'h', 'AccuracyScore': 97.0},
          ],
        },
        {
          'Word': 'world',
          'Offset': 5000000,
          'Duration': 4000000,
          'AccuracyScore': 58.0,
          'ErrorType': 'Mispronunciation',
        },
      ],
    },
  ],
};

void main() {
  late HttpServer server;
  late Directory dir;
  late File wav;
  late List<HttpHeaders> headers;
  late List<Uri> uris;
  late List<int> bodyLengths;
  late int status;

  setUp(() async {
    headers = [];
    uris = [];
    bodyLengths = [];
    status = HttpStatus.ok;
    dir = await Directory.systemTemp.createTemp('assess_test');
    wav = File('${dir.path}/take.wav')..writeAsBytesSync(List.filled(64, 1));
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = await request.fold<List<int>>(
        [],
        (acc, chunk) => acc..addAll(chunk),
      );
      headers.add(request.headers);
      uris.add(request.uri);
      bodyLengths.add(body.length);
      request.response.statusCode = status;
      request.response.write(
        status == HttpStatus.ok ? jsonEncode(_restResponse) : 'bad token',
      );
      await request.response.close();
    });
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await server.close(force: true);
    await dir.delete(recursive: true);
  });

  AzureSpeechHttpAssessor assessor() => AzureSpeechHttpAssessor(
    endpointFor: (region, language) => Uri.http(
      '127.0.0.1:${server.port}',
      '/stt/$region',
      {'language': language, 'format': 'detailed'},
    ),
  );

  AzurePronunciationAssessmentParams params() =>
      AzurePronunciationAssessmentParams(
        audioPath: wav.path,
        referenceText: 'Hello world',
        language: 'en-US',
        token: 'tok-1',
        region: 'eastus',
      );

  test('posts the WAV with the assessment config header', () async {
    await assessor().assess(params());

    final h = headers.single;
    expect(uris.single.path, '/stt/eastus');
    expect(uris.single.queryParameters['language'], 'en-US');
    expect(uris.single.queryParameters['format'], 'detailed');
    expect(h.value(HttpHeaders.authorizationHeader), 'Bearer tok-1');
    expect(h.value(HttpHeaders.contentTypeHeader), contains('audio/wav'));
    expect(bodyLengths.single, 64);
    final config =
        jsonDecode(
              utf8.decode(base64Decode(h.value('Pronunciation-Assessment')!)),
            )
            as Map<String, dynamic>;
    expect(config['ReferenceText'], 'Hello world');
    expect(config['Granularity'], 'Phoneme');
    expect(config['EnableProsodyAssessment'], 'True');
    expect(config['EnableMiscue'], 'True');
  });

  test('re-nests flat REST scores into the SDK shape', () async {
    final outcome = await assessor().assess(params());

    final nBest = outcome.detail.nBest.single;
    expect(nBest.pronunciationAssessment.pronScore, 90.5);
    expect(nBest.pronunciationAssessment.prosodyScore, 76.0);
    expect(
      nBest.words[1].pronunciationAssessment.errorType,
      'Mispronunciation',
    );
    expect(nBest.words[1].pronunciationAssessment.accuracyScore, 58.0);
    expect(
      nBest.words[0].phonemes!.single.pronunciationAssessment.accuracyScore,
      97.0,
    );
    final rawNBest = (outcome.rawJson['NBest'] as List).single as Map;
    expect(rawNBest['PronunciationAssessment'], isA<Map>());
    expect(rawNBest.containsKey('AccuracyScore'), isFalse);
  });

  test('HTTP errors surface as AzureSpeechException', () async {
    status = HttpStatus.unauthorized;
    await expectLater(
      assessor().assess(params()),
      throwsA(
        isA<AzureSpeechException>().having(
          (e) => e.code,
          'code',
          'assess_http_401',
        ),
      ),
    );
  });

  test('AzureSpeech.assess uses REST on Linux', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final outcome = await AzureSpeech(
      assessEndpoint: (region, language) =>
          Uri.http('127.0.0.1:${server.port}', '/stt/$region'),
    ).assess(params());
    expect(outcome.detail.nBest.single.words, hasLength(2));
  });
}
