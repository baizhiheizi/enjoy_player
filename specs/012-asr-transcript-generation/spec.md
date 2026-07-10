# Feature Specification: ASR Transcript Generation

**Feature Branch**: `012-asr-transcript-generation`

**Created**: 2026-07-10

**Status**: Draft

**Input**: User description: "If you import some materials, if there're no subtitles there, Enjoy Player should provide the ASR capability, generate the transcription from the material, video or audio. We'll use Azure ASR as default, both Enjoy API and BYOK. You need ref the similar implementation of the webapp in `~/dev/enjoy/apps/web`. Design it concisely. Take care of the format of the transcript. We should always provide an option to generate/re-generate transcript."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Generate a transcript when none exists (Priority: P1)

A learner imports or opens a local audio or video file that has no
subtitles—no sidecar `.srt` / `.vtt`, no embedded subtitle streams, and no
cloud transcript available. Instead of being stuck with a blank transcript panel
and no path forward, the learner can **generate** a transcript from the media's
audio using speech recognition. The generated transcript appears in the same
transcript panel with the same line-tap-to-seek, highlight, and dictionary
lookup behavior as imported subtitles.

**Why this priority**: This is the core value of the feature. Without a
discoverable "generate transcript" action that produces a usable, time-aligned
transcript from audio, nothing else matters.

**Independent Test**: Open a media item that resolves to no transcript tracks at
all; invoke the generate-transcript action; confirm a time-aligned transcript
appears and is usable for playback tracking, dictionary lookup, and echo
practice just like an imported subtitle file.

**Acceptance Scenarios**:

1. **Given** a media item with no transcript tracks after import / cloud
   resolution, **When** the transcript empty state is shown, **Then** the learner
   sees a **Generate transcript** action alongside existing Extract / Import
   options.
2. **Given** the learner invokes Generate transcript, **When** the media's audio
   is processed through speech recognition, **Then** progress feedback is shown
   (status text and/or progress indicator) and the learner is never left
   wondering if the app is working or frozen.
3. **Given** speech recognition completes successfully, **When** the result is
   saved, **Then** a transcript track with `source: ai` appears in the subtitle
   picker and is auto-selected as the primary track so the learner sees lines
   immediately.
4. **Given** the generated transcript is displayed, **When** the learner plays
   the media, **Then** lines highlight, scroll, and respond to tap-to-seek
   identically to an imported `.srt` / `.vtt` transcript.
5. **Given** the learner is on a platform or media type where audio extraction
   is not possible, **When** they reach the empty state, **Then** the Generate
   action is either hidden or clearly disabled with an explanation—not a silent
   failure when tapped.

---

### User Story 2 - Re-generate a transcript at any time (Priority: P1)

A learner who already has a transcript (generated, imported, or fetched) may
want a fresh ASR pass—perhaps the first result was poor, the wrong language was
detected, audio quality improved after re-import, or they simply want to try
again. The app always provides a **re-generate** path so the learner is never
locked into a bad transcript.

**Why this priority**: Equal to P1 generation. Without re-generate, a poor ASR
result is permanently sticky and the learner has no recovery path within the
app.

**Independent Test**: With an existing ASR-generated transcript displayed, invoke
re-generate from the subtitle picker or transcript actions; confirm a new ASR
pass runs and replaces the prior `source: ai` track in place.

**Acceptance Scenarios**:

1. **Given** the learner has any transcript (AI-generated, imported, or cloud),
   **When** they open the subtitle track picker actions, **Then** a **Generate /
   Re-generate transcript** action is always present and available—not hidden
   behind developer settings or long-press gestures.
2. **Given** an AI-generated transcript already exists for this media, **When**
   the learner re-generates, **Then** the new result replaces the prior
   `source: ai` track for the same language in place (upsert by deterministic
   id) rather than creating a duplicate row.
3. **Given** re-generation is in progress, **When** the learner continues
   interacting with the app, **Then** playback and existing transcript display
   remain usable; the old transcript stays visible until the new result is ready.
4. **Given** the learner re-generates after changing the content language of the
   media, **When** the new pass completes, **Then** the transcript reflects the
   newly specified language (or the auto-detected one) and the track metadata
   (label, language) is updated.

---

### User Story 3 - Azure ASR as default, with Enjoy API and BYOK paths (Priority: P1)

ASR uses Azure Speech as the default recognition backend. Learners signed in to
Enjoy get this through the Enjoy API (the worker handles Azure token management,
credits, and routing between short-form and long-form recognition). Learners who
prefer their own credentials use the existing **BYOK** flow (Azure Speech
subscription key + region, or OpenAI-compatible Whisper) configured per-modality
in Settings. Either path produces the same quality of result and the same
transcript format.

**Why this priority**: Azure Speech provides high-quality, multi-language
recognition necessary for a learning app. Both the managed (Enjoy API) and
self-managed (BYOK) paths are established product patterns and must work for
ASR.

**Independent Test**: Configure ASR provider as Enjoy (signed in) and generate a
transcript; then configure BYOK Azure Speech and generate again; confirm both
produce usable transcripts with consistent format and quality.

**Acceptance Scenarios**:

1. **Given** the learner is signed in with the ASR modality set to Enjoy
   (default), **When** they generate a transcript, **Then** the Enjoy worker
   handles recognition via Azure Speech and credits are consumed according to
   audio duration.
2. **Given** the learner has configured BYOK for ASR (Azure Speech subscription
   key + region, or OpenAI-compatible Whisper), **When** they generate a
   transcript, **Then** the app uses the learner's own credentials and does not
   deduct Enjoy credits.
3. **Given** BYOK credentials are missing or invalid at generation time,
   **When** the learner tries to generate, **Then** they get a clear, actionable
   error that links back to the AI providers settings—not a silent Enjoy
   fallback or a raw exception string.
4. **Given** the audio duration exceeds the short-form threshold, **When** the
   Enjoy API path is active, **Then** the app uses long-form continuous Azure
   Speech recognition (not a single-shot) so longer media is fully transcribed.
5. **Given** credits are exhausted on the Enjoy API path, **When** generation is
   attempted, **Then** the learner sees a credits-exhausted message with a path
   to upgrade, consistent with other AI surfaces.

---

### User Story 4 - Transcript format consistency and quality (Priority: P2)

The generated transcript must be time-aligned, segmented into readable lines,
and stored in the same format as imported subtitle files so that every existing
transcript feature—playback highlight, dictionary lookup, echo region, blur
practice, auto-translate—works without special cases. Lines should be
intelligently grouped (not one giant block, not one word per line) with accurate
timestamps derived from word-level recognition timings.

**Why this priority**: A raw text blob or poorly segmented transcript degrades
the entire learning experience. Format parity with existing subtitles is what
makes ASR output a first-class transcript.

**Independent Test**: Generate a transcript from a 5-minute media file; confirm
lines are reasonably sized (a few seconds each), timestamps align with audio,
and all existing transcript features (highlight, lookup, echo, blur,
auto-translate) work on the generated track.

**Acceptance Scenarios**:

1. **Given** ASR returns word-level or segment-level timings, **When** the
   transcript is constructed, **Then** lines are segmented into readable groups
   (roughly sentence-length, not one-word lines and not one monolithic block)
   with start times and durations in milliseconds, matching the existing
   `TranscriptLine` shape.
2. **Given** the generated transcript is stored, **When** the subtitle picker
   lists it, **Then** it is labeled as AI-generated (provider badge `ai`) with
   the detected or specified language, consistent with how imported tracks show
   `user` and cloud tracks show `official` / `auto`.
3. **Given** ASR returns only plain text without timings, **When** the transcript
   is constructed, **Then** the app falls back to a reasonable timing strategy
   (e.g. evenly distributed across the media duration) rather than producing a
   track with no timestamps or a single 0-ms line.
4. **Given** the generated transcript is active, **When** the learner uses
   dictionary lookup, echo region, blur practice, or auto-translate, **Then**
   these features work identically to how they work on imported subtitle
   tracks—no feature regression.

---

### User Story 5 - Audio extraction from video before recognition (Priority: P2)

Video files must have their audio track extracted before speech recognition can
run. This extraction must work across supported platforms (Android, iOS, macOS,
Windows), report progress, and handle errors gracefully (corrupt files, no audio
track, very large files). Audio-only files use the audio directly.

**Why this priority**: Without reliable audio extraction, ASR cannot run on
video—the most common media type.

**Independent Test**: Open a video file with no subtitles; trigger generation;
confirm audio is extracted (with progress feedback) before recognition runs and
the final transcript aligns with the video's audio.

**Acceptance Scenarios**:

1. **Given** the learner generates a transcript for a video file, **When** audio
   extraction begins, **Then** the UI shows that extraction is in progress
   before recognition starts.
2. **Given** the media file has no audio track, **When** generation is
   attempted, **Then** the learner gets a clear error explaining there is no
   audio to transcribe.
3. **Given** a very large video file, **When** extraction runs, **Then** the
   process does not freeze the UI or exhaust device memory; progress is reported
   and the learner can cancel.
4. **Given** an audio-only file, **When** generation is triggered, **Then**
   extraction is skipped and recognition runs directly on the audio.

---

### User Story 6 - Language selection and auto-detection (Priority: P2)

The learner can specify the spoken language before generating, or let the
recognition service auto-detect it. When auto-detection is used and returns a
different language than the media record's language, the app updates the media
language so downstream features (YouTube captions, auto-translate target) use the
correct source.

**Why this priority**: Correct language identification is essential for
transcript quality and for downstream features that depend on the media language.

**Independent Test**: Generate a transcript with explicit language selection;
then generate with auto-detect on a media file whose stored language is wrong;
confirm the detected language is reflected in the track metadata and media
record.

**Acceptance Scenarios**:

1. **Given** the learner generates a transcript, **When** the generation dialog
   or action is presented, **Then** they can choose the spoken language or
   accept the media's current language as the default.
2. **Given** auto-detect is used and ASR returns a detected language, **When**
   the transcript is saved, **Then** the track's language field reflects the
   detected language.
3. **Given** the detected language differs from the media record's stored
   language, **When** the pass completes, **Then** the media record is updated
   to the detected language so future cloud fetches and features use the correct
   language.

---

### Edge Cases

- **YouTube / streaming media**: ASR generation is for local audio/video files
  only. YouTube rows already have a dedicated caption-fetch path; generation
  should not be offered (or should clearly explain it is local-file-only).
- **Audio extraction unavailable** (no FFmpeg on Windows PATH, no bundled binary):
  the Generate action is disabled or hidden with an explanation; Import and
  other paths remain available.
- **Very long media** (e.g. 2-hour lecture): recognition must not hang or crash;
  progress continues to report; the learner can cancel; credits (Enjoy path) are
  capped at a maximum billable duration.
- **Signed-out learner on Enjoy path**: generation fails with a clear sign-in
  prompt, not a silent no-op; BYOK path works without sign-in.
- **Partial recognition failure** (Azure session error mid-stream): whatever
   segments were recognized before the failure should be preserved if usable,
   with a clear warning that the result may be incomplete.
- **Empty or silent audio**: ASR returns empty text; the app handles this
  gracefully (informative message, no empty track created).
- **Unsupported language**: if the specified or detected language is not
  supported by Azure Speech, the learner gets a clear message listing supported
  options.
- **Concurrent generation**: starting a new generation while one is in-flight
  cancels the prior run cleanly (no overlapping writes, no torn state).
- **Re-generate while an AI track is the active primary/secondary**: the track
  id is deterministic so the upsert replaces in place; the active selection is
  preserved, echo session references stay valid.
- **BYOK OpenAI Whisper** returns text only (no word timings): the transcript
  uses the duration-based fallback segmentation so the result is still usable
  with approximate timestamps.
- **Platform differences**: generation works on Android, iOS, macOS, and Windows
  with the existing subtitle picker / transcript panel presentations; audio
  extraction respects platform-specific FFmpeg discovery (bundled binary on
  Windows, PATH on others).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The transcript empty state MUST offer a **Generate transcript**
  action when the media is a local audio or video file eligible for ASR.
- **FR-002**: The subtitle track picker actions MUST always include a
  **Generate / Re-generate transcript** action for eligible local media,
  regardless of whether tracks already exist.
- **FR-003**: Invoking generation MUST extract audio from video files before
  running recognition; audio-only files MUST be passed directly to recognition.
- **FR-004**: Audio extraction MUST work on all supported platforms (Android,
  iOS, macOS, Windows) and MUST report progress to the learner.
- **FR-005**: The app MUST use Azure Speech as the default ASR backend,
  available through both the Enjoy API (managed, signed-in) and BYOK (user
  credentials) paths, following the existing per-modality provider setting.
- **FR-006**: When the Enjoy API path is active and audio duration exceeds the
  short-form threshold, the app MUST use long-form continuous Azure Speech
  recognition so longer media is fully transcribed.
- **FR-007**: ASR generation MUST produce a transcript stored as `source: ai`
  with the same `TranscriptLine` format (text + startMs + durationMs) as
  imported subtitle files.
- **FR-008**: Generated lines MUST be intelligently segmented from word-level or
  segment-level timings into readable, roughly sentence-length cues—not one
  monolithic block and not one word per line.
- **FR-009**: When ASR returns only plain text without timings, the app MUST
  fall back to a reasonable timing strategy (duration-distributed) so the
  transcript is still usable with approximate timestamps.
- **FR-010**: Re-generating a transcript for the same media + language MUST
  upsert the existing `source: ai` track in place (deterministic id) rather than
  creating a duplicate row.
- **FR-011**: The learner MUST be able to select the spoken language before
  generating, with the media's current language as the default.
- **FR-012**: When ASR auto-detects a language that differs from the media
  record's stored language, the app MUST update the media record to the
  detected language.
- **FR-013**: ASR generation MUST show progress feedback (status text and/or
  progress indicator) during extraction and recognition so the learner is never
  left wondering if the app is working.
- **FR-014**: The learner MUST be able to cancel an in-progress generation.
- **FR-015**: Starting a new generation while one is in-flight MUST cancel the
  prior run cleanly without overlapping writes or torn transcript state.
- **FR-016**: Generated transcripts MUST be immediately usable by all existing
  transcript features: playback highlight, tap-to-seek, dictionary lookup, echo
  region, blur practice, and auto-translate.
- **FR-017**: Errors (no audio track, unsupported language, credits exhausted,
  BYOK not configured, network failure, extraction failure) MUST surface as
  friendly, actionable messages—never raw exception text as the primary copy.
- **FR-018**: BYOK credentials missing or invalid MUST produce a clear message
  linking back to AI providers settings, with no silent Enjoy fallback.
- **FR-019**: Credits-exhausted on the Enjoy path MUST show a credits-exhausted
  message with an upgrade path, consistent with other AI surfaces.
- **FR-020**: ASR generation MUST NOT be offered for YouTube / streaming media
  that already has a dedicated caption-fetch path; it is local-file-only.
- **FR-021**: After successful generation, the `source: ai` track MUST be
  auto-selected as the primary transcript so the learner sees lines immediately.
- **FR-022**: The generated transcript's label and provider badge (`ai`) MUST
  clearly indicate it is AI-generated, consistent with how imported tracks show
  `user` and cloud tracks show `official` / `auto`.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first
  architecture and reuse the existing `AsrCapability` / `AsrService` /
  `asrServiceProvider` abstraction; no vendor HTTP calls directly in UI or
  feature widgets.
- **QR-002**: Behavior changes MUST include automated tests (unit tests for
  segmentation, timeline construction, language detection mapping, and the
  generation controller; widget tests for the empty-state action and picker
  action) or document why manual verification is the only option.
- **QR-003**: User-facing strings, controls, haptics, tooltips, and keyboard
  affordances MUST follow existing localization (ARB files) and shared UI
  patterns (`EnjoyTappableSurface` / `EnjoyButton` / `TranscriptBusyButton`,
  friendly error + Retry, subtitle picker sheet/dialog).
- **QR-004**: Audio extraction and ASR processing MUST run off the main isolate
  / not block UI frames; the transcript list and playback MUST remain responsive
  during generation on supported desktop and mobile targets.
- **QR-005**: Feature behavior changes MUST update the matching documentation
  under `docs/features/` (transcript feature doc, ai feature doc).
- **QR-006**: Logging MUST use `logNamed` (never `print()`); ASR-specific logs
  should include duration, language, provider, and outcome without exposing
  secrets.
- **QR-007**: The generation confirmation / progress UI MUST be calm and
  non-blocking—inline progress or a compact dialog, not a full-screen modal that
  prevents playback interaction unless necessary for confirmation.
- **QR-008**: For very long media (e.g. ≥ 30 minutes), the UI SHOULD warn the
  learner that generation may take a while and/or consume significant credits,
  with a confirmation before proceeding.

### Key Entities

- **ASR generation job**: The logical work of extracting audio, running speech
  recognition, constructing a segmented timeline, and persisting the result as a
  `source: ai` transcript track for a media item.
- **Generated transcript track**: A transcript row with `source: 'ai'`,
  deterministic id (`enjoyTranscriptId` with source `ai`), time-aligned
  `TranscriptLine[]` timeline, detected or specified language, and a label
  indicating AI generation.
- **Spoken language**: The language of the audio content; either explicitly
  chosen by the learner or auto-detected by the ASR service; stored on the
  transcript track and propagated to the media record when detected.
- **Audio extraction**: The intermediate step of converting a video file's audio
  track into a format suitable for speech recognition (platform FFmpeg), with
  progress reporting and error handling.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a media item with no transcript, the learner finds and triggers
  Generate transcript in **≤ 2 taps/clicks** from the transcript panel empty
  state on **100%** of supported platforms.
- **SC-002**: For a typical 5-minute media file under normal connectivity,
  generation completes and the first usable transcript lines appear within
  **60 seconds** on desktop targets.
- **SC-003**: During generation (extraction + recognition), playback, scrolling,
  and transcript panel interaction remain usable with no sustained UI jank on
  supported desktop and mobile targets.
- **SC-004**: Re-generating a transcript for the same media + language produces
  exactly **one** `source: ai` track (upsert, no duplicate rows) in **100%** of
  regression checks.
- **SC-005**: After generation, **all** existing transcript features (highlight,
  tap-to-seek, dictionary lookup, echo region, blur practice, auto-translate)
  work on the generated track without regression in **100%** of verification
  scenarios.
- **SC-006**: Both the Enjoy API path (signed-in) and the BYOK path (Azure
  Speech / OpenAI Whisper) produce transcripts with the same format and
  feature compatibility.
- **SC-007**: **100%** of user-visible error messages for this feature are
  localized and free of raw exception text as the primary message.
- **SC-008**: Audio extraction from video works on **all four** supported
  platforms (Android, iOS, macOS, Windows) where FFmpeg is available, and the
  Generate action is clearly disabled/hidden when extraction is not possible.
- **SC-009**: At least **90%** of test participants understand that the
  generated transcript is AI-sourced (via the `ai` provider badge and label)
  without additional explanation.

## Assumptions

- ASR uses the existing `AsrCapability` abstraction and provider routing
  (`EnjoyAsrCapability` for the managed path, `ByokAsrAzureCapability` /
  `ByokAsrOpenAiCapability` for BYOK). The ASR service and models
  (`AsrRequest` / `AsrResult` / `AsrSegment` / `AsrWord`) are already
  implemented; this feature wires the end-to-end generation flow.
- The Enjoy API path routes short audio (< ~2 min) to Whisper and longer audio
  to Azure Speech continuous recognition, mirroring the webapp's
  `LONG_AUDIO_AZURE_THRESHOLD_SECONDS` (120s) routing. This routing is an
  implementation detail handled by the worker / client.
- Azure token management for the Enjoy API long-form path reuses the existing
  `AzureTokenApi` / `AzureTokenCache` (9-min TTL) already wired for assessment,
  or an equivalent native Azure Speech continuous recognition path. The exact
  SDK integration (native plugin vs. worker-mediated) is a planning concern.
- Audio extraction from video uses FFmpeg (already used for embedded subtitle
  extraction in the Flutter app), reusing the platform-specific binary discovery
  (bundled `ffmpeg.exe` on Windows, PATH elsewhere).
- The generated transcript's timeline is segmented from ASR word-level or
  segment-level timings using an intelligent segmentation strategy (grouping
  words into roughly sentence-length lines by pauses, punctuation, and meaning
  boundaries), mirroring the webapp's `transcript-segmentation` pipeline. The
  exact port of this segmentation logic is a planning concern.
- Credits on the Enjoy path follow existing per-second ASR billing (capped at a
  maximum billable duration, e.g. 1 hour) consistent with the webapp and worker.
- BYOK OpenAI Whisper returns text only (no word timings); BYOK Azure Speech
  uses single-shot or continuous recognition depending on platform SDK
  capability. Both fall back to duration-distributed segmentation when timings
  are unavailable.
- The generation confirmation / progress UI follows the same calm, non-blocking
  patterns established by transcript fetch (inline spinners, status text) and
  the auto-translate feature (compact progress, friendly errors).
- YouTube and streaming media continue to use their existing caption-fetch paths
  and are not eligible for ASR generation.
- Editing generated transcript lines, exporting generated transcripts, and
  multi-pass ASR refinement are out of scope for this change.
- Web targets remain out of scope per product platform policy.
