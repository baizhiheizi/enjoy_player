import 'dart:io';

import 'package:azure_speech/azure_speech.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late List<String> hits;

  setUp(() async {
    hits = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await request.drain<void>();
      hits.add('${request.method} ${request.uri.path}');
      request.response.statusCode = HttpStatus.ok;
      request.response.add([7, 8, 9]);
      await request.response.close();
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await server.close(force: true);
  });

  AzureSpeech linuxSpeech() => AzureSpeech(
    synthesizeEndpoint: (_) =>
        Uri.http('127.0.0.1:${server.port}', '/cognitiveservices/v1'),
  );

  test(
    'synthesize goes over REST instead of the missing native channel',
    () async {
      final outcome = await linuxSpeech().synthesize(
        const AzureSpeechSynthesisParams(
          text: 'Hello there',
          language: 'en-US',
          token: 'tok',
          region: 'eastus',
          voice: 'en-US-GuyNeural',
        ),
      );

      expect(outcome.audioBytes, [7, 8, 9]);
      expect(outcome.wordBoundaries, isEmpty);
      expect(hits, ['POST /cognitiveservices/v1']);
    },
  );

  test(
    'assess reports an unsupported platform instead of a missing channel',
    () async {
      await expectLater(
        linuxSpeech().assess(
          const AzurePronunciationAssessmentParams(
            audioPath: '/tmp/x.wav',
            referenceText: 'hello',
            language: 'en-US',
            token: 'tok',
            region: 'eastus',
          ),
        ),
        throwsA(
          isA<AzureSpeechException>().having(
            (e) => e.code,
            'code',
            'unsupported_platform',
          ),
        ),
      );
    },
  );

  test(
    'transcribe reports an unsupported platform instead of a missing channel',
    () async {
      await expectLater(
        linuxSpeech().transcribe(
          const AzureSpeechTranscriptionParams(
            audioPath: '/tmp/x.wav',
            language: 'en-US',
            subscriptionKey: 'key',
            region: 'eastus',
          ),
        ),
        throwsA(
          isA<AzureSpeechException>().having(
            (e) => e.code,
            'code',
            'unsupported_platform',
          ),
        ),
      );
    },
  );
}
