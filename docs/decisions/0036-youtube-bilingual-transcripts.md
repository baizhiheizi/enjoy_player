# ADR-0036: YouTube bilingual transcripts via multi-language worker contract

## Status

Accepted

## Context

Enjoy Player fetches a single YouTube caption per video from the Enjoy Worker
(`POST /youtube/transcripts`). Language learners reading along almost always
want **two** captions at once: the video's **original** language and a caption
translated into their **native** language. Today they must manually pick a
translation track (if one even exists locally), and the app issues one request
per language.

The Worker now accepts a `languages` array on the same endpoint: the first entry
is the **source** language (the original caption actually fetched from the
video) and any remaining entries are **translation** targets, fetched once and
translated in-step. The multi-language response returns a `transcripts[]` list
(with a `partial` status + `missing_languages` when some are unavailable).
Separately, the Worker supports a `wait_ms` body field for server-side
long-polling and emits `Retry-After: 5` while generating.

The client's existing poll loop wakes every 2 s for up to 30 attempts (~60 s),
issuing a fresh `POST` each cycle even while captions are still being produced.
Worker source of truth: `apps/worker/src/routes/youtube.ts` (local clone
`C:\Users\me\dev\enjoy`).

## Decision

1. **Single bilingual request.** When a signed-in learner's native language
   differs from the video's content language, send
   `pollTranscripts({ languages: [source, native], waitMs })` and store the
   original caption as the **primary** transcript and the native translation as
   the **secondary** transcript (explicit assignment via
   `updatePrimaryTranscriptForTarget` / `updateSecondaryTranscriptForTarget`,
   not source-priority sort).
2. **Conditional single-vs-multi path.** Use the multi-language path **only**
   when a valid, *different* native language is known. When the native language
   is unknown/null, equals the source, or the source is `und`, keep the existing
   single-language path (`language: <source>`, flat response). This preserves
   the single-language **Apify fallback** (`handleApifyFallbackWorkflow`), which
   the multi-language path does **not** have — so monolingual/edge fetches do not
   regress.
3. **`partial` is success.** Store every caption that *is* ready and treat the
   result as `success` (never an error). `missing_languages` is logged via
   `logNamed` for diagnostics only. When the *source* language itself is the
   missing entry, no primary is invented from a non-existent row — the existing
   source-priority sort (`ensurePrimaryTranscript`) picks a readable track.
4. **Server-side long-poll now; ETag-GET / SSE deferred.** Replace the fixed
   `2 s × 30` client sleep loop with `wait_ms` server-side long-polling. Send
   `waitMs` on every POST and honour the worker's `Retry-After` (a constant 5 s,
   since `ApiClient.postJson` does not expose response headers) between
   `generating` responses, with a bounded attempt budget (~60–75 s total).
   `GET /:job_id` (ETag/304) and `/events` (SSE) are cheaper/streaming
   alternatives but require a persisted `jobId`, a 304-aware client path, or a
   streaming dependency — deferred to a follow-up.
5. **Native-language plumbing (architecture-safe).** The repository stays
   UI-free. The learner's `effectiveNativeLanguage` is read inside the
   `TranscriptFetchCtrl._runResolve` helper — the single path shared by both
   `resolveOnOpen` (media open) and `refreshFromCloud` (manual refresh) — and
   passed down as a parameter, so a manual "refresh from cloud" re-requests both
   captions (no second threading point, no starved refresh).

No DB schema change is required: `EchoSessions.secondaryTranscriptId`,
`Transcripts`, and `TranscriptFetchStates` already support multi-track storage,
and both primary/secondary DAO setters already exist.

## Consequences

- Learners get original + native captions side by side after one request, with
  both auto-selected (no manual picker action).
- Request count per video drops from up to ~30 fixed-interval polls to a handful
  of long-poll POSTs; time-to-first-caption stays at parity (the server long-
  polls internally at 1 s and returns as soon as the workflow is terminal).
- Reopen of an already-fetched video stays network-free (existing fetch-state
  guard unchanged).
- The multi-language path does **not** trigger the Apify fallback; the
  conditional path choice keeps Apify intact for the source-only / unknown-native
  cases that depend on it.
- If a future worker version changes the `languages` / `partial` / `wait_ms`
  contract, the client parsing in `_fetchYoutubeWorkerTranscripts` and
  `_storeWorkerTranscriptList` is the place to update.

## References

- Feature spec: `specs/008-youtube-bilingual-captions/spec.md`
- Worker contract: `specs/013-client-yt-transcripts/contracts/worker-cache-api.md` (the poll-based contract described here is retired — the worker now exposes a cache-only `POST /youtube/transcripts` accepting `format`, `video_id`, `language`, `caption_fetch`, `source`, `timeline`, `metadata`, `generated_at`; see issue #320)
- YouTube playback: [ADR-0015](0015-youtube-playback.md), [docs/features/youtube.md](../features/youtube.md)
- Transcripts: [docs/features/transcript.md](../features/transcript.md)
