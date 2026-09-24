# ADR-0049 — YouTube language-aware caption discovery & primary selection

- Status: Accepted
- Date: 2026-07-14
- Supersedes / amends: none; replaces the source-only `_pickYoutubePrimary` /
  `ensurePrimaryTranscript` interaction in `transcript_repository.dart`.

## Context

Two bugs in the YouTube transcript chain (spec 013) were repeatedly observed:

1. **Windows-fetches-but-Android-can't** — the InnerTube chain rotated
   through `ios` / `android_vr` / `mweb` / `web` profiles and the per-track
   timedtext GET always sent the iOS UA. On Android this could return 403 for
   every track (hidden inside the `Future.wait` per-track `try/catch`), the
   user saw an empty list, and the worker upload was lost because it was
   `unawaited` with only a `.then`/`.catchError` observer.
2. **Videos with `videos.language = 'und'` / empty** skipped the entire
   chain (`_workerCaptionLanguage` returned `null` and the early return at
   `transcript_repository.dart:496-509` short-circuited both Tier 1 and
   Tier 2). Imported rows where the user never set a content language
   showed no captions and no error.

A related design gap: `ensurePrimaryTranscript` sorts purely by source
priority and `createdAt`. It never consults the video's content language
or the user's learning language, so the post-Tier-2 picker often surfaced a
random track instead of the one matching what the user is studying.

## Decision

### 1. Always run Tier 2 for YouTube rows
- `_workerCaptionLanguage(video)` continues to return `null` for
  `kInvalidLanguageTags` (`''`, `'und'`, `'mul'`, `'mis'`, `'zxx'`), but
  that gate now narrows **only** the worker GET. Tier 2 (direct InnerTube)
  always runs when the row resolves to YouTube playback.
- When `preferredLang` is empty the fetcher receives `''` so no track is
  artificially ranked first; every available language is still returned and
  stored.

### 2. Language-aware primary picker (new `_pickYoutubePrimary`)
Rank rows for the post-fetch primary pick as:
1. Video's content language (broad subtag match).
2. User's learning language (broad match).
3. Existing source-priority + `createdAt` order.

A user-picked primary already on the session is always preserved (mirrors
the guard in `ensurePrimaryTranscript`).

### 3. Durable worker upload retry via `sync_queue`
Failed `client.uploadTranscript(...)` calls (returns `false` or throws)
now enqueue a `video` row with `payloadJson = {"kind": "youtube_upload",
"videoId", "language", "source", "timeline"}`. The next `SyncCtrl`
periodic drain (5 min) retries it via `YoutubeTranscriptsClient.uploadTranscript`.
This closes the Windows-fetches-but-Android-can't-serve-from-cache mode
where a transient worker failure left Android re-fetching forever.

### 4. Per-track timedtext UA parity (F4)
`_fetchCaptionTrack` now receives the `ClientProfile` that drove `/player`
and sends:
- `User-Agent: <profile.userAgent>` (was: hard-coded iOS UA)
- `Referer: https://m.youtube.com/`
- `Accept-Language: en-US,en;q=0.9`

### 5. Lazy worker profile fetch (F5)
New `youtubeProfilesProvider` (`lib/features/transcript/data/youtube_profiles_provider.dart`)
fetches `GET /youtube/client-profiles` on first YouTube open, caches in a
24 h `L1Store`, and falls back to `kBuiltInClientProfiles` on failure.
`transcriptRepositoryProvider` watches the profiles so the
`YoutubeCaptionFetcher` is rebuilt whenever fresh profiles arrive.

## Consequences

- Every YouTube row now persists one `TranscriptRow` per available language
  on first open — confirmed by `F1: Tier 2 still runs when videos.language
  is "und"` test.
- The picker honors user intent: a user who imported a video with `es-ES`
  gets Spanish as primary even when the video also has `en-US` captions,
  and a learner studying `en-US` whose video doesn't have an English track
  still gets English picked when present.
- Worker uploads are now durable across process restarts; Android users
  who previously had to manually refresh after a transient worker blip
  no longer do.
- A real `android` InnerTube profile was considered but **deferred** — the
  existing `android_vr` profile (Quest 3) is still the closest Android
  identity and changing the profile order risks regressions against the
  current YouTube fingerprint database. The UA-parity fix (F4) closes
  the common Android failure mode without changing the profile list.

## Verification

- `flutter analyze`: clean
- `flutter test`: 1348 tests passing (9 new in
  `transcript_repository_youtube_fallback_test.dart`)
- `dart format`: clean
- Updated feature docs: `docs/features/youtube.md`

## Amendments

- **2026-09-16 (issue #717)**: decision 3's drain consumer did not exist when
  this ADR landed — the retry rows are keyed `'$videoId/$language'`, but the
  `SyncEntityType.video` drain resolves `entityId` against local video row ids
  (UUIDv5), so every enqueued row was dropped as "missing locally" and the
  payload destroyed. The consumer now exists: `SyncEngine._processOne`
  dispatches `kind: youtube_upload` payloads (entity `video`, non-delete
  action) directly to `YoutubeTranscriptsClient.uploadTranscript` — success
  clears the row; failure reuses the queue's shared `SyncRetryPolicy`
  threshold / exponential-backoff machinery (issue #752). The producer also
  switched from a plain insert to `SyncQueueRepository.addOrUpsert` so
  repeated failures of the same `videoId/language` refresh one row instead of
  stacking duplicates.
- **2026-09-24 (issue #749)**: the producer no longer constructs
  `SyncQueueRepository` directly — it hands the pre-built
  `SyncYoutubeUploadRetry` to the widened typed enqueue seam (the job-shaped
  `syncEnqueueJobProvider` entry beside `syncEnqueueProvider`). The seam runs
  the same `addJob` dedup contract and, **when signed in, schedules an
  immediate queue drain**, so a failed worker upload retries as soon as the
  enqueue lands instead of waiting up to 5 minutes for decision 3's periodic
  `SyncCtrl` drain (that timer is now only the fallback). The retry-handling
  contract (throw-on-false + payload-match conditional remove) moved from
  `SyncEngine` into `SyncYoutubeUploadRetry.processRetry`, with the expected
  payload derived from `encode()` — whose byte stability is documented and
  tested. The wire shape pinned by decision 3 and the 2026-09-16 amendment is
  unchanged, byte-for-byte.