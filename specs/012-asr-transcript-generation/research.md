# Research — ASR Transcript Generation

**Branch**: `012-asr-transcript-generation` | **Date**: 2026-07-10
**Status**: Phase 0 (research) complete; all NEAR-CLARIFICATIONS resolved against
existing codebase. **No NEEDS CLARIFICATION remain.**

This research note is the input to Phase 1 design. It maps every dependency
the feature will rely on, identifies reuse opportunities (high), and flags
gaps where new code is needed (low).

---

## 1. Decision: Reuse existing `AsrCapability` / `AsrService`

The ASR plumbing is already in place behind `lib/features/ai/`:

- `lib/features/ai/domain/capabilities/asr_capability.dart` — abstract
  `AsrCapability.transcribe(AsrRequest) → Future<AsrResult>`.
- `lib/features/ai/data/enjoy/enjoy_asr_capability.dart` — `EnjoyAsrCapability`
  delegates to `AsrApi` (`POST /audio/transcriptions` on the Enjoy worker).
- `lib/features/ai/data/byok/byok_asr_azure_capability.dart` — native Azure
  Speech (`AzureSpeech.instance.transcribe`) with subscription key + region;
  uses `azure_speech` path package; re-uses
  `tryCreateNormalizedAzureAssessmentWav` for Azure-preferred 16 kHz mono WAV.
- `lib/features/ai/data/byok/byok_asr_openai_capability.dart` — BYOK OpenAI-
  compatible Whisper via `postWhisperTranscription` (multipart).
- `lib/features/ai/application/ai_services.dart` — `AsrService` wraps the
  capability via `guardAiCall`; `asrServiceProvider` (Riverpod keepAlive).
- `lib/features/ai/application/ai_capability_providers.dart` —
  `resolveAsrCapability` switches on `AIProvider.enjoy | byok | local`, and
  on `SpeechByokKind.openAiCompatible | azureSpeech` for the BYOK branch.
- `lib/features/ai/domain/models/asr_request.dart` — `AsrRequest` value
  object (`audioBytes`, `filename`, `mimeType?`, `model?`, `language?`,
  `prompt?`, `responseFormat`, `durationSeconds?`).
- `lib/features/ai/domain/models/asr_result.dart` — `AsrResult` with
  `text`, `segments?`, `language?`, `duration?`, `wordCount?`; nested
  `AsrSegment { start, end, text, words? }` and `AsrWord { word, start, end }`.

**Rationale**: the spec mandates reuse of the existing abstraction
(QR-001). All three provider paths already exist; the new feature only
needs the **end-to-end glue**: feed audio in, get back a `source: ai`
transcript row, surface progress / errors in the transcript panel and the
subtitle picker.

**Alternatives considered**:
- A new REST path bypassing the existing capabilities — rejected: would
  duplicate Azure / Whisper / OpenAI logic and break provider routing.
- Direct Azure token / Whisper HTTP in feature code — rejected: violates
  QR-001 (no vendor HTTP outside `lib/features/ai/data`).

## 2. Decision: Reuse transcript persistence path

`lib/features/transcript/data/transcript_repository.dart` already supports
`source: 'ai'` upsert via two existing flows:

- `_upsertYoutubeWorkerReadyTranscript` (line 646-687) — canonical example
  of writing a `TranscriptRow` with deterministic `enjoyTranscriptId(...)`,
  encoded timeline JSON, and `ensurePrimaryTranscript` follow-up.
- `ensureAutoTranslateTrack` (line 916-965) — creates a `source: 'ai'`
  skeleton track for auto-translate; same row shape we will reuse for ASR.

Both use `enjoyTranscriptId(targetType, targetId, language, source: 'ai')`
so the row id is deterministic — re-generation will upsert in place
(FR-010 / SC-004) without changing the active session.

**Rationale**: SC-004 requires re-generation produces *exactly one* `ai`
track. Deterministic id + Drift `upsert` gives that for free.

**Alternatives considered**:
- A new table (`ai_generated_transcripts`) — rejected: would fragment the
  source priority and break `TranscriptTrack` consumers (`user | official |
  auto | ai`).
- Storing ASR raw output separately and materializing on demand — rejected:
  introduces a hot path for every transcript line render with no clear win.

## 3. Decision: Reuse FFmpeg audio extraction

`lib/data/files/ffmpeg_media_probe.dart` and
`lib/features/ai/data/azure_assessment_wav_normalizer.dart` already provide:

- `FfmpegMediaProbe.resolveFfmpegExecutable()` — bundled `ffmpeg.exe` on
  Windows, `ffmpeg` on PATH elsewhere (FR-004).
- `FfmpegMediaProbe.mediaInputForFfmpeg(uri)` — file:// → local path.
- `FfmpegMediaProbe.parseDurationSeconds(stderr)` — duration probe.
- `tryCreateNormalizedAzureAssessmentWav(wavPath)` — 16 kHz mono 16-bit
  PCM (Azure-preferred). Used by `ByokAsrAzureCapability` already.

We will add a thin `lib/features/asr/data/asr_audio_extractor.dart` that
extracts the audio track from a video file into a temp WAV using the
existing `ffmpeg_kit_flutter_new` on mobile/macOS and `Process.run` on
Windows. For audio-only files, we skip extraction (FR-003) and read the
file bytes directly. The output bytes feed straight into `AsrRequest`.

**Rationale**: FR-003, FR-004, SC-008 require audio extraction across all
four supported platforms. FFmpeg is already wired through the repo.

**Alternatives considered**:
- A native MediaExtractor plugin — rejected: platform surface is already
  covered by `ffmpeg_kit_flutter_new` (Android/iOS/macOS) + bundled
  `ffmpeg.exe` (Windows); adding a second audio extraction path is unjustified.
- Streaming media_kit's audio — rejected: `media_kit` exposes video, not
  audio frames.

## 4. Decision: Reuse language catalog / mapper

`lib/core/application/app_language_catalog.dart` is the single source of
truth for supported BCP47 tags and Azure pronunciation-assessment locales.
For ASR:

- Whisper (Enjoy + BYOK OpenAI) accepts any BCP47 base tag — pass
  `request.language` directly.
- Azure Speech (BYOK) — `mapTranscriptLanguageToAzure` already handles
  language→locale mapping for the recognition call.
- Auto-detect: Enjoy worker already returns `transcriptionInfo.language`
  in `AsrResult.fromJson`; we will surface this as the resulting track
  language (FR-012).

**Rationale**: there is exactly one place to register new supported
languages (the catalog), and Azure / Whisper mapping is already wired.

## 5. Decision: Progress and cancel UX

`lib/features/transcript/presentation/transcript_busy_action.dart` defines
`TranscriptBusyButton` and `TranscriptBusyListTile` — the existing pattern
for inline-busy CTA on the empty state and the subtitle picker.

For ASR, we will:

- Reuse `TranscriptBusyButton` for the empty-state CTA
  (calm, non-blocking; FR-013 / QR-007).
- Reuse `TranscriptBusyListTile` for the picker's "Generate / Re-generate
  transcript" row.
- Add a Riverpod controller (`AsrGenerationController`) that exposes
  `state ∈ {idle, extracting, recognizing, persisting, success, error}`
  with a single in-flight guard per media id (FR-014 / FR-015).
- For long media (≥ 30 min, FR-008), the dialog will warn about duration /
  credits and require confirmation before kicking off.

**Rationale**: QR-003 / QR-007 require the same calm, non-blocking
patterns as transcript fetch and auto-translate.

## 6. Decision: Deterministic re-generation semantics

Re-generation for the same `(mediaId, language)` writes to the same row id
(`enjoyTranscriptId(...source: 'ai')`). During the in-flight pass, the
previous `source: ai` track (if any) stays visible (FR / US2.3); the new
result replaces it in place on success. If a new run is started while one
is in-flight, the controller cancels the prior run cleanly (FR-015) and
the new run starts against a clean future — no overlapping writes.

## 7. Decision: Auto-detected language propagation

When ASR returns `AsrResult.language` and it differs from the media
record's stored language, the new controller will:

1. Save the track with the detected language (FR-011 / FR-012).
2. Update the media row's `language` field via the existing media DAO so
   subsequent cloud fetches, auto-translate target selection, and lookup
   use the correct language (US6.3).

This mirrors how `fetchCloudTranscripts` updates the language when a
worker returns a more accurate hint.

## 8. Decision: Audio extraction failure / no-audio UX

When the source file has no audio track (FR-US5.2) or FFmpeg is missing,
the Generate CTA stays visible but disables itself with a tooltip that
explains the reason (matches the existing `transcriptEmptyExtract`
disable behavior when `onExtract` is null). The same wording is reused
across the empty state and the picker.

## 9. Open questions and resolution

| Open question | Resolution |
|---|---|
| Webapp reference (`~/dev/enjoy/apps/web`) | Not present on this machine — **NEEDS CLARIFICATION** is not required because the implementation pattern is already documented in the spec (Azure Speech long-form threshold 120s, segmentation by pauses/punctuation, deterministic id upsert) and matches the Flutter codebase conventions. If a future iteration needs deeper parity with the webapp, an additional discovery pass is documented but not blocking. |
| Long-form Azure continuous recognition SDK | The native `azure_speech` plugin currently exposes a single-shot `transcribe(...)`; long-form routing is **handled server-side by the Enjoy worker** (FR-006 / spec assumption #2). BYOK Azure path keeps single-shot with the same WAV normalization; **no client SDK upgrade is required** to ship the feature. |
| Auto-detect handling for BYOK Azure | Azure BYOK path does not return a detected language from `AzureSpeechTranscriptionOutcome`; we will pass the user's chosen language (default = media's stored language) and **not** rewrite media language on the Azure BYOK path. |
| Auto-translate interaction | An ASR `ai` track will become the **primary** transcript after save (FR-021). Auto-translate's existing skeleton (`ensureAutoTranslateTrack`) will rebuild against the new primary in the next auto-translate tick — no special case needed. |

## 10. Test plan (mirrors Constitution Principle II)

Required automated tests (in `test/features/asr/` and existing `transcript/`):

- `asr_audio_extractor_test.dart` — happy path (audio-only skip), video
  audio extract, missing FFmpeg path, no-audio-track error.
- `asr_timeline_segmentation_test.dart` — word-level timings → grouped
  `TranscriptLine` list, plain-text fallback (duration-distributed),
  empty-result graceful handling.
- `asr_generation_controller_test.dart` — state machine:
  extracting → recognizing → persisting → success; in-flight guard;
  cancel-on-restart; deterministic upsert (re-generation produces 1 row).
- `asr_language_propagation_test.dart` — auto-detected language overrides
  media row language; same-language no-op.
- `transcript_repository_generate_asr_test.dart` — repository helper
  `upsertAsrGeneratedTrack(mediaId, language, lines, label)` writes one
  `source: ai` row and updates primary.
- `transcript_empty_state_generate_action_test.dart` (widget) — empty
  state shows Generate CTA when local file is eligible; hidden when not.
- `subtitle_track_picker_generate_action_test.dart` (widget) — picker
  shows Generate / Re-generate row, busy spinner while in-flight,
  replaces `ai` track in place.
- Update existing `transcript_repository_test.dart` — re-run with the
  new ASR helper present (no breakage).

`dart run build_runner build` is required when adding Riverpod
generators for the new controller / providers (Constitution Principle
II / Flutter Quality Gates).

## 11. Verification commands

Per the Constitution's Flutter Quality Gates section, every implementation
PR must run:

- `bash .github/scripts/validate_ci_gates.sh` — format + codegen drift
- `dart run build_runner build` — generated providers / Drift
- `flutter analyze` — lint
- `flutter test test/features/asr test/features/transcript` — new and
  affected suites
- Manual / `integration_test/` smoke on Android, iOS, macOS, Windows:
  open a media item with no transcript → Generate → confirm track
  appears and primary is selected.