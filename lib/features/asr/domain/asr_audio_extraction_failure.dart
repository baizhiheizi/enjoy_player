/// Failure surface for [AsrAudioExtractor].
///
/// Maps a single, machine-readable [AsrAudioExtractionFailureReason] to a
/// localized message key via [AsrFailureMessages]. The exception is the
/// only thing the extractor throws; the controller maps it to the
/// matching ARB key for the user-facing copy.
library;

enum AsrAudioExtractionFailureReason {
  /// `ffmpeg` was not found on the host (no bundled binary on Windows,
  /// no entry on PATH elsewhere).
  ffmpegUnavailable,

  /// The container has no audio stream to extract.
  noAudioTrack,

  /// `ffmpeg` exited with a non-zero status (decoder error, IO error, ...).
  ffmpegFailed,

  /// The source file is larger than the extractor's `maxBytes` cap.
  fileTooLarge,

  /// The source URI is not supported (e.g. non-file streaming).
  unsupportedSource,
}

class AsrAudioExtractionException implements Exception {
  AsrAudioExtractionException(this.reason, [this.message]);

  final AsrAudioExtractionFailureReason reason;
  final String? message;

  @override
  String toString() => message ?? reason.name;
}
