/// Shared thresholds and poll backoff for Enjoy long-form ASR.
library;

/// Worker long-form gate: clips at or above this duration use Deepgram jobs.
const int kLongFormMinDurationSeconds = 900;

/// Suggested initial poll interval (worker client guidance).
const Duration kLongFormPollInitialDelay = Duration(seconds: 2);

/// Maximum poll interval.
const Duration kLongFormPollMaxDelay = Duration(seconds: 30);

/// Default Content-Type for extracted WAV recognition audio.
const String kLongFormDefaultAudioContentType = 'audio/wav';
