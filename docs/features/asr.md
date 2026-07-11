# Feature: ASR transcript generation

Local audio and video can generate a time-aligned `source: ai` transcript from
the transcript empty state or the subtitle picker. The UI uses the existing
`AsrService` provider routing: Enjoy uses the worker, while BYOK routes to
Azure Speech or an OpenAI-compatible Whisper endpoint.

## Flow

`launchAsrGeneration` accepts only local library files. For video, it confirms
long media, extracts a temporary 16 kHz mono WAV through FFmpeg, then delegates
recognition to `AsrGenerationController`. Audio files are sent without an
extraction step. The controller includes the known media duration in the
`AsrRequest.durationSeconds` field; the Enjoy worker uses it to route short
audio to Whisper and longer audio to Azure Speech continuous recognition.
Whisper-compatible paths normalize the user-selected BCP-47 language tag
(e.g. `en-US`) to the base subtag (`en`) before sending it to the provider.
The controller converts the `AsrResult` through `buildAsrTranscriptLines`,
persists the result through `TranscriptRepository.upsertAsrGeneratedTrack`,
and makes it primary.

Re-generation uses the deterministic `enjoyTranscriptId` for
`(targetType, mediaId, language, source: ai)`, so it updates one row in place.
The previous track stays available until the replacement succeeds. If ASR
returns a detected language, both the generated track and the media row use it.

## Failure handling and performance

`AsrAudioExtractionException` carries one of `ffmpegUnavailable`,
`noAudioTrack`, `ffmpegFailed`, `fileTooLarge`, or `unsupportedSource`. The
presentation boundary maps those reasons, provider setup failures, credit
failures, network failures, and no-speech results to localized notices; raw
exceptions are not displayed.

Video extraction runs through FFmpegKit on mobile/macOS and an isolate-backed
`Process.run` on Windows. Temporary WAV files are deleted after bytes have been
read. The intended manual budget is 60 seconds for a five-minute desktop file,
without sustained UI jank.
