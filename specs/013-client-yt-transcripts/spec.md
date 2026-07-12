# Feature Specification: Client-Side YouTube Transcript Fetching

**Feature Branch**: `013-client-yt-transcripts`

**Created**: 2026-07-12

**Status**: Draft

**Input**: User description: "Let's implement the caption fetching in client-side. And we should design it well, it lives in client, we should make the client profile version strings configurable, like from worker's API. Also we might re-design the worker API. The full flow should be: 1. open YT video; 2. fetch the transcripts from worker API (GET only); 3. if no response from worker API, use the client-side fetching; 4. if success, upload the captions to the worker API for caching; The translation API is separate, no changed."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Direct client-side transcript fetch (Priority: P1)

When a learner opens a YouTube video, the app attempts to fetch the transcript directly from YouTube's servers without waiting for a server-side worker to process and deliver it. The transcript appears alongside the video in the transcript panel, with the original language caption selected as primary.

**Why this priority**: This is the core architectural shift — removing the mandatory server-side dependency for transcript retrieval. It eliminates server polling latency, reduces worker load, and gives users a faster transcript experience even when the worker is unavailable.

**Independent Test**: Open any public YouTube video that has captions. The transcript panel populates with timestamped caption lines fetched directly by the client, without relying on the worker's poll-based delivery. The transcript renders correctly in the transcript panel and tracks playback position.

**Acceptance Scenarios**:

1. **Given** a YouTube video with available captions in the video's content language, **When** the user opens the video, **Then** the app fetches the caption track directly from YouTube and displays it in the transcript panel within 5 seconds of video open.
2. **Given** a YouTube video with captions available in multiple languages, **When** the app fetches captions, **Then** the track matching the video's content language is selected as the primary transcript.
3. **Given** a YouTube video whose captions are auto-generated (not manually uploaded), **When** the app fetches captions, **Then** the auto-generated track is returned and marked with the appropriate source label.
4. **Given** the app has already fetched captions for a video, **When** the user reopens the same video, **Then** stored captions from local persistence are displayed immediately without re-fetching.
5. **Given** the user opens a video while offline, **When** a prior fetch has stored captions locally, **Then** the stored captions are shown; when no stored captions exist, the app shows a clear "no transcript available" state rather than an indefinite loading indicator.

---

### User Story 2 - Worker re-designed as a caching layer (Priority: P2)

The worker API is redesigned to be a simple GET-based cache: when a transcript is requested, the worker returns previously cached results if available. If the client successfully fetches a transcript directly that the worker did not have, the client uploads it so future clients (or the same client on a different device) benefit from the cached result. The worker also serves client profile version strings so the app can stay current with YouTube's changing API without an app update.

**Why this priority**: This ensures the worker continues to add value (caching, profile config) while the client-side path handles the primary fetch. It also future-proofs the client-side implementation by making the YouTube client versions remotely configurable.

**Independent Test**: Open a YouTube video on device A (which performs a direct client-side fetch). The app uploads the transcript to the worker. Then open the same video on device B — the worker cache returns the transcript without device B needing to hit YouTube directly.

**Acceptance Scenarios**:

1. **Given** a video whose transcript is cached on the worker, **When** a client requests it via GET, **Then** the worker returns the cached transcript within 2 seconds.
2. **Given** a successful client-side direct fetch, **When** the transcript is stored locally, **Then** the client uploads it to the worker asynchronously (non-blocking, best-effort) so future fetches can hit the cache.
3. **Given** the client needs client profile version strings (YouTube client names, versions, user agents), **When** the app starts or periodically refreshes, **Then** it fetches the latest profile configuration from the worker.
4. **Given** the worker profile config is unreachable, **When** the app starts, **Then** it falls back to a built-in set of client profile versions so transcript fetching still works.
5. **Given** the client uploads a transcript to the worker, **When** the upload succeeds, **Then** the worker stores it keyed by video ID and language so subsequent GET requests return it without re-scraping YouTube.

---

### User Story 3 - Resilient fallback chain (Priority: P3)

The app orchestrates multiple transcript sources in a priority chain: locally stored > worker cache > client-side direct fetch. The user never sees the complexity of this chain — they simply get the fastest available transcript. When the primary fallback succeeds, the app uploads results upward (to worker cache) to improve the experience for future sessions.

**Why this priority**: This ties P1 and P2 together into a seamless experience. Without it, the user must understand which path succeeded or failed. With it, transcript retrieval is a single "just works" behavior.

**Independent Test**: Disable the worker connection (or use a video the worker hasn't cached). The app falls back to direct client-side fetch transparently. The user sees the transcript appear without any indication of which path was used.

**Acceptance Scenarios**:

1. **Given** locally stored transcripts exist for a video, **When** the user opens the video, **Then** local transcripts are displayed immediately, and no network request for transcripts is made (or a background refresh skips if local data is fresh).
2. **Given** no local transcripts exist and the worker has a cached transcript, **When** the user opens the video, **Then** the transcript is fetched from the worker via GET and displayed.
3. **Given** neither local nor worker transcripts exist, **When** the user opens the video, **Then** the client fetches directly from YouTube and displays the result.
4. **Given** the client-side direct fetch also fails (video unavailable, no captions, network error), **When** all paths are exhausted, **Then** the app shows a clear "no transcript available" message with an option to retry.
5. **Given** a bilingual transcript is needed (original language + native translation), **When** the direct client fetch returns only the original captions, **Then** the app still displays the original captions and marks the translation as pending (to be filled by the separate translation service).

---

### Edge Cases

- What happens when YouTube's InnerTube API rejects the client request (rate limiting, bot detection)? The app should try the next client profile in its fallback list and, if all profiles fail, log the failure and fall through to the next source.
- What happens when the video ID is valid but the video has no captions at all? The app detects the empty caption track list from the API response and treats it as "no captions available" (not an error).
- What happens with region-restricted videos? The client's IP determines access; the same fallback chain applies. If all client profiles fail due to region locks, the app surfaces "video not accessible."
- What happens with very long transcripts (multi-hour videos)? The fetch retrieves all segments; the transcript panel uses existing pagination/virtualization to handle large line counts without jank.
- How does the app handle the worker being completely unreachable (network down, service outage)? The client-side direct path becomes the only network path; the app degrades gracefully with no worker-dependent features broken.
- What about bilingual transcripts when only the original is available via direct fetch? The original is stored and shown; the translation slot remains empty until the separate translation service provides it.
- How does the client handle profile version drift (YouTube changes API, current versions stop working)? The worker pushes updated profiles; if the worker is also unreachable, the built-in defaults provide a baseline until an app update ships newer versions.
- What about platform differences (Android, iOS, macOS, Windows) in HTTP client behavior? The client-side fetch uses standard HTTP libraries available on all supported platforms; any platform-specific headers or TLS behavior must be verified across all targets.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST support fetching YouTube captions directly from YouTube's servers without routing through any intermediate server-side service.
- **FR-002**: The direct caption fetch MUST attempt multiple YouTube client profiles (spoofing different device types) in sequence, using the first successful response with caption tracks.
- **FR-003**: The set of client profiles (client name, version, user agent, device context) MUST be remotely configurable via a configuration endpoint on the worker, with built-in defaults as fallback.
- **FR-004**: The app MUST select the best matching caption track for the video's content language, preferring manual captions over auto-generated, and exact language matches over partial matches.
- **FR-005**: The app MUST persist fetched caption data locally so re-opening the same video shows transcripts immediately without re-fetching.
- **FR-006**: The worker API MUST be redesigned to serve transcripts via GET (read-only cache lookup), accepting video ID and language as parameters.
- **FR-007**: The app MUST upload successfully fetched transcripts to the worker (best-effort, non-blocking) so the worker can serve them to future requests.
- **FR-008**: When fetching transcripts, the app MUST follow a priority chain: local persistence → worker cache GET → client-side direct fetch.
- **FR-009**: The app MUST handle the bilingual transcript case: when the learner's native language differs from the video's content language, the direct fetch obtains the original captions; translation remains handled by the separate translation service.
- **FR-010**: The app MUST surface a clear "no transcript available" state when all fetch paths are exhausted, with an option to retry.
- **FR-011**: Transcript upload to the worker MUST be asynchronous and best-effort — upload failures must not block the user from viewing the locally stored transcript.
- **FR-012**: The worker's profile configuration endpoint MUST return the current set of YouTube client profiles (name, version, user agent, context fields) so the app can stay compatible without requiring an app update.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture under `lib/features/transcript/` and not introduce cross-feature shortcuts.
- **QR-002**: Changed behavior MUST have automated tests covering the direct fetch parser, client profile fallback logic, cache priority chain, and upload flow.
- **QR-003**: User-facing strings for transcript status (loading, unavailable, retry) MUST follow existing localization patterns and use ARB files.
- **QR-004**: Direct transcript fetch MUST complete within 5 seconds for the common case (video with readily available captions, good network).
- **QR-005**: The fallback chain (local → worker → direct) MUST resolve to a result within 15 seconds or surface a timeout state, never leaving an indefinite loading indicator.
- **QR-006**: Feature behavior changes MUST update `docs/features/youtube.md` and `docs/features/transcript.md`.
- **QR-007**: Performance MUST remain acceptable for transcripts with 5,000+ lines — the parse and persist path must not block the UI thread.

### Key Entities

- **Client Profile**: A configuration record describing how to impersonate a YouTube client: client name, version string, user agent header, client name header value, and device context (platform, OS version, device model). These are versioned and fetched from the worker.
- **Caption Track**: A specific subtitle track available for a YouTube video, identified by language code, track kind (manual/auto-generated), and a base URL for fetching the timed text data.
- **Timed Caption Segment**: A single subtitle unit with start time, duration, and decoded text content, produced by parsing the raw YouTube caption format.
- **Transcript Fetch Result**: The outcome of a transcript retrieval attempt from any source, carrying status (success, empty, error), the source identifier (local, worker, direct), parsed segments, and metadata about the track (language, kind).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 90% of YouTube video opens with available captions display transcripts within 5 seconds of video load (measured from play start to first transcript line visible).
- **SC-002**: The client-side direct fetch path succeeds for at least 95% of videos with public captions when the same video works in the `youtube-caption-extractor` reference library.
- **SC-003**: Transcript upload to the worker completes within 10 seconds for videos with up to 2,000 caption lines, and does not block transcript display to the user.
- **SC-004**: Opening a previously fetched video shows stored transcripts in under 500ms (no network round-trip).
- **SC-005**: The fallback chain correctly transitions through all three sources (local → worker → direct) without user-visible errors or redundant fetches when prior sources return empty or error.
- **SC-006**: 100% of new user-facing text in this feature is localized and exposed through the ARB localization system.

## Assumptions

- YouTube's InnerTube API (`youtubei.googleapis.com`) remains publicly accessible without authentication for caption metadata and timed text data. If YouTube locks this down, the client-side path breaks and requires an app update or worker-side fallback.
- The separate translation service (for producing native-language translations of captions) continues to operate independently and is not changed by this feature.
- The learner's content language for a YouTube video is already known at import time and stored on the video row; this feature does not change the language selection flow.
- The worker's new GET endpoint for cached transcripts is implemented server-side in coordination with this client-side work; the API contract is defined as part of this feature's design phase.
- Built-in client profile defaults are sufficient as a cold-start fallback when the worker is unreachable; these defaults may lag behind YouTube's latest requirements but provide baseline functionality.
- All four supported platforms (Android, iOS, macOS, Windows) have equivalent HTTP client capabilities for the POST to InnerTube and GET for caption track data. Platform-specific proxies or TLS configurations are out of scope for v1.
