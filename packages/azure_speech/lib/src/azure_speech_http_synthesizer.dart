/// REST text-to-speech for Linux, where the vendored plugin ships no native
/// Speech SDK implementation.
///
/// One POST to the `cognitiveservices/v1` TTS endpoint per synthesis: SSML in,
/// WAV bytes out (`riff-16khz-16bit-mono-pcm`, the Speech SDK's default
/// output format, so downstream consumers see the same `wav` payload the
/// native path produces). Word boundaries are a WebSocket-SDK feature and
/// are not available here; [AzureSpeechSynthesisOutcome.wordBoundaries]
/// stays empty on this path.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'azure_speech_exception.dart';
import 'azure_speech_synthesis_outcome.dart';
import 'azure_speech_synthesis_params.dart';

/// Synthesizes speech over Azure's REST TTS endpoint.
final class AzureSpeechHttpSynthesizer {
  AzureSpeechHttpSynthesizer({
    HttpClient? client,
    Uri Function(String region)? endpointFor,
  }) : _client = client ?? HttpClient(),
       _endpointFor =
           endpointFor ??
           ((region) => Uri.parse(
             'https://$region.tts.speech.microsoft.com/cognitiveservices/v1',
           ));

  final HttpClient _client;
  final Uri Function(String region) _endpointFor;

  /// Same as the unconfigured Speech SDK default output format.
  static const _outputFormat = 'riff-16khz-16bit-mono-pcm';

  Future<AzureSpeechSynthesisOutcome> synthesize(
    AzureSpeechSynthesisParams params,
  ) async {
    final map = params.toMap();
    final voice = (map['voice'] as String?)?.trim();
    if (voice == null || voice.isEmpty) {
      throw const AzureSpeechException(
        code: 'missing_voice',
        message:
            'REST synthesis requires an explicit voice name; the native SDK '
            'defaults are not available on this path.',
      );
    }

    final request = await _client.postUrl(
      _endpointFor(map['region'] as String),
    );
    final token = map['token'] as String?;
    if (token != null && token.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    final key = map['subscriptionKey'] as String?;
    if (key != null && key.isNotEmpty) {
      request.headers.set('Ocp-Apim-Subscription-Key', key);
    }
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/ssml+xml');
    request.headers.set('X-Microsoft-OutputFormat', _outputFormat);
    request.headers.set('User-Agent', 'enjoy-player-azure-speech');
    request.write(
      _ssml(
        language: map['language'] as String,
        voice: voice,
        text: map['text'] as String,
      ),
    );

    final response = await request.close();
    final bytes = await response
        .fold(BytesBuilder(), (builder, chunk) => builder..add(chunk))
        .then((builder) => builder.takeBytes());
    if (response.statusCode != HttpStatus.ok) {
      throw AzureSpeechException(
        code: 'synthesize_http_${response.statusCode}',
        message:
            'Azure TTS returned ${response.statusCode}: '
            '${utf8.decode(bytes.take(200).toList(), allowMalformed: true)}',
      );
    }
    return AzureSpeechSynthesisOutcome(audioBytes: bytes);
  }

  String _ssml({
    required String language,
    required String voice,
    required String text,
  }) {
    return "<speak version='1.0' "
        "xmlns='http://www.w3.org/2001/10/synthesis' "
        "xml:lang='${_escape(language)}'>"
        "<voice name='${_escape(voice)}'>${_escape(text)}</voice></speak>";
  }

  String _escape(String raw) {
    return raw
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
