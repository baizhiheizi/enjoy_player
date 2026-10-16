import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_result.dart';

TtsResult ttsResultFromAzureOutcome(AzureSpeechSynthesisOutcome outcome) {
  return TtsResult(
    audioBytes: outcome.audioBytes,
    format: outcome.format,
    wordBoundaries: outcome.wordBoundaries
        .map(
          (w) => TtsWordBoundary(
            text: w.text,
            audioOffsetMs: w.audioOffsetMs,
            durationMs: w.durationMs,
          ),
        )
        .toList(),
  );
}
