import 'dart:convert';
import 'dart:io';

import 'package:azure_speech/src/azure_speech_exception.dart';
import 'package:azure_speech/src/azure_speech_http_synthesizer.dart';
import 'package:azure_speech/src/azure_speech_synthesis_outcome.dart';
import 'package:azure_speech/src/azure_speech_synthesis_params.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturedCall {
  _CapturedCall(this.uri, this.headers, this.body);

  final Uri uri;
  final HttpHeaders headers;
  final String body;
}

void main() {
  late HttpServer server;
  late List<_CapturedCall> calls;
  late List<int> responseBody;
  int responseStatus;

  Future<(AzureSpeechSynthesisOutcome, _CapturedCall)> synthesizeOnce({
    String? voice = 'en-US-GuyNeural',
    String? token = 'tok-1',
    String? subscriptionKey,
  }) async {
    final synthesizer = AzureSpeechHttpSynthesizer(
      endpointFor: (_) =>
          Uri.http('127.0.0.1:${server.port}', '/cognitiveservices/v1'),
    );
    final outcome = await synthesizer.synthesize(
      AzureSpeechSynthesisParams(
        text: 'Hello <world> & "friends"',
        language: 'en-US',
        token: token,
        subscriptionKey: subscriptionKey,
        region: 'eastus',
        voice: voice,
      ),
    );
    return (outcome, calls.single);
  }

  setUp(() async {
    calls = [];
    responseBody = [1, 2, 3, 4];
    responseStatus = HttpStatus.ok;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      calls.add(_CapturedCall(request.uri, request.headers, body));
      request.response.statusCode = responseStatus;
      request.response.add(responseBody);
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('posts SSML with bearer auth and returns the audio bytes', () async {
    final (outcome, call) = await synthesizeOnce();

    expect(outcome.audioBytes, responseBody);
    expect(outcome.format, 'wav');
    expect(outcome.wordBoundaries, isEmpty);
    expect(call.uri.path, '/cognitiveservices/v1');
    expect(call.headers.value('authorization'), 'Bearer tok-1');
    expect(call.headers.value('content-type'), 'application/ssml+xml');
    expect(
      call.headers.value('x-microsoft-outputformat'),
      'riff-16khz-16bit-mono-pcm',
    );
    expect(
      call.body,
      "<speak version='1.0' "
      "xmlns='http://www.w3.org/2001/10/synthesis' "
      "xml:lang='en-US'>"
      "<voice name='en-US-GuyNeural'>"
      'Hello &lt;world&gt; &amp; &quot;friends&quot;'
      '</voice></speak>',
    );
  });

  test('subscription key auth lands in the APIM header', () async {
    final (_, call) = await synthesizeOnce(
      token: null,
      subscriptionKey: 'key-9',
    );

    expect(call.headers.value('ocp-apim-subscription-key'), 'key-9');
    expect(call.headers.value('authorization'), isNull);
  });

  test(
    'non-200 responses become AzureSpeechException with the status code',
    () async {
      responseStatus = HttpStatus.unauthorized;
      responseBody = utf8.encode('bad token');

      await expectLater(
        synthesizeOnce(),
        throwsA(
          isA<AzureSpeechException>().having(
            (e) => e.code,
            'code',
            'synthesize_http_401',
          ),
        ),
      );
    },
  );

  test('REST synthesis requires an explicit voice', () {
    expect(
      () => synthesizeOnce(voice: null),
      throwsA(
        isA<AzureSpeechException>().having(
          (e) => e.code,
          'code',
          'missing_voice',
        ),
      ),
    );
  });
}
