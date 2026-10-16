import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_result.dart';

/// Domain [TtsResult] for a native Azure synthesis outcome; SDK defaults
/// (`wav` format, empty boundaries) pass through untouched.
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
