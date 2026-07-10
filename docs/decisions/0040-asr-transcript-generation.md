# ADR-0040 — ASR Transcript Generation

- **Status**: Accepted
- **Date**: 2026-07-10
- **Feature**: `012-asr-transcript-generation`

## Context

The transcript feature currently supports four paths to populate a track
for a media item: sidecar `.srt` / `.vtt` import, embedded subtitle
extraction via FFmpeg, cloud fetch via `TranscriptApi`, and the YouTube
worker long-poll. There is no path for **local audio / video with no
existing transcript**: learners must find and import a subtitle file
themselves, which is impractical for podcasts, lectures, and personal
recordings.

User Story 1 (Generate a transcript when none exists) and User Story 2
(Re-generate at any time) require a speech-recognition path that:

1. Reuses the existing AI capability abstraction (`AsrCapability` /
   `AsrService`) so Azure Speech (default), OpenAI-compatible Whisper
   (BYOK), and the Enjoy worker Whisper path all work without new
   vendor wiring.
2. Persists the result as a first-class `source: 'ai'` track in the
   existing Drift `transcripts` table — every downstream consumer
   (highlight, lookup, echo, blur, auto-translate) already supports
   `ai`.
3. Re-uses FFmpeg (already wired through `ffmpeg_kit_flutter_new` and
   `FfmpegMediaProbe`) for video audio extraction.
4. Re-uses the language catalog (`app_language_catalog.dart`) and the
   `mapTranscriptLanguageToAzure` mapper for Azure BYOK.
5. Auto-selects the generated track as primary so the learner sees the
   transcript immediately.

## Decision

The implementation **does not add new vendor SDKs, HTTP paths, or
schema migrations**. Every component is a thin glue layer on top of
existing infrastructure:

| Need | Reused |
|---|---|
| ASR provider | `lib/features/ai/data/{enjoy,byok}_*_capability.dart` |
| Provider routing | `resolveAsrCapability` in `ai_capability_providers.dart` |
| Provider config | `AiModalityConfigs.asr` (Enjoy vs. BYOK) |
| Whisper / Azure call | `AsrService.transcribe(AsrRequest)` |
| Audio extraction | `FfmpegMediaProbe`, `ffmpeg_kit_flutter_new`, `azure_assessment_wav_normalizer` |
| Persistence | `TranscriptDao.upsert` with deterministic `enjoyTranscriptId(...source: 'ai')` |
| Language mapping | `mapTranscriptLanguageToAzure`, `app_language_catalog.dart` |
| UX | `TranscriptBusyButton`, `TranscriptBusyListTile`, `TranscriptEmptyState` |
| Logging | `logNamed('asr...')` |

A new feature folder `lib/features/asr/` hosts only the new
end-to-end glue:

- `domain/asr_timeline_builder.dart` — pure `AsrResult → TranscriptLine[]`.
- `data/asr_audio_extractor.dart` — `MediaKind`-aware audio extraction.
- `application/asr_generation_controller.dart` — `@riverpod` controller
  orchestrating the pipeline, with a per-`mediaId` in-flight guard and
  cancellation token (FR-015).

A new repository helper
`TranscriptRepository.upsertAsrGeneratedTrack(...)` is added to
`lib/features/transcript/data/transcript_repository.dart`; this is the
**only** modification to the transcript feature folder besides the
two widget-callback additions on `TranscriptEmptyState` and
`SubtitleActionsSection`.

## Consequences

- **Positive**: minimal surface area, no schema migration, no platform
  channel additions, every existing capability test continues to pass.
- **Positive**: SC-004 (deterministic upsert) is satisfied by
  construction — re-generation writes the same row id and Drift's
  `upsert` replaces in place.
- **Positive**: SC-005 (every downstream feature works on the new
  track) is satisfied by construction — the result is a `TranscriptRow`
  with `source = 'ai'`, the same shape every other path produces.
- **Trade-off**: the new controller does not yet support arbitrary
  ASR-side prompts beyond `AsrRequest.prompt`. Whisper hot-words are a
  follow-up if learner feedback demands it.
- **Trade-off**: long-form Azure continuous recognition (FR-006) is
  delegated to the Enjoy worker (matches the existing webapp routing
  at the 120 s threshold). The BYOK Azure path uses single-shot
  recognition; very long media on BYOK Azure will hit the
  short-form-only behavior. Documented in `research.md` § 9.
- **Reversibility**: low. Every component is additive; reverting means
  removing `lib/features/asr/`, the two widget-callback additions, and
  the `upsertAsrGeneratedTrack` helper. No data migration needed.

## Alternatives considered

1. **New REST path bypassing `AsrCapability`** — rejected: duplicates
   Azure / Whisper / OpenAI logic and breaks provider routing.
2. **New `ai_generated_transcripts` table** — rejected: fragments the
   `user | official | auto | ai` source priority and forces every
   `TranscriptTrack` consumer to special-case the new table.
3. **Native plugin instead of FFmpeg for audio extraction** — rejected:
   `media_kit` doesn't expose audio frames, and `ffmpeg_kit_flutter_new`
   plus bundled `ffmpeg.exe` already cover all four supported targets.
4. **Streaming recognition over multiple `transcribe` calls** — rejected
   for v1: the BYOK Azure SDK is single-shot; long-form is routed via
   the Enjoy worker. Splitting further is unjustified complexity.

## References

- Spec: `specs/012-asr-transcript-generation/spec.md`
- Plan: `specs/012-asr-transcript-generation/plan.md`
- Research: `specs/012-asr-transcript-generation/research.md`
- Tasks: `specs/012-asr-transcript-generation/tasks.md`