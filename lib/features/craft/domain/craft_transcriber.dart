/// Transcription port for the Craft Express flow.
///
/// Adapter wraps [AsrService.transcribe] so the controller stays testable
/// without a live AI capability stack.
library;

import 'dart:typed_data';

/// Abstract transcription interface consumed by [CraftController].
abstract interface class CraftTranscriber {
  /// Transcribes the given WAV audio bytes into text.
  ///
  /// [language] is an optional BCP-47 hint (e.g. `'zh'`, `'en'`).
  /// Returns the raw recognized text.
  Future<String> transcribe({required Uint8List audioBytes, String? language});
}
