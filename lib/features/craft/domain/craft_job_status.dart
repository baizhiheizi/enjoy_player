/// Craft job status lifecycle.
library;

/// Where the Craft pipeline currently is.
enum CraftJobStatus {
  /// Initial state, no work in progress.
  idle,

  /// Checking eligibility (sign-in, text length, same-language, dedupe).
  validating,

  /// Translation stage (Translate then speak only).
  translating,

  /// TTS synthesis stage.
  synthesizing,

  /// Writing audio file + transcript rows to storage/DB.
  saving,

  /// All stages succeeded; media id is available.
  completed,

  /// A failure occurred; [CraftJobState.failure] is set.
  failed,
}
