# Feature Specification: Deepgram Long-Form ASR (Flutter Client)

**Feature Branch**: `025-deepgram-long-form-asr`

**Created**: 2026-07-19

**Status**: Draft

**Input**: User description: "Let's replace the ASR with the deepgram API in worker API for flutter client. ref enjoy/apps/worker/docs/long-form-transcription.md and enjoy/apps/worker/src/services/deepgram"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Transcribe long local media via Enjoy (Priority: P1)

A signed-in learner opens a local audio or video lecture that is **15 minutes or longer** and has no usable subtitles. They choose **Generate transcript**. The app uses the Enjoy managed worker path for long-form recognition (Deepgram behind the worker), shows clear progress while the job runs asynchronously, and when finished presents a time-aligned `source: ai` transcript that works like any other subtitle track.

**Why this priority**: Long media is the gap this change closes. The previous Enjoy long-form path is being replaced by the worker's Deepgram job API; without Flutter adopting that contract, long lectures remain unreliable or unavailable on the managed path.

**Independent Test**: Sign in on a Pro/Ultra account with remaining daily Credits; open a local file ≥ 15 minutes with no transcripts; generate; wait until a timed transcript appears and supports tap-to-seek, highlight, and lookup.

**Acceptance Scenarios**:

1. **Given** a signed-in learner and eligible local media whose duration is at least 15 minutes, **When** they invoke Generate / Re-generate transcript with the Enjoy ASR path active, **Then** the app submits a long-form job through the Enjoy worker (not a single synchronous short-clip upload of the whole file) and shows non-blocking progress until the job finishes.
2. **Given** a long-form job is accepted, **When** recognition is still running, **Then** the learner sees a processing state (status text and/or progress) and can continue using the app; playback and any existing transcript remain usable until the new result is ready.
3. **Given** the job completes successfully, **When** the result is saved, **Then** a `source: ai` track appears (or replaces the prior AI track for that language), becomes primary, and lines highlight / seek like imported subtitles.
4. **Given** the completed job includes usage information, **When** the transcript is shown, **Then** the learner can see that Credits were charged for the actual transcribed duration (consistent with other AI credit surfaces), without seeing provider credentials or internal billing formulas.

---

### User Story 2 - Keep short-clip Enjoy ASR working (Priority: P1)

A learner generates a transcript for local media **shorter than 15 minutes** on the Enjoy path. Behavior stays the familiar synchronous short-clip flow: they get a result without learning a new async job model, and short clips are not forced through the long-form Deepgram job API.

**Why this priority**: The worker contract intentionally splits short vs long. Breaking short-clip generation would regress the most common ASR use case.

**Independent Test**: Generate a transcript for a ~5-minute local file on the Enjoy path; confirm a usable timed transcript appears without requiring job-polling UX as the primary path.

**Acceptance Scenarios**:

1. **Given** local media under 15 minutes and Enjoy ASR selected, **When** the learner generates a transcript, **Then** recognition completes through the existing short-clip Enjoy path and produces a usable `source: ai` track.
2. **Given** the same Generate / Re-generate entry points used today, **When** duration is under the long-form threshold, **Then** the learner is not asked for long-form-only steps (e.g. idle-only job polling as the only feedback) beyond normal progress for short recognition.

---

### User Story 3 - Safe retries, cancel, and failure recovery (Priority: P1)

Long-form jobs can take minutes. Learners lose connectivity, dismiss the app, run out of Credits, or hit a provider failure. The app must recover safely: retries must not double-charge, cancel must stop waiting, and failures must be actionable.

**Why this priority**: Async jobs without idempotent retry and clear failures destroy trust and can waste Credits.

**Independent Test**: Simulate a network drop after submit and retry with the same intent; simulate credits exhausted and a retryable provider failure; confirm no duplicate charge, clear messages, and a path to try again with a fresh attempt when appropriate.

**Acceptance Scenarios**:

1. **Given** a long-form submission times out or the app restarts while a job is in flight, **When** the learner retries generation for the same attempt, **Then** the app resumes or reattaches to the same job when safe (idempotent retry) and does not create a duplicate billable job for that attempt.
2. **Given** the learner cancels generation, **When** cancel is confirmed, **Then** the UI leaves the waiting state, does not overwrite the prior transcript with a partial result, and a later successful run can still replace the AI track.
3. **Given** preflight Credits are insufficient (including Free tier for ≥ 15 minute media), **When** generation is attempted, **Then** the learner sees a credits-exhausted / upgrade message and no long-form job is left in a confusing half-started UI state.
4. **Given** the job fails with a retryable reason, **When** the failure is shown, **Then** the learner can start a **new** attempt (fresh retry identity) and understands the previous attempt ended; non-retryable failures (e.g. unsupported media, billing exhausted at settlement) explain that retrying the same way will not help or that they need to upgrade / change media.

---

### User Story 4 - Language, credits preview, and BYOK unchanged where appropriate (Priority: P2)

Before generating, the learner can pick spoken language (or omit for multilingual / auto mode per product rules). For long media, they get a clear Credits-oriented confirmation when duration warrants it. Learners on **BYOK** ASR continue to use their own credentials and are not forced onto Deepgram/Enjoy long-form billing.

**Why this priority**: Language and Credits UX affect quality and spend; BYOK must not regress when Enjoy switches long-form vendors.

**Independent Test**: Generate long-form with an explicit language and with language omitted; confirm pricing mode and track language behave as expected. With BYOK ASR configured, generate on long media without Enjoy long-form job submission.

**Acceptance Scenarios**:

1. **Given** the generation UI, **When** the learner chooses a spoken language or leaves multilingual / auto, **Then** that choice is sent on the Enjoy long-form request and reflected in the saved track metadata when the job completes.
2. **Given** media at or above the long-form threshold on the Enjoy path, **When** generation is about to start, **Then** the learner sees a confirmation that communicates long duration and Credit impact before the costly upload/job begins (aligned with existing long-media confirm patterns, using the **15-minute** worker threshold).
3. **Given** BYOK ASR is selected and valid, **When** the learner generates for long local media, **Then** recognition uses BYOK credentials, Enjoy daily Credits for Deepgram long-form are not charged, and failure messages still point to AI provider settings when credentials are wrong.

---

### User Story 5 - Format parity with existing AI transcripts (Priority: P2)

Completed long-form results must become the same local transcript shape used by short-clip ASR and imports, so highlight, lookup, echo, blur, and auto-translate need no special cases.

**Why this priority**: A provider-shaped blob that breaks learning features is not a successful migration.

**Independent Test**: Complete a long-form job; exercise highlight, tap-to-seek, lookup, and re-generate upsert; confirm parity with a short-clip AI track.

**Acceptance Scenarios**:

1. **Given** a completed long-form transcript with segments and/or words, **When** the app builds local lines, **Then** cues are readable sentence-scale lines with start and duration, not one word per line and not one monolithic block.
2. **Given** an existing `source: ai` track for the same media and language, **When** long-form re-generation completes, **Then** the track is upserted in place (deterministic identity) without duplicating rows or breaking the active selection.
3. **Given** the new AI track is primary, **When** the learner uses lookup, echo, blur, or auto-translate, **Then** those features behave as they do for imported or short-clip AI tracks.

---

### Edge Cases

- **Duration exactly 15 minutes (900 seconds)**: treated as long-form on the Enjoy path.
- **Declared duration under 900 seconds**: must not call the long-form job API; use short-clip Enjoy path instead.
- **Free-tier daily Credits**: long-form is blocked at preflight with upgrade guidance (worker policy: Free cannot fund ≥ 15 min at current rates).
- **Signed-out learner on Enjoy path**: clear sign-in prompt; no silent failure.
- **Upload or media reference missing / not owned**: clear error; no endless processing spinner.
- **Unsupported media at the provider**: terminal non-retryable failure with a safe message.
- **Provider timeout / provider failure**: retryable failure messaging; new attempt uses a new retry identity.
- **Billing exhausted at settlement**: transcript not applied; Credits messaging consistent with other AI surfaces.
- **App backgrounded or killed during poll**: on return, the in-flight job can be resumed or status checked without double submit for the same attempt.
- **YouTube / streaming rows**: still local-file-only for ASR; caption-fetch path unchanged.
- **Very large files**: upload and recognition must not freeze the UI; progress remains visible; cancel remains available during client-controlled phases.
- **Linux and other supported desktops**: same Generate entry points and outcomes as other platforms once audio extraction / file access succeed.
- **Concurrent generation**: starting a new generation cancels or supersedes waiting on the prior client wait loop without torn local DB writes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: On the Enjoy ASR path, local media with duration **≥ 15 minutes (900 seconds)** MUST use the worker long-form transcription job flow documented for clients (submit job → poll until terminal → apply transcript), not the short-clip synchronous multipart path for the full long file.
- **FR-002**: On the Enjoy ASR path, local media with duration **< 15 minutes** MUST continue to use the short-clip Enjoy transcription path.
- **FR-003**: Long-form Enjoy generation MUST authenticate with the learner's Enjoy session; the app MUST NOT require or store a Deepgram API key.
- **FR-004**: Before long-form submit, the app MUST ensure the media (or extracted audio suitable for recognition) is available to the worker under a user-scoped media reference required by the long-form API.
- **FR-005**: Long-form submit MUST send declared duration (for preflight), optional language, and a client-generated idempotency key for the attempt.
- **FR-006**: After accept, the app MUST poll job status with backoff until `completed` or `failed` (or until the learner cancels waiting).
- **FR-007**: Retrying the same interrupted attempt MUST reuse the same idempotency key so the worker returns the existing job and does not create a duplicate provider request.
- **FR-008**: Starting a **new** attempt after a terminal failure or explicit re-generate MUST use a new idempotency key.
- **FR-009**: On `completed`, the app MUST map the returned transcript (text, language, segments/words, timings) into the existing local `source: ai` transcript format and upsert by the existing deterministic AI track identity.
- **FR-010**: On `failed`, the app MUST show a localized, actionable message based on failure category (retryable vs not), including credits-exhausted / billing-exhausted and unsupported media.
- **FR-011**: Free-tier or otherwise insufficient Credits at preflight MUST block long-form with upgrade / credits messaging consistent with other AI features.
- **FR-012**: Generate / Re-generate entry points from the transcript empty state and subtitle picker MUST remain available for eligible local media; long-form is a backend/path change, not a removal of those actions.
- **FR-013**: Learners MUST be able to cancel waiting on an in-flight long-form generation from the client UI.
- **FR-014**: Long media confirmation for Enjoy MUST use the **15-minute** threshold aligned with the worker long-form gate (replacing any higher client-only threshold for this path).
- **FR-015**: BYOK ASR paths MUST remain available and MUST NOT be routed through Enjoy Deepgram long-form billing.
- **FR-016**: Short-clip Enjoy, pronunciation assessment (if present elsewhere), and YouTube caption-fetch MUST remain outside this long-form replacement scope.
- **FR-017**: Polling MUST NOT be presented as a Credits-consuming action; only successful long-form settlement (server-side) charges Credits.
- **FR-018**: When the completed response includes `credits_charged` / actual duration, the app SHOULD surface that usage in a way consistent with existing Credits UX (at minimum, not contradict server-charged amounts).
- **FR-019**: ASR MUST remain local-file-only; YouTube / streaming media MUST NOT gain Deepgram long-form generation as a substitute for caption fetch.
- **FR-020**: Errors MUST never show raw provider or stack traces as primary user copy.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve feature-first layout and the existing ASR capability / service abstractions; UI MUST NOT call worker HTTP directly from widgets.
- **QR-002**: Changed behavior MUST include automated tests for routing (short vs long), idempotency-key lifecycle, status→local transcript mapping, and failure message mapping—or document why only manual verification is possible.
- **QR-003**: User-facing strings and controls MUST use ARB localization and shared Enjoy UI primitives.
- **QR-004**: Upload, extraction, and polling MUST keep the UI responsive (no sustained main-thread stalls); learners MUST see progress during multi-minute jobs.
- **QR-005**: Feature behavior changes MUST update `docs/features/asr.md` (and related AI/credits docs if Credits UX copy changes).
- **QR-006**: Logging MUST use project logging helpers (never `print()`), including job id, duration bucket (short/long), language mode, and terminal outcome without secrets.

### Key Entities

- **Long-form transcription job**: Server-owned job identified by `job_id`, with status (`accepted` / `processing` / `completed` / `failed`), timestamps, optional failure category, optional usage (`actual_duration_seconds`, `credits_charged`), and optional transcript payload.
- **Media reference**: Opaque, user-scoped handle to uploaded media required before long-form submit.
- **Idempotency key**: Client-generated key scoped to one generation attempt; reused on transport retry; replaced on a new attempt.
- **AI transcript track**: Existing local `source: ai` subtitle track with timed lines; upserted when a job completes.
- **Credits usage**: Daily pool and charge recorded by the worker from provider-measured duration; Free / Pro / Ultra limits apply.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On Pro/Ultra with sufficient Credits, 100% of successful long-form generations (≥ 15 min local media, Enjoy path) produce a primary timed AI transcript without the learner configuring a speech-vendor API key.
- **SC-002**: Short-clip Enjoy generation (< 15 min) continues to succeed in the same entry points; no new mandatory async-job ceremony for short media.
- **SC-003**: Replaying the same interrupted long-form attempt does not create a second billable job (verified against a single `job_id` / single Credits settlement for that attempt).
- **SC-004**: After a completed long-form track is applied, tap-to-seek and line highlight work on the first playback pass for at least 95% of sampled lines in manual QA on a 15–20 minute fixture.
- **SC-005**: Credits-exhausted and Free-tier long-form attempts show an upgrade/credits path within one screen of the failure—no blank transcript panel with no explanation.
- **SC-006**: During a multi-minute job, the UI remains interactive (navigate away and back, or continue playback) without a frozen shell; cancel returns the learner to a stable state within 2 seconds of confirmation.
- **SC-007**: BYOK ASR generation on long local media still completes without Enjoy long-form Credit charges when BYOK is correctly configured.
- **SC-008**: Documentation for ASR reflects the short-clip vs ≥ 15 minute Enjoy routing so support and contributors can explain behavior without reading worker source.

## Assumptions

- The Enjoy worker long-form HTTP contract in `apps/worker/docs/long-form-transcription.md` is the source of truth for client behavior (900s gate, JSON submit, poll, Credits settlement, failure categories).
- Worker Deepgram integration is already (or will be) available in the environments Flutter targets; this feature is the **Flutter client adoption**, not a re-implementation of Deepgram inside the app.
- Short-clip Enjoy transcription remains the multipart short-clip path; Deepgram is for long-form only.
- Obtaining a user-scoped **media reference** (upload of original or extracted audio into the worker-accessible store) is **in scope** for Flutter as a prerequisite step of long-form generation, even if a separate upload helper already exists for web.
- Azure long-form continuous recognition on the Enjoy path is retired for Flutter in favor of the worker Deepgram job API; BYOK Azure / Whisper remains for self-managed learners.
- Language omitted on long-form means multilingual mode and multilingual Credit rates, per worker pricing.
- Existing generate / re-generate product rules from ASR transcript generation (local files only, upsert AI track, progress, cancel) remain in force unless this spec overrides the Enjoy long-form mechanism and the 15-minute threshold.
- Linux is a supported desktop target for the same user-visible outcomes when media access and extraction succeed.
