# Tasks: Client-Side YouTube Transcript Fetching

**Input**: Design documents from `/specs/013-client-yt-transcripts/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are required per constitution II. Each test file should be written first and verified to FAIL before implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `lib/features/transcript/{application,data,domain,presentation}/`
- **Shared code**: `lib/core/`, `lib/data/`
- **Tests**: `test/features/transcript/`, `test/data/api/services/ai/`
- **Feature docs**: `docs/features/youtube.md`, `docs/features/transcript.md`
- **ADRs**: `docs/decisions/0043-client-youtube-transcripts.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create new files and confirm target paths exist

- [ ] T001 Create project scaffolding per implementation plan — verify directories `lib/features/transcript/data/`, `lib/features/transcript/application/`, `lib/core/utils/`, `test/features/transcript/data/`, `test/features/transcript/application/` all exist
- [ ] T002 [P] Add `youtube.client_profiles_v1` settings key constant in `lib/data/db/settings_keys.dart`
- [ ] T003 [P] Identify affected docs (`docs/features/youtube.md`, `docs/features/transcript.md`) and ADR target (`docs/decisions/0043-client-youtube-transcripts.md`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 [P] Create HTML cleaning utilities (`htmlDecode`, `stripTags`) in `lib/core/utils/html_clean.dart` using `dart:convert` `HtmlUnescape` + `RegExp(r'<[^>]*>')`
- [ ] T005 [P] Create unit tests for HTML cleaning utilities in `test/core/utils/html_clean_test.dart`
- [ ] T006 [P] Create `ClientProfile` model with built-in default profiles (ios, android_vr, mweb) in `lib/features/transcript/data/client_profile.dart`
- [ ] T007 [P] Create `ClientProfile` unit tests (JSON decode, validation) in `test/features/transcript/data/client_profile_test.dart`
- [ ] T008 [P] Extend `YoutubeTranscriptsClient` interface with `getCachedTranscript`, `uploadTranscript`, and `fetchClientProfiles` methods in `lib/data/api/services/ai/youtube_transcripts_api.dart`
- [ ] T009 [P] Update `YoutubeTranscriptsApi` to add `getCachedTranscript` (GET `/youtube/transcripts?videoId=…&language=…`), `uploadTranscript` (POST `/youtube/transcripts` upload), and `fetchClientProfiles` (GET `/youtube/client-profiles`) method implementations in `lib/data/api/services/ai/youtube_transcripts_api.dart`
- [ ] T010 [P] Add unit tests for new `YoutubeTranscriptsApi` methods (GET cache, POST upload, GET profiles) in `test/data/api/services/ai/youtube_transcripts_api_test.dart`
- [ ] T011 [P] Add new settings key `youtube.client_profiles_v1` constant in `lib/data/db/settings_keys.dart` (if not done in T002, verify it exists)

**Checkpoint**: Foundation ready — HTML cleaning, client profiles, and extended API client are available for all user stories

---

## Phase 3: User Story 1 - Direct Client-Side Transcript Fetch (Priority: P1) 🎯 MVP

**Goal**: User opens a YouTube video; the app fetches captions directly from YouTube's InnerTube API (bypassing worker) and displays them in the transcript panel.

**Independent Test**: Import a YouTube video with known captions (e.g., `dQw4w9WgXcQ`), open it, and observer transcript lines appear within 5 seconds sourced directly from YouTube.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T012 [P] [US1] Create unit tests for `YoutubeCaptionFetcher` covering: InnerTube POST + response parsing, client profile fallback (ios → android_vr → mweb), caption track selection (manual > auto > code match > first available), json3 parsing, entity decode + tag stripping, empty tracks, HTTP errors, all-profiles-fail in `test/features/transcript/data/youtube_caption_fetcher_test.dart`
- [ ] T013 [P] [US1] Create unit tests for transcript timeline parse extension — json3 format parsing into `TranscriptLine` list with correct startMs/durationMs/text in `test/features/transcript/data/transcript_timeline_parse_test.dart`
- [ ] T014 [US1] Create unit tests for `TranscriptRepository._fetchYoutubeDirect()` method: successful fetch → upsert, empty caption tracks → empty result, fetch error → error result, auto-generated vs official source labeling in `test/features/transcript/transcript_repository_direct_fetch_test.dart`

### Implementation for User Story 1

- [ ] T015 [P] [US1] Create `CaptionTrack` and `CaptionFetchResult` transient models in `lib/features/transcript/data/youtube_caption_fetcher.dart`
- [ ] T016 [US1] Implement `YoutubeCaptionFetcher` class: `fetchSubtitles(videoId, language, profiles)` method that POSTs to InnerTube API with each profile in sequence, parses caption tracks, selects best match, GETs json3 data, parses segments in `lib/features/transcript/data/youtube_caption_fetcher.dart` (depends on T015)
- [ ] T017 [P] [US1] Add json3 format parsing support alongside existing worker timeline parser in `lib/features/transcript/data/transcript_timeline_parse.dart`
- [ ] T018 [US1] Add `_fetchYoutubeDirect()` method to `TranscriptRepository` that calls `YoutubeCaptionFetcher.fetchSubtitles()`, normalizes source label, generates transcript ID via `enjoyTranscriptId()`, upserts via `transcriptDao`, and sets primary transcript in `lib/features/transcript/data/transcript_repository.dart` (depends on T016, T017)
- [ ] T019 [US1] Wire `YoutubeCaptionFetcher` into `TranscriptRepository` constructor (optional parameter, default constructed with built-in profiles) and update `TranscriptRepository` provider in `lib/features/transcript/application/transcript_repository_provider.dart`
- [ ] T020 [US1] Add `fetchSource` tracking to domain model — extend `TranscriptCloudFetchResult` or add companion field to distinguish `local`/`worker`/`directYoutube` source in `lib/features/transcript/domain/transcript_fetch_status.dart`
- [ ] T021 [US1] Add localization strings for new transcript states ("no transcript available", "retry") to ARB files under `lib/core/localization/`
- [ ] T022 [US1] Verify performance: ensure json3 parsing for 5000+ lines uses `compute()` (background isolate) and does not block UI thread

**Checkpoint**: At this point, User Story 1 should be fully functional — opening a YouTube video triggers a direct fetch that stores and displays captions. Test independently by running `flutter test test/features/transcript/data/youtube_caption_fetcher_test.dart` and verifying all pass.

---

## Phase 4: User Story 2 - Worker Re-Designed as Caching Layer (Priority: P2)

**Goal**: Worker serves cached transcripts via GET, client uploads directly-fetched transcripts for caching, and worker provides remotely configurable client profiles.

**Independent Test**: Fetch a transcript directly (US1 path), confirm it's uploaded to the worker. Open the same video on a second device — worker GET returns the cached transcript.

### Tests for User Story 2

- [ ] T023 [P] [US2] Create unit tests for `ClientProfileProvider`: fetch from worker → cache in settings, built-in fallback when worker unreachable, periodic refresh (24h), cache hit within refresh window in `test/features/transcript/application/client_profile_provider_test.dart`
- [ ] T024 [P] [US2] Create unit tests for upload flow: upload called after successful direct fetch, upload NOT called after local cache hit, upload failure does not block transcript display, upload idempotency (409 treated as success) in `test/features/transcript/transcript_repository_upload_test.dart`
- [ ] T025 [US2] Create unit tests for worker GET cache lookup: cache hit returns transcript, cache miss (404) returns null, worker unreachable (network error) returns error result in `test/features/transcript/transcript_repository_worker_cache_test.dart`

### Implementation for User Story 2

- [ ] T026 [US2] Implement `ClientProfileProvider` Riverpod provider: fetches from worker `GET /youtube/client-profiles` at startup and every 24h, caches JSON in Drift settings under `youtube.client_profiles_v1`, falls back to cached then built-in defaults on failure in `lib/features/transcript/application/client_profile_provider.dart`
- [ ] T027 [US2] Register `clientProfileProvider` and wire into `YoutubeCaptionFetcher` so it uses remotely-configured profiles instead of only built-in defaults, updating `lib/features/transcript/data/youtube_caption_fetcher.dart` and `lib/features/transcript/application/transcript_repository_provider.dart`
- [ ] T028 [US2] Add `_fetchWorkerCachedTranscript()` method to `TranscriptRepository` that calls `YoutubeTranscriptsClient.getCachedTranscript()` and converts the response to the same internal format as direct fetch. Returns null on cache miss (404) in `lib/features/transcript/data/transcript_repository.dart`
- [ ] T029 [US2] Implement async upload flow in `TranscriptRepository._uploadToWorkerIfNeeded()`: called after a successful direct fetch, wraps `YoutubeTranscriptsClient.uploadTranscript()` in a fire-and-forget (unawaited, try-catch), uploads the stored transcript's timeline + metadata in `lib/features/transcript/data/transcript_repository.dart`
- [ ] T030 [US2] Register updated providers in `lib/data/api/services/ai/ai_api_providers.dart` if needed for new `YoutubeTranscriptsApi` methods

**Checkpoint**: At this point, User Stories 1 AND 2 should both work — transcripts are cached on the worker and client profiles update remotely.

---

## Phase 5: User Story 3 - Resilient Fallback Chain (Priority: P3)

**Goal**: The app orchestrates a seamless priority chain (local → worker GET → direct YouTube) and handles all edge cases gracefully, including bilingual transcripts and exhausted sources.

**Independent Test**: Clear local data, mock worker to return 404, mock InnerTube to return valid data — the user sees transcripts without any indication of which path was used.

### Tests for User Story 3

- [ ] T031 [P] [US3] Create unit tests for fallback chain: local hit skips network, worker hit after local miss, direct fetch after worker miss, chain short-circuits on success (doesn't try later tiers), exhausted chain shows empty state in `test/features/transcript/transcript_repository_fallback_test.dart`
- [ ] T032 [P] [US3] Create unit tests for `TranscriptFetchCtrl.resolveOnOpen()` with new chain: hydrated from persisted state, resolves through chain, maps result to UI state correctly for each tier in `test/features/transcript/transcript_fetch_controller_test.dart`
- [ ] T033 [US3] Create unit tests for bilingual handling with direct fetch: original language caption fetched, translation left pending (not error), native==source skips bilingual in `test/features/transcript/transcript_repository_bilingual_direct_test.dart`

### Implementation for User Story 3

- [ ] T034 [US3] Refactor `TranscriptRepository.fetchCloudTranscripts()` to implement the three-tier fallback chain: check local → call `_fetchWorkerCachedTranscript()` → call `_fetchYoutubeDirect()` — each tier only tried if previous returns "no data" (not error). On direct fetch success, call `_uploadToWorkerIfNeeded()` in `lib/features/transcript/data/transcript_repository.dart`
- [ ] T035 [US3] Update `TranscriptFetchCtrl.resolveOnOpen()` to work with the new chain: remove old polling-based worker logic, wire the new fallback flow, ensure `_persistFetchOutcome` correctly records which source succeeded in `lib/features/transcript/application/transcript_fetch_controller.dart`
- [ ] T036 [US3] Implement timeout guard for the full fallback chain (15s total, per QR-005) — if the chain hasn't resolved, surface a timeout state and cancel in-flight requests in `lib/features/transcript/data/transcript_repository.dart`
- [ ] T037 [US3] Implement "no transcript available" UI state with retry action — update `TranscriptFetchUiState` and existing transcript panel widgets to show clear empty state with retry button in `lib/features/transcript/domain/transcript_fetch_status.dart` and `lib/features/transcript/presentation/`
- [ ] T038 [US3] Handle bilingual transcript case in the direct fetch path: when native language differs from content language, fetch only original captions, mark secondary translation slot as pending (do NOT error), ensure the separate translation service fills it later in `lib/features/transcript/data/transcript_repository.dart`
- [ ] T039 [US3] Add `package:logging` instrumentation (`logNamed('YoutubeCaptionFetcher')` etc.) to all new code paths using `_log` pattern from existing code — no `print()` calls

**Checkpoint**: All three user stories fully integrated — the fallback chain works seamlessly end-to-end.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, verification, and final quality gates

- [ ] T040 [P] Update `docs/features/youtube.md` — document the new client-side fetch flow, worker cache redesign, and profile configuration
- [ ] T041 [P] Update `docs/features/transcript.md` — add direct fetch as a transcript source, document the fallback chain
- [ ] T042 [P] Create ADR-0043 in `docs/decisions/0043-client-youtube-transcripts.md` recording the architectural decision to move transcript fetching client-side, the fallback chain design, and the worker cache redesign
- [ ] T043 Run `dart run build_runner build` if any Drift or Riverpod annotations were modified (e.g., new providers, settings keys)
- [ ] T044 Run `flutter analyze` and fix all warnings/errors
- [ ] T045 Run `flutter test` — all existing and new tests pass
- [ ] T046 Run `bash .github/scripts/validate_ci_gates.sh` and fix any format or codegen drift issues
- [ ] T047 Verify quickstart.md validation scenarios — run through each of the 7 scenarios manually or via test

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational — builds direct fetch capability
- **User Story 2 (Phase 4)**: Depends on Foundational — can start in parallel with US1 but US2 integration tasks (T027, T034) need US1's fetcher available
- **User Story 3 (Phase 5)**: Depends on US1 and US2 completion — orchestrates them together
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2). No dependencies on other stories.
- **User Story 2 (P2)**: Tests (T023-T025) and most implementation (T026, T028-T030) can start after Foundational. Only T027 (wire profiles to fetcher) needs US1's `YoutubeCaptionFetcher` available.
- **User Story 3 (P3)**: Requires both US1 and US2 complete — orchestrates the full chain.

### Within Each User Story

- Tests MUST be written FIRST and verified to FAIL before implementation
- Models before services (T015 before T016)
- Core implementation before integration (T016-T019 before T020-T022)
- Story complete before moving to next priority

### Parallel Opportunities

- **Phase 2**: T004, T005, T006, T007, T008, T009, T010, T011 are ALL marked [P] — can run in parallel
- **Phase 3 tests**: T012, T013 can run in parallel
- **Phase 3 implementation**: T015 and T017 can run in parallel (different files)
- **Phase 4 tests**: T023, T024 can run in parallel
- **Phase 5 tests**: T031, T032 can run in parallel
- **Phase 6**: T040, T041, T042 can run in parallel (different docs files)

---

## Parallel Example: User Story 1

```bash
# Step 1: Launch all tests for US1 together (they MUST fail initially):
Task: T012 "Unit tests for YoutubeCaptionFetcher in test/features/transcript/data/youtube_caption_fetcher_test.dart"
Task: T013 "Unit tests for transcript timeline parse in test/features/transcript/data/transcript_timeline_parse_test.dart"

# Step 2: Launch independent models together:
Task: T015 "Create CaptionTrack and CaptionFetchResult models in lib/features/transcript/data/youtube_caption_fetcher.dart"
Task: T017 "Add json3 format parsing in lib/features/transcript/data/transcript_timeline_parse.dart"

# Step 3: Core implementation (depends on T015):
Task: T016 "Implement YoutubeCaptionFetcher class in lib/features/transcript/data/youtube_caption_fetcher.dart"

# Step 4: Integration (depends on T016, T017):
Task: T014 "Unit tests for TranscriptRepository._fetchYoutubeDirect()"
Task: T018 "Add _fetchYoutubeDirect() to TranscriptRepository"
```

---

## Parallel Example: Phase 2 (Foundational)

```bash
# All of these run in parallel — different files, no dependencies:
Task: T004 "HTML cleaning utilities in lib/core/utils/html_clean.dart"
Task: T005 "HTML cleaning tests in test/core/utils/html_clean_test.dart"
Task: T006 "ClientProfile model in lib/features/transcript/data/client_profile.dart"
Task: T007 "ClientProfile tests in test/features/transcript/data/client_profile_test.dart"
Task: T008 "Extend YoutubeTranscriptsClient interface"
Task: T009 "Implement new YoutubeTranscriptsApi methods"
Task: T010 "Tests for new YoutubeTranscriptsApi methods"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T011) — CRITICAL, blocks all stories
3. Complete Phase 3: User Story 1 (T012-T022)
4. **STOP and VALIDATE**: Open a YouTube video, verify transcript appears via direct fetch
5. Run `flutter test test/features/transcript/data/youtube_caption_fetcher_test.dart`
6. Deploy/demo if ready — this alone delivers the core value of eliminating server dependency

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 → Direct fetch works independently → **MVP!**
3. Add User Story 2 → Worker caching and profile refresh → cross-device cache sharing
4. Add User Story 3 → Seamless fallback chain → polished user experience
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (T001-T011)
2. Once Foundational is done:
   - Developer A: User Story 1 — direct fetch core (T012-T022)
   - Developer B: User Story 2 tests + implementation (T023-T030, except T027 which needs US1)
   - Developer C: Prepare docs (T040-T042) and localization (T021)
3. Developer B integrates T027 after US1 is stable
4. Team completes User Story 3 together (or one developer)
5. Polish phase: shared verification (T043-T047)

---

## Notes

- [P] tasks = different files, no dependencies — launch in parallel
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Tests MUST be written first, verified to FAIL, then implementation makes them pass
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- **No `print()`** — use `logNamed` (per conventions.md and constitution)
- **No `media_kit` Player** creation outside the player engine/controller
- **YouTube client profile versions** must track yt-dlp's recent commits for accuracy
- **Worker API endpoints** are defined in contracts/worker-cache-api.md — server-side implementation coordinated separately
