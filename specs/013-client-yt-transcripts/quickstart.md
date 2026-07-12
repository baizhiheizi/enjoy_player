# Quickstart: Client-Side YouTube Transcript Fetching

**Feature**: [spec.md](spec.md) | **Date**: 2026-07-12

## Prerequisites

- Dev environment set up per `README.md`
- Flutter stable, all platform toolchains
- Worker API running locally or staging accessible

## Verification Scenarios

### 1. Direct Fetch — Happy Path

**Objective**: Prove the client can fetch YouTube captions directly without worker involvement.

**Steps**:
1. Launch the app signed in.
2. Import a YouTube video with known captions (e.g., `dQw4w9WgXcQ`).
3. Open the video.
4. Observe the transcript panel.

**Expected outcome**:
- Transcript lines appear within 5 seconds of video open.
- Each line has text, start time, and duration.
- The track source shows `"official"` or `"auto"` matching the caption kind.

**Test command**: Widget test covering `YoutubeCaptionFetcher` → `TranscriptRepository` integration with a mock HTTP client returning canned InnerTube + json3 responses.

---

### 2. Worker Cache Hit

**Objective**: Prove the worker GET returns cached transcripts when available.

**Steps**:
1. Seed a transcript in the worker cache for a known video+language.
2. Clear local transcript data for that video.
3. Open the video in the app.

**Expected outcome**:
- Transcript loads from worker within 2 seconds.
- Same display as direct fetch — source attribution may differ.

**Test command**: Unit test with `_CapturingYoutubeClient` returning a cache-hit response, asserting no direct YouTube call is made.

---

### 3. Fallback Chain — Worker Miss → Direct Success

**Objective**: Prove the app falls back correctly when the worker has no cache.

**Steps**:
1. Ensure the worker has no cached transcript for a test video.
2. Clear local transcript data.
3. Open the video.

**Expected outcome**:
- Worker GET returns 404.
- App silently falls back to direct YouTube fetch.
- Transcript appears (no user-visible error or intermediate loading state change).
- After success, the transcript is persisted locally.

**Test command**: Unit test: mock worker GET returning 404, mock InnerTube returning valid data, assert transcript stored.

---

### 4. All Paths Exhausted

**Objective**: Prove graceful degradation when no source has the transcript.

**Steps**:
1. Clear local data.
2. Mock worker GET to return 404.
3. Mock InnerTube to return a response with no `captionTracks` (or all profiles fail).

**Expected outcome**:
- App shows "no transcript available" message.
- Option to retry is visible.
- No crash, no infinite spinner.

**Test command**: Unit test: all sources return empty/error, assert `TranscriptFetchUiState.status == TranscriptFetchStatus.empty`.

---

### 5. Upload After Direct Fetch

**Objective**: Prove the client uploads transcript data to the worker after a successful direct fetch.

**Steps**:
1. Clear local data and worker cache.
2. Open a video that triggers a direct fetch.
3. Verify the upload POST is sent to the worker.

**Expected outcome**:
- Transcript displays immediately (does not wait for upload).
- Worker receives POST with correct videoId, language, source, and timeline.
- Upload occurs exactly once (not re-uploaded when re-opening the same video from local cache).

**Test command**: Unit test: spying on `YoutubeTranscriptsClient.uploadTranscript`, asserting it's called after a successful direct fetch but not after a local cache hit.

---

### 6. Client Profile Refresh

**Objective**: Prove the app fetches and caches client profiles from the worker.

**Steps**:
1. Start the app fresh (no cached profiles).
2. Verify `GET /youtube/client-profiles` is called.
3. Kill and restart the app.
4. Verify cached profiles are used (no network call if within refresh window).

**Expected outcome**:
- First launch: profiles fetched from worker and cached.
- Second launch (within 24h): cached profiles used, no network call.
- Third launch (after cache expiry): re-fetched from worker.
- Worker unreachable: built-in defaults used, profile fetching still works.

**Test command**: Unit test: mock worker profile endpoint, assert cache storage in Drift settings.

---

### 7. Platform Smoke Test

**Objective**: Verify the InnerTube HTTP calls work on all supported platforms.

**Steps**:
1. Build and launch the app on Android, iOS, macOS, and Windows.
2. On each platform, import and open the same test YouTube video.
3. Verify the transcript appears.

**Expected outcome**: Transcript fetches succeed on all four platforms with no TLS errors, timeout issues, or platform-specific HTTP quirks.

**Test command**: Manual verification on each platform (CI integration test where available).

---

## Key Files to Create/Modify

| File | Action |
|------|--------|
| `lib/features/transcript/data/youtube_caption_fetcher.dart` | New — direct YouTube InnerTube fetch logic |
| `lib/features/transcript/data/client_profile.dart` | New — profile model + built-in defaults |
| `lib/features/transcript/application/client_profile_provider.dart` | New — profile fetch/cache/refresh provider |
| `lib/data/api/services/ai/youtube_transcripts_api.dart` | Modify — add GET cache, upload, profile methods |
| `lib/features/transcript/data/transcript_repository.dart` | Modify — update `fetchCloudTranscripts` with fallback chain |
| `test/features/transcript/data/youtube_caption_fetcher_test.dart` | New — unit tests for InnerTube + json3 parsing |
| `test/features/transcript/transcript_repository_fallback_test.dart` | New — fallback chain unit tests |

## Run Verification Commands

```bash
flutter analyze
flutter test test/features/transcript/
dart run build_runner build         # if Drift/Riverpod annotations change
bash .github/scripts/validate_ci_gates.sh
```
