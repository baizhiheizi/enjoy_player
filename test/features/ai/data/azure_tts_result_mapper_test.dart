import 'dart:typed_data';

import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/features/ai/data/azure_tts_result_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps audio, format, and word boundaries from Azure outcome', () {
    final outcome = AzureSpeechSynthesisOutcome(
      audioBytes: Uint8List.fromList([1, 2, 3]),
      format: 'riff-24khz-16bit-mono-pcm',
      wordBoundaries: const [
        AzureWordBoundary(text: 'Hello', audioOffsetMs: 10, durationMs: 120),
        AzureWordBoundary(text: 'world', audioOffsetMs: 140, durationMs: 200),
      ],
    );

    final result = ttsResultFromAzureOutcome(outcome);

    expect(result.audioBytes, outcome.audioBytes);
    expect(result.format, 'riff-24khz-16bit-mono-pcm');
    expect(result.wordBoundaries, hasLength(2));
    expect(result.wordBoundaries[0].text, 'Hello');
    expect(result.wordBoundaries[0].audioOffsetMs, 10);
    expect(result.wordBoundaries[0].durationMs, 120);
    expect(result.wordBoundaries[1].text, 'world');
    expect(result.wordBoundaries[1].audioOffsetMs, 140);
    expect(result.wordBoundaries[1].durationMs, 200);
  });

  test('keeps SDK defaults for format and empty boundaries', () {
    final result = ttsResultFromAzureOutcome(
      AzureSpeechSynthesisOutcome(audioBytes: Uint8List(0)),
    );

    expect(result.format, 'wav');
    expect(result.wordBoundaries, isEmpty);
  });
}
