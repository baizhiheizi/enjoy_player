---
description: "Task list for InnerTube channel discover (InnerTube primary + RSS fallback)"
---

# Tasks: InnerTube Channel Discover

**Input**: Design documents from `/specs/017-innertube-channel-discover/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/discover-repository-contract.md, contracts/youtube-browse-client-contract.md, quickstart.md

**Tests**: Automated tests are required for changed behavior (QR-002 in plan.md, SC-006 in spec.md). Tests are written first (Phase 2 parser tests, then per-user-story repository tests) and must fail before the implementation that satisfies them lands.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `lib/features/discover/{application,data,domain,presentation}/`
- **Shared code**: `lib/features/transcript/data/` (ClientProfile), `lib/core/logging/log.dart`
- **Tests**: `test/features/discover/`
- **Feature docs**: `docs/features/discover.md`
- **ADRs**: `docs/decisions/NNNN-short-title.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the change surface and that the working tree starts in a known-good state before any code edits.

- [X] T001 Confirm baseline: `flutter test test/features/discover/` passes on the current working tree (record the passing test count so the post-change comparison is unambiguous).
- [X] T002 [P] Re-read `lib/features/discover/data/discover_repository.dart` `_refreshChannel` and note the exact line range covering the RSS fetch, the parse step, the upsert loop, `_enrichMissingDurations`, the display-name update, and `touchLastFetched` — these are the touch points the dual-source edit will rewrite.
- [X] T003 [P] Re-read `lib/features/transcript/data/youtube_caption_fetcher.dart` lines 18–19 and 200–251 to confirm the InnerTube POST header pattern, the JSON body shape, the retry-with-rotation ladder, and the `logNamed` channel naming — `YoutubeBrowseClient` will mirror this posture exactly.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add the InnerTube client profile, the new `YoutubeBrowseClient` collaborator, and its pure parser — with tests written and **failing** before the implementation lands. No user story work begins until these are present and green.

**⚠️ CRITICAL**: Phase 3+ work cannot begin until this phase is complete.

- [X] T004 [P] Add a fourth built-in entry to `kBuiltInClientProfiles` in `lib/features/transcript/data/client_profile.dart`: `name: 'web'`, `clientName: 'WEB'`, `clientNameHeader: '1'`, a current `clientVersion` (e.g., `'2.20240101.00.00'`), a desktop Chrome user agent, and a context map with `platform: 'DESKTOP'`, `osName: 'Windows'`, `osVersion: '10.0'`. Keep the existing three entries unchanged.
- [X] T005 [P] Add unit test "browse client: parses one-page InnerTube response into BrowseVideoEntry list" to a new `test/features/discover/youtube_browse_client_test.dart`. The test feeds a canned JSON response with three `videoRenderer` entries (each carrying `videoId`, `title`, `thumbnail.thumbnails[0].url`, `lengthText.simpleText`, `publishedTimeText.simpleText`, `viewCountText.simpleText`) and asserts the three `BrowseVideoEntry` projections carry the right fields (including parsed `durationSeconds` and `publishedAt`).
- [X] T006 [P] Add unit test "browse client: follows continuation token across 3 pages" to `test/features/discover/youtube_browse_client_test.dart`. The mock client returns page 1 (30 entries + continuation token), page 2 (30 entries + continuation token), page 3 (0 entries). Assert `entries.length == 60`, `pagesFetched == 3`, `exhaustedPages == false`.
- [X] T007 [P] Add unit test "browse client: honors `maxPages` and reports `exhaustedPages`" to `test/features/discover/youtube_browse_client_test.dart`. Configure the mock to return a continuation token on every one of 7 pages; call `fetchChannelVideos(maxPages: 5)`; assert `pagesFetched == 5`, `exhaustedPages == true`, `entries.length == 150`.
- [X] T008 [P] Add unit test "browse client: empty response returns empty list without throwing" to `test/features/discover/youtube_browse_client_test.dart`. The mock returns a `200` with a `richGridRenderer.contents: []` body. Assert `entries.isEmpty`, `pagesFetched == 1`, `exhaustedPages == false`.
- [X] T009 [P] Add unit test "browse client: missing richGridRenderer throws YoutubeBrowseException" to `test/features/discover/youtube_browse_client_test.dart`. The mock returns a `200` whose body has no `richGridRenderer` / `richItemRenderer` (shape drift / deleted channel). Assert the call throws `YoutubeBrowseException` with a message containing `"no videos"`.
- [X] T010 [P] Add unit test "browse client: per-profile retry on 401 — retries next profile before throwing" to `test/features/discover/youtube_browse_client_test.dart`. The mock returns `401` for `WEB`, then `401` for `MWEB`, then `200` with a valid 1-entry response for the fallback profile in the second iteration of `MWEB` (after a 401-retry signal). Assert the call succeeds with 1 entry; assert the request list is `[profile=web → 401, profile=mweb → success]`.
- [X] T011 [P] Add unit test "browse client: all profiles 401 throws YoutubeBrowseException" to `test/features/discover/youtube_browse_client_test.dart`. The mock returns `401` for `WEB` and `MWEB`. Assert the call throws `YoutubeBrowseException` with `statusCode == 401`.
- [X] T012 [P] Add unit tests for the parsing helpers to `test/features/discover/youtube_browse_client_test.dart`:
  - `_parseInnerTubeLengthText` covers the table in `contracts/youtube-browse-client-contract.md`: `"1:23"` → `83`, `"12:34"` → `754`, `"1:02:03"` → `3723`, `"42"` → `42`, `""` → `null`, `"abc"` → `null`, `"0:00"` → `null`.
  - `_parseInnerTubePublishedTimeText(text, fetchedAt)` covers: `"3 days ago"` → `fetchedAt - 3d`, `"1 hour ago"` → `fetchedAt - 1h`, `"30 minutes ago"` → `fetchedAt - 30m`, `"2 weeks ago"` → `fetchedAt - 14d`, `"5 months ago"` → `fetchedAt - 150d`, `"1 year ago"` → `fetchedAt - 365d`, `"Streamed live 2 days ago"` → `fetchedAt - 2d`, `"Premiered 5 months ago"` → `fetchedAt - 150d`, `"unknown shape"` → `fetchedAt` (defensive fallback).
- [X] T013 Create `lib/features/discover/data/youtube_browse_client.dart` with: the `BrowseVideoEntry`, `BrowseFetchOutcome`, `YoutubeBrowseException` types (per `contracts/youtube-browse-client-contract.md`); the `YoutubeBrowseClient` class with `fetchChannelVideos` doing the per-profile retry + continuation loop + page cap; the response parser walking `richGridRenderer.contents[*].richItemRenderer.content.videoRenderer`; the top-level `_parseInnerTubeLengthText` and `_parseInnerTubePublishedTimeText` helpers; and `logNamed('discover.browse')` instrumentation (no `print()`). Use `http.MockClient`-friendly dependencies (`http.Client`, `List<ClientProfile>`, no globals). The constructor accepts `preferredProfileOrder` defaulting to `const ['web', 'mweb']` and `maxPages` defaulting to `5`.
- [X] T014 Wire `YoutubeBrowseClient` into `DiscoverRepository` in `lib/features/discover/data/discover_repository.dart`: add `YoutubeBrowseClient? browseClient` constructor argument; instantiate `browseClient ?? YoutubeBrowseClient(client: _client, profiles: <built-in list filtered to {web, mweb}>)` in the constructor body; no behavior change yet (the InnerTube branch is not called from `_refreshChannel`). Run `flutter test test/features/discover/` and confirm no regression.
- [X] T015 Re-run `flutter test test/features/discover/` and confirm: T005–T012 are all green; the existing dedupe / subscribe / dedupe tests still pass; total test count has grown by at least 8 (one per parser test). **No regression in existing tests.**

**Checkpoint**: Foundation ready — the parser, the per-profile retry ladder, the continuation loop, the page cap, and the parsing helpers all have green tests. The dual-source repository edit can now begin.

---

## Phase 3: User Story 1 — Channel refreshes succeed when the public RSS source is blocked (Priority: P1) 🎯 MVP

**Goal**: `DiscoverRepository._refreshChannel` calls `YoutubeBrowseClient.fetchChannelVideos` first; on a successful InnerTube response it writes the rows; on `YoutubeBrowseException` it falls back to the legacy `YoutubeRssParser` path. Either source's success counts; both failing leaves the cache and `lastFetchedAt` untouched.

**Independent Test**: With InnerTube stubbed to return a valid 1-page response of 5 entries, `refreshFeeds()` writes 5 rows and `failedChannelIds == []`. With InnerTube stubbed to 401 across all profiles and RSS stubbed to return 5 valid Atom entries, `refreshFeeds()` writes the 5 RSS rows and `failedChannelIds == []`. With both sources failing, `refreshFeeds()` reports the channel id in `failedChannelIds` and the cache is unchanged.

### Tests for User Story 1

- [X] T016 [P] [US1] Add unit test "InnerTube primary success writes rows from browse response" to `test/features/discover/discover_repository_test.dart`. Seed an empty cache; stub the InnerTube POST to return 5 entries with valid videoId/title/thumbnail/lengthText; run `refreshFeeds()`; assert the cache has 5 rows with the expected `(videoId, channelId, title, thumbnailUrl, durationSeconds)` for each, and `failedChannelIds == []`.
- [X] T017 [P] [US1] Add unit test "InnerTube failure falls back to RSS" to `test/features/discover/discover_repository_test.dart`. Seed an empty cache; stub InnerTube to 401 across all profiles (via `YoutubeBrowseClient` mock); stub RSS to return a valid 5-entry Atom feed; run `refreshFeeds()`; assert the cache has 5 rows from the RSS payload, `failedChannelIds == []`, and the channel's `lastFetchedAt` advanced.
- [X] T018 [P] [US1] Add unit test "dual failure preserves cache and lastFetchedAt" to `test/features/discover/discover_repository_test.dart`. Pre-seed 3 entries; record the channel's `lastFetchedAt`; stub InnerTube to 401 across all profiles; stub RSS to return HTTP 200 with a bot-block HTML body (`YoutubeRssParser.isValidFeedDocument` returns false); run `refreshFeeds()`; assert the channel id appears in `failedChannelIds`, the cache still has exactly 3 rows (unchanged), `lastFetchedAt` is unchanged, and **no** watch-page HTML fetch was issued.
- [X] T019 [P] [US1] Add unit test "YoutubeBrowseException caught in _refreshChannelGuarded" to `test/features/discover/discover_repository_test.dart`. Stub InnerTube to throw `YoutubeBrowseException("all profiles 401/403", statusCode: 401)` (transport-level failure); stub RSS to also throw; run `refreshFeeds()`; assert the channel id is in `failedChannelIds` and the failure is logged via `logNamed('discover.repository')` with a `warning` level (per FR-010 and contract C-2). **This test pins the exception-type contract for `_refreshChannelGuarded`.**

### Implementation for User Story 1

- [X] T020 [US1] In `lib/features/discover/data/discover_repository.dart` `_refreshChannel` (around lines 344–430), restructure the method into three sequential phases:
  1. **InnerTube attempt** — call `browseClient.fetchChannelVideos(channelId: channelId, fetchedAt: fetchedAt)`; on success, map each `BrowseVideoEntry` into the same `(existing, durationSeconds, videoId)` resolution + upsert loop the RSS path uses today; on `YoutubeBrowseException`, log a warning via `logNamed('discover.repository')` and **continue** to phase 2 (do **not** throw).
  2. **RSS fallback** — run the existing `YoutubeFetch.getRss` + `YoutubeRssParser.parse` flow exactly as today; on `YoutubeFeedFetchException`, **throw** to signal dual failure (so `_refreshChannelGuarded` records the failure).
  3. **Either-source success** — keep the `touchLastFetched` call at the end of the method, after the upsert loop completes on either path. The dual-failure throw must skip this write.
- [X] T021 [US1] In `lib/features/discover/data/discover_repository.dart` `_refreshChannelGuarded` (around lines 324–342), add a `catch YoutubeBrowseException` branch alongside the existing `YoutubeFeedFetchException` and generic `catch`. Both branches log a warning and return `_ChannelRefreshOutcome.failure(id)`. The InnerTube failure must NOT propagate to `refreshFeeds`; only the dual-failure throw (after RSS also fails) reaches the guard's generic catch.
- [X] T022 [US1] Re-run `flutter test test/features/discover/` and confirm: T016, T017, T018, T019 are all green; the existing dedupe / subscribe / dedupe tests still pass; total test count has grown by at least 4. **No regression in existing tests.**

**Checkpoint**: User Story 1 is fully functional and testable on its own. The MVP — reliable refresh via InnerTube primary + RSS fallback — is shippable from this point.

---

## Phase 4: User Story 2 — Channel uploads include richer per-video metadata without a second HTTP round-trip (Priority: P2)

**Goal**: When the InnerTube primary path returns a `BrowseVideoEntry` whose `durationSeconds` is non-null, the upserted `YoutubeFeedEntryRow` carries that duration; `_enrichMissingDurations` is **not** invoked on the InnerTube path. When the InnerTube response omits `lengthText`, the row is cached with `durationSeconds == null` and the legacy enrichment is still skipped (no "InnerTube + HTML enrichment" hybrid). The RSS fallback path continues to invoke `_enrichMissingDurations` exactly as today.

**Independent Test**: A 30-video InnerTube response with `lengthText` populated writes 30 cache rows with non-null `durationSeconds`, and the request log shows **zero** calls to `youtube.com/watch?v=…`. A 30-video InnerTube response without `lengthText` writes 30 cache rows with `durationSeconds == null`, and the request log shows zero watch-page calls (legacy enrichment skipped). A successful RSS fallback response with 5 entries invokes `_enrichMissingDurations` and the request log shows watch-page calls.

### Tests for User Story 2

- [X] T023 [P] [US2] Add unit test "InnerTube-supplied duration persists on row" to `test/features/discover/discover_repository_test.dart`. Seed an empty cache; stub InnerTube to return 30 entries with `lengthText` populated; run `refreshFeeds()`; assert every cached row has a non-null `durationSeconds` matching the parsed InnerTube length, and assert the request log contains zero `youtube.com/watch?v=…` requests.
- [X] T024 [P] [US2] Add unit test "InnerTube partial-shape writes row with null duration and skips legacy enrichment" to `test/features/discover/discover_repository_test.dart`. Seed an empty cache; stub InnerTube to return 30 entries whose JSON omits `lengthText` entirely; run `refreshFeeds()`; assert all 30 rows are cached, every row has `durationSeconds == null`, and the request log contains zero `youtube.com/watch?v=…` requests.
- [X] T025 [P] [US2] Add unit test "RSS fallback path still invokes duration enrichment" to `test/features/discover/discover_repository_test.dart`. Stub InnerTube to 401 across all profiles; stub RSS to return 5 entries; stub `YoutubeVideoDuration.fetchSeconds` to record each call; run `refreshFeeds()`; assert `_enrichMissingDurations` was called for the 5 entries (request log contains 5 `youtube.com/watch?v=…` requests).

### Implementation for User Story 2

- [X] T026 [US2] In `lib/features/discover/data/discover_repository.dart` `_refreshChannel`, after the dual-source restructure from T020:
  - On the **InnerTube success** branch: pass `r.entry.durationSeconds` (the parsed value from `BrowseVideoEntry`) into the upsert `YoutubeFeedEntryRow.durationSeconds`; after the upsert loop, **do not** call `unawaited(_enrichMissingDurations(channelId, entries))`.
  - On the **RSS fallback** branch: keep `unawaited(_enrichMissingDurations(channelId, entries))` exactly as today.
  - On **dual failure**: nothing is written; both enrichment calls are skipped.

  No new imports; no DAO changes; no schema change.
- [X] T027 [US2] Re-run `flutter test test/features/discover/` and confirm: T023, T024, T025 are all green; no existing test regressed; total test count has grown by at least 3.

**Checkpoint**: User Stories 1 and 2 both work independently. The Discover timeline shows durations on InnerTube-sourced rows immediately, with no extra HTTP round-trip.

---

## Phase 5: User Story 3 — Refresh contract and the append-only cache are preserved (Priority: P3)

**Goal**: The 1 h per-channel cooldown still applies; the append-only cache (ADR-0046) is preserved when the InnerTube primary path returns a strict subset of cached entries; profile rotation retries with the next available profile before falling back to RSS. The 4-way concurrency cap and the 8 h lifecycle-gated timer are unchanged.

**Independent Test**: A channel refreshed successfully 30 minutes ago is skipped on the next `refreshFeeds(force: false)`. A channel whose InnerTube request returns a 30-entry subset of its 50-entry cache keeps all 50 rows. A channel whose InnerTube request 401s on `WEB` retries with `MWEB` and only falls back to RSS after `MWEB` also fails.

### Tests for User Story 3

- [X] T028 [P] [US3] Add unit test "1-hour cooldown skips re-fetch when lastFetchedAt is fresh" to `test/features/discover/discover_repository_test.dart`. Pre-set the channel's `lastFetchedAt` to 30 minutes ago; run `refreshFeeds(force: false)`; assert neither the InnerTube POST nor the RSS GET was issued and the cache is unchanged.
- [X] T029 [P] [US3] Add unit test "profile rotation: WEB 401 → MWEB retry → RSS fallback" to `test/features/discover/discover_repository_test.dart`. Configure `YoutubeBrowseClient` to 401 on `WEB`, 401 on `MWEB`; configure RSS to return a valid 5-entry Atom feed; run `refreshFeeds()`; assert the request log is `[POST browse (web) → 401, POST browse (mweb) → 401, GET RSS → 200]` and the cache has 5 rows from RSS.
- [X] T030 [P] [US3] Add unit test "append-only cache preserved when InnerTube returns a subset" to `test/features/discover/discover_repository_test.dart`. Pre-seed 50 entries; stub InnerTube to return the 30 newest entries (a strict subset); run `refreshFeeds()`; assert the cache still has 50 rows, the 30 seen rows have refreshed `fetchedAt`, the 20 unseen rows are untouched, and no row was deleted.
- [X] T031 [P] [US3] Add unit test "profile rotation: WEB 401 → MWEB success" to `test/features/discover/discover_repository_test.dart`. Configure `YoutubeBrowseClient` to 401 on `WEB` and 200 on `MWEB`; run `refreshFeeds()`; assert the request log is `[POST browse (web) → 401, POST browse (mweb) → 200]` and the cache was written from the MWEB response (no RSS fallback issued).

### Implementation for User Story 3

- [X] T032 [US3] No code change is expected — the InnerTube primary path's per-channel retry ladder is already implemented in `YoutubeBrowseClient.fetchChannelVideos` (T013), the cooldown skip is preserved in `refreshFeeds` (around lines 273–280 of `discover_repository.dart`), the 4-way concurrency cap is preserved in the `_kRefreshChannelConcurrency` loop (around lines 293–306), and the append-only behavior follows automatically from the upsert loop in T020. Verify and tighten the doc comment above `_refreshChannel`'s `touchLastFetched` call so future readers understand (a) it must stay at the bottom of the method, (b) it is gated on either source's success, and (c) the InnerTube primary branch must not bypass it.
- [X] T033 [US3] Re-run `flutter test test/features/discover/` and confirm: T028, T029, T030, T031 are all green; no existing test regressed; total test count has grown by at least 4.

**Checkpoint**: All three user stories are independently functional. The refresh contract, the append-only cache, the profile rotation, and the cooldown semantics are all preserved across the new InnerTube primary path.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, formatting, lint, codegen drift, and CI gates.

- [X] T034 [P] Create `docs/decisions/0047-youtube-discover-innertube.md` with: Status (Accepted), Context (RSS bot-block / shape drift; cite spec § US1), Decision (InnerTube `browse` primary + RSS fallback; WEB built-in profile; page cap of 5; per-channel profile rotation; legacy duration enrichment skipped on InnerTube path), Consequences (better reliability, richer metadata, ≤ 60% request count when healthy; new `YoutubeBrowseClient` collaborator; explicit deferral of playlist import to a follow-up spec), and References (spec, plan, ADR-0021, ADR-0046, `docs/features/discover.md`, contracts).
- [X] T035 [P] Update `docs/features/discover.md`:
  - "Feed refresh" — add a subsection "Data sources" that names the InnerTube primary path (channel `browseId`) and the RSS fallback path (Atom feed), and the per-channel profile rotation order (`WEB` → `MWEB`).
  - "InnerTube-supplied metadata" — note that durations and view counts appear earlier on InnerTube-sourced rows (no watch-page HTML enrichment) and that the RSS fallback path retains the legacy enrichment behavior.
  - "Limitations" — drop or rephrase any wording that implies RSS is the only data source; add a note that playlist import is explicitly deferred (link to the playlist follow-up spec when it lands).
  - "Related" — link ADR-0047 alongside ADR-0021 and ADR-0046.
- [X] T036 Run `bash .github/scripts/check_dart_format.sh --fix` (auto-format the touched files). Confirm exit 0.
- [X] T037 Run `flutter analyze`; resolve any new lints. No analyzer exemptions are expected — the change introduces one new file and edits two existing files; patterns mirror `youtube_caption_fetcher.dart`.
- [X] T038 Run `flutter test test/features/discover/` once more and confirm the full feature suite is green. Run `flutter test test/data/db/` to confirm no Drift regression (no schema change ⇒ no codegen drift, but the existing DAO tests are still the regression guard).
- [X] T039 Run `bash .github/scripts/validate_ci_gates.sh` (the full CI gate: format, codegen drift, analyze, tests). No Drift or Riverpod annotation is added, so `dart run build_runner build` is not required.
- [X] T040 [P] Update `AGENTS.md` only if a new workflow rule emerged from this change (e.g., a rule about when to add a new `ClientProfile` built-in or when to extend the dual-source contract). For this change, no AGENTS.md entry is expected — skip the write unless a concrete rule surfaced during T022 / T027 / T033. If a rule did surface, add it to the "Hard rules" or "Lookup language catalog" section as appropriate.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories. Tests T005–T012 must exist and fail before T013 (the `YoutubeBrowseClient` implementation) lands.
- **User Stories (Phase 3+)**: All depend on Foundational phase completion.
  - User Story 1 (P1) is the MVP. It must be shipped first.
  - User Story 2 (P2) builds on the US1 dual-source structure but is independently testable.
  - User Story 3 (P3) builds on the US1 dual-source structure but is independently testable (most of its tests are regression guards on existing behavior).
- **Polish (Phase 6)**: Depends on all three user stories being complete (T022, T027, T033 all green).

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2). No dependencies on US2 or US3.
- **User Story 2 (P2)**: Can start after Foundational (Phase 2). Builds on US1's dual-source `_refreshChannel` structure. The duration-write and the "skip legacy enrichment on InnerTube path" edits are both inside the same `_refreshChannel` method that US1 already restructured.
- **User Story 3 (P3)**: Can start after Foundational (Phase 2). Builds on US1's dual-source structure. Mostly regression-guard tests; the implementation task (T032) is a no-op doc-comment tightening.

### Within Each User Story

- Tests (T016–T019, T023–T025, T028–T031) MUST be written and FAIL before the corresponding implementation tasks (T020–T021, T026, T032) land.
- T013 (the `YoutubeBrowseClient` implementation) lands after T005–T012 (the parser tests) are written; the parser tests must turn green on T013.
- US1 implementation tasks (T020–T021) are the dual-source restructure; US2 implementation task (T026) is a small follow-up edit inside the same method; US3 implementation task (T032) is a doc-comment tightening.

### Parallel Opportunities

- T002 and T003 (Phase 1 re-reads) can run in parallel — different files.
- T004 (WEB profile) and T005–T012 (parser tests) can run in parallel — different files.
- T016, T017, T018, T019 (US1 tests) can run in parallel — same file but different `test()` blocks (or split into a new helper test file if preferred).
- T023, T024, T025 (US2 tests) can run in parallel with T020–T021 (US1 implementation) **after** T022 is green — the US2 tests target a different aspect of `_refreshChannel` (the duration write + enrichment skip), and the dual-source structure must already exist.
- T028, T029, T030, T031 (US3 tests) can run in parallel with US1/US2 implementation work.
- T034 (ADR) and T035 (feature docs) can run in parallel — different files.
- After T022, T027, T033 are all green, US2 and US3 verification work can run in parallel.
- T036, T037, T038, T039 are sequential CI gates and should not be parallelized.

---

## Parallel Example: User Story 1

```bash
# Phase 2 — write all parser tests first (same file, different test blocks):
- [X] T005 [P] Add test "browse client: parses one-page InnerTube response into BrowseVideoEntry list"
- [X] T006 [P] Add test "browse client: follows continuation token across 3 pages"
- [X] T007 [P] Add test "browse client: honors `maxPages` and reports `exhaustedPages`"
- [X] T008 [P] Add test "browse client: empty response returns empty list without throwing"
- [X] T009 [P] Add test "browse client: missing richGridRenderer throws YoutubeBrowseException"
- [X] T010 [P] Add test "browse client: per-profile retry on 401 — retries next profile before throwing"
- [X] T011 [P] Add test "browse client: all profiles 401 throws YoutubeBrowseException"
- [X] T012 [P] Add test "browse client: parsing helpers (_parseInnerTubeLengthText + _parseInnerTubePublishedTimeText)"

# Phase 2 — implement the client (lands after the tests are red):
- [X] T013 Create lib/features/discover/data/youtube_browse_client.dart

# Phase 2 — wire it into the repository (no behavior change yet):
- [X] T014 Wire YoutubeBrowseClient into DiscoverRepository constructor

# Phase 3 — write the failing repository tests:
- [X] T016 [P] [US1] Add test "InnerTube primary success writes rows from browse response"
- [X] T017 [P] [US1] Add test "InnerTube failure falls back to RSS"
- [X] T018 [P] [US1] Add test "dual failure preserves cache and lastFetchedAt"
- [X] T019 [P] [US1] Add test "YoutubeBrowseException caught in _refreshChannelGuarded"

# Phase 3 — apply the dual-source restructure:
- [X] T020 [US1] Restructure _refreshChannel into InnerTube-attempt → RSS-fallback → either-source-success
- [X] T021 [US1] Add YoutubeBrowseException branch to _refreshChannelGuarded

# Verify all four failing tests now pass:
- [X] T022 [US1] Re-run flutter test test/features/discover/
```

---

## Parallel Example: After MVP (US1) Ships

```bash
# US2 and US3 can run in parallel after T022 is green:
# Developer A (US2):
- [X] T023 [P] [US2] Add test "InnerTube-supplied duration persists on row"
- [X] T024 [P] [US2] Add test "InnerTube partial-shape writes row with null duration and skips legacy enrichment"
- [X] T025 [P] [US2] Add test "RSS fallback path still invokes duration enrichment"
- [X] T026 [US2] Edit _refreshChannel to write duration from BrowseVideoEntry and skip _enrichMissingDurations on InnerTube path
- [X] T027 [US2] Re-run flutter test test/features/discover/

# Developer B (US3) — regression-guard tests, mostly independent files:
- [X] T028 [P] [US3] Add test "1-hour cooldown skips re-fetch when lastFetchedAt is fresh"
- [X] T029 [P] [US3] Add test "profile rotation: WEB 401 → MWEB retry → RSS fallback"
- [X] T030 [P] [US3] Add test "append-only cache preserved when InnerTube returns a subset"
- [X] T031 [P] [US3] Add test "profile rotation: WEB 401 → MWEB success"
- [X] T032 [US3] Verify and tighten the doc comment above _refreshChannel's touchLastFetched
- [X] T033 [US3] Re-run flutter test test/features/discover/

# Developer C (Polish) — can start as soon as the change surface is final:
- [X] T034 [P] Create docs/decisions/0047-youtube-discover-innertube.md
- [X] T035 [P] Update docs/features/discover.md
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup — T001, T002, T003.
2. Complete Phase 2: Foundational — T004, T005–T012 (red parser tests), T013 (YoutubeBrowseClient), T014 (wire into repo), T015 (green).
3. Complete Phase 3: User Story 1 — T016–T019 (red repository tests), T020–T021 (dual-source restructure), T022 (green).
4. **STOP and VALIDATE**: Run `flutter test test/features/discover/`; confirm T005–T012, T016–T019 are all green; the InnerTube primary path is working and the RSS fallback is wired up. Ship the MVP if the metadata / contract preservation work can be a follow-up.

### Incremental Delivery

1. Setup + Foundational → Foundation ready (YoutubeBrowseClient + parser green).
2. US1 → Verify → Ship (MVP — reliable refresh with RSS fallback).
3. US2 → Verify → Ship (richer metadata without second HTTP round-trip).
4. US3 → Verify → Ship (cooldown, profile rotation, append-only regression guards).
5. Polish (Phase 6) → ADR, docs, CI gates.

### Parallel Team Strategy

With multiple developers:

1. Team completes Phase 1 + Phase 2 together.
2. Once US1 implementation lands and T022 is green:
   - Developer A: US2 (T023–T027).
   - Developer B: US3 (T028–T033).
   - Developer C: Polish docs (T034, T035) can start as soon as the change surface is final.
3. Phase 6 sequential gates (T036–T039) run on the merged branch.

---

## Notes

- The change surface is small: one new file (`youtube_browse_client.dart`), one shared built-in profile (`web` in `client_profile.dart`), one restructured method (`_refreshChannel` in `discover_repository.dart`), plus tests + ADR + docs.
- No Drift schema change ⇒ no `dart run build_runner build` ⇒ no `*.g.dart` churn to commit.
- No new dependencies are added; `package:http` is already in `pubspec.yaml`.
- The new `YoutubeBrowseClient` mirrors the existing `YoutubeCaptionFetcher`'s posture (anonymous InnerTube surface, per-profile retry, `logNamed` instrumentation, no `print()`, no `media_kit`, no `kIsWeb`).
- The existing `ValueKey` + `findChildIndexCallback` sliver pattern already supports the new metadata surface; no widget changes are needed.
- Tasks target the production refresh path. The append-only behavior (ADR-0046) is preserved automatically because the dual-source `_refreshChannel` still upserts keyed by `(channelId, videoId)` and never deletes based on source omission.
- The page cap (`maxPages = 5`, ~150 entries per channel) is intentionally conservative; it bounds wall-clock per channel under the 4-way concurrency cap without requiring cross-channel state in the repository.
- The playlist follow-up spec is **out of scope** for this task list (per FR-013 in spec.md and the explicit user instruction "Make the playlist as follow-up"). When that spec lands, it will reuse `YoutubeBrowseClient` with `browseId: "VL<playlistId>"` and the same profile rotation.
