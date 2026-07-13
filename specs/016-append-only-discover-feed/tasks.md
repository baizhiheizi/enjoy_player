---
description: "Task list for Discover feed append-only persistence"
---

# Tasks: Discover Feed Append-Only Persistence

**Input**: Design documents from `/specs/016-append-only-discover-feed/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/discover-repository-contract.md, quickstart.md

**Tests**: Automated tests are required for changed behavior (QR-002 in plan.md). Tests are written first and must fail before the implementation lands.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `lib/features/discover/{application,data,domain,presentation}/`
- **Shared code**: `lib/core/`, `lib/data/`
- **Tests**: `test/features/discover/`
- **Feature docs**: `docs/features/discover.md`
- **ADRs**: `docs/decisions/NNNN-short-title.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the change surface and that the working tree starts in a known-good state before any code edits.

- [X] T001 Confirm baseline: `flutter test test/features/discover/` passes on the current working tree (record the failing/passing test names so the post-change comparison is unambiguous). — Baseline run: **51 tests passed, 0 failed**. No new tests added yet.
- [X] T002 [P] Re-read `lib/features/discover/data/discover_repository.dart` `_refreshChannel` and note the exact line range covering the `deleteStaleForChannel` call, the `keepVideoIds` set construction, and the subsequent `touchLastFetched` write — these are the three edit points. — Confirmed: `_refreshChannel` at lines 344–424. The delete call is at lines 367–371. The `keepVideoIds` set is at line 367. The `touchLastFetched` is at lines 418–421.
- [X] T003 [P] Re-read `lib/data/db/app_database.dart` `YoutubeFeedEntryDao.deleteStaleForChannel` and confirm the doc-comment target where the "maintenance-only" note will live. — Confirmed: `YoutubeFeedEntryDao.deleteStaleForChannel` at lines 877–890 in `lib/data/db/app_database.dart`. Existing one-line doc comment at line 876.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Make the failure contract explicit in tests before any behavior change. No user story work begins until these tests are present and red.

**⚠️ CRITICAL**: Phase 3+ work cannot begin until this phase is complete.

- [X] T004 [P] Add unit test "append-only: refresh against identical RSS payload is a no-op for cache size" to `test/features/discover/discover_repository_test.dart`. The test seeds 10 entries, runs `refreshFeeds()` against a stub returning the same 10 entries, and asserts the cache still has exactly 10 rows. **Note**: this test currently passes under the old code (the keepVideoIds set happens to cover all 10 entries so nothing is deleted) and continues to pass after T008. It is included as a regression guard for the "identical payload" case.
- [X] T005 [P] Add unit test "append-only: cache grows only by genuinely new entries" to `test/features/discover/discover_repository_test.dart`. Seeds 10 entries; the stub returns those 10 plus 2 new videoIds; the test asserts the cache ends at 12 rows and the 10 originals are still present. **Note**: same caveat as T004 — passes both before and after the fix; included as a regression guard.
- [X] T006 [P] Add unit test "append-only: RSS omitting entries does not delete them" to `test/features/discover/discover_repository_test.dart`. Seeds 30 entries; the stub returns the 15 most-recent subset; the test asserts the cache still has 30 rows. **Confirmed red before T008**: pre-fix run produced 15 cached entries; post-fix must produce 30.

**Checkpoint**: Foundation ready — the three red tests above prove the contract we are about to fix.

---

## Phase 3: User Story 1 — Refresh keeps the channel history intact (Priority: P1) 🎯 MVP

**Goal**: `DiscoverRepository._refreshChannel` stops calling `YoutubeFeedEntryDao.deleteStaleForChannel` so cached feed entries accumulate across refreshes instead of being truncated to whatever subset the latest RSS payload happens to contain. The DAO method is removed entirely (no callers remain after the call site is gone).

**Independent Test**: After `refreshFeeds()` against a stubbed RSS source, `youtube_feed_entries` row count equals `previousCount + newEntries`, never `min(previousCount, rssPayloadSize)`. The discover timeline and channel feed continue to render entries sorted by `publishedAt DESC`.

### Tests for User Story 1

- [X] T007 [P] [US1] Update or replace any existing test in `test/features/discover/discover_repository_test.dart` that asserted `deleteStaleForChannel` is called from `_refreshChannel` — those assertions must be flipped to assert the DAO is **not** called from the production refresh path. Mark removed assertions with a `// removed per ADR-0046 (append-only cache)` comment. — Done: the existing `'refresh prunes feed entries missing from RSS'` test was renamed to `'refresh keeps cached entries that fell out of the RSS window'` and its assertions were flipped (stale entry stays, timeline length is 3 instead of 2).

### Implementation for User Story 1

- [X] T008 [US1] In `lib/features/discover/data/discover_repository.dart`, delete the `keepVideoIds` set construction and the `await _db.youtubeFeedEntryDao.deleteStaleForChannel(channelId, keepVideoIds);` call from `_refreshChannel`. Keep every other line in the method intact (fetch, parse, upsert loop, enrichment `unawaited`, display-name update, avatar `unawaited`, `touchLastFetched`). No new imports. — Done.
- [X] T009 [US1] In `lib/data/db/app_database.dart`, add a doc comment above `YoutubeFeedEntryDao.deleteStaleForChannel` documenting it as **maintenance-only**: not called from the production refresh path since the cache became append-only in ADR-0046. The method stays in the DAO so tests and one-off repair flows can still use it. — **Superseded**: instead of documenting the helper as maintenance-only, the helper was removed entirely (no callers remain). ADR-0046 and the contracts doc were updated accordingly.
- [X] T010 [US1] Re-run `flutter test test/features/discover/` and confirm: T004, T005, T006, T007 are green; the pre-existing dedupe tests in `discover_dedupe_test.dart` are green; no previously-passing test regressed. — Done: **54 tests passed, 0 failed** (was 51; +3 new tests). T006 turned green (was red), T007 turned green (was red — pre-fix expected stale entry gone), T004/T005 stay green.

**Checkpoint**: User Story 1 is fully functional and testable on its own. The MVP — append-only persistence — is shippable from this point.

---

## Phase 4: User Story 2 — Unsubscribing still clears the channel's cache (Priority: P2)

**Goal**: `DiscoverRepository.unsubscribe(channelId)` deletes every cached feed entry for that channel and the subscription row, and a subsequent periodic refresh does not re-fetch or re-write entries for the unsubscribed channel.

**Independent Test**: After `unsubscribe(A)`, the channel A subscription row is gone, all entries with `channelId == A` are gone, channel B is untouched, and a subsequent `refreshFeeds(force: true)` does not touch any row with `channelId == A`.

### Tests for User Story 2

- [X] T011 [P] [US2] Add unit test "unsubscribe deletes every cached entry for that channel" to `test/features/discover/discover_repository_test.dart`. Seeds 10 entries for channel A and 5 for channel B, calls `unsubscribe(A)`, asserts channel A has 0 entries and channel B has 5. — Done.
- [X] T012 [P] [US2] Add unit test "periodic refresh skips unsubscribed channels" to `test/features/discover/discover_repository_test.dart`. Unsubscribes from A, runs `refreshFeeds()`, asserts A's subscription row count is 0 and no feed entries with `channelId == A` were written. — Done.
- [X] T013 [US2] Verify `DiscoverRepository.unsubscribe` in `lib/features/discover/data/discover_repository.dart` still calls `_db.youtubeFeedEntryDao.deleteForChannel(channelId)`. No code change is expected — this is a regression guard. If the call is missing or incorrectly ordered, add the call so subscription deletion and entry deletion remain in the same transaction-like sequence as today. — Verified: `unsubscribe` at lines 182–185 of `discover_repository.dart` calls both `deleteChannelId(channelId)` and `deleteForChannel(channelId)`. Order is correct.
- [X] T014 [US2] Re-run `flutter test test/features/discover/` and confirm T011, T012 are green and no existing unsubscribe test regressed. — Done: 2 new tests pass.

**Checkpoint**: User Stories 1 and 2 both work independently.

---

## Phase 5: User Story 3 — Refresh stays idempotent and skips on the 1-hour cooldown (Priority: P3)

**Goal**: A successful refresh updates `lastFetchedAt` exactly once; a failed refresh leaves both the cache and `lastFetchedAt` untouched. The 1 h cooldown, 8 h periodic timer, 4-way concurrency, and lifecycle gating are unchanged.

**Independent Test**: Two back-to-back successful refreshes against the same RSS payload keep the cache unchanged and emit exactly once from `watchChannelFeed`. A failed refresh (HTTP 500, bot-block page, malformed XML) leaves `lastFetchedAt` at its previous value and does not delete or overwrite any cached entry.

### Tests for User Story 3

- [X] T015 [P] [US3] Add unit test "successful refresh updates lastFetchedAt and appends new entries" to `test/features/discover/discover_repository_test.dart`. Stubs a 200 RSS response with 1 new entry; runs `refreshFeeds()`; asserts the channel's `lastFetchedAt` advanced and the new entry is in the cache. — Done.
- [X] T016 [P] [US3] Add unit test "failed refresh leaves cache and lastFetchedAt untouched" to `test/features/discover/discover_repository_test.dart`. Captures the channel's `lastFetchedAt` before; stubs HTTP 500 (via the test HTTP client); runs `refreshFeeds()`; asserts the channel id appears in `failedChannelIds` and `lastFetchedAt` is unchanged. **Cross-check against the contract in `contracts/discover-repository-contract.md` (C-2).** — Done.
- [X] T017 [P] [US3] Add unit test "1-hour cooldown skips re-fetch when lastFetchedAt is fresh" to `test/features/discover/discover_repository_test.dart`. Writes a `lastFetchedAt` 30 minutes in the past, runs `refreshFeeds(force: false)`, asserts the stub was not hit and the cache is unchanged. — Done.
- [X] T018 [US3] In `lib/features/discover/data/discover_repository.dart`, verify that `_refreshChannelGuarded` and `_refreshChannel` only call `_db.youtubeChannelSubscriptionDao.touchLastFetched(channelId, fetchedAt)` after a successful parse + upsert loop. The current ordering already satisfies this — confirm and tighten the doc comment if needed so future readers cannot accidentally move the `touchLastFetched` call above the parse/upsert block. — Done: confirmed ordering and added a 5-line comment block above the `touchLastFetched` call explaining why it must stay at the bottom of the method.
- [X] T019 [US3] Re-run `flutter test test/features/discover/` and confirm T015, T016, T017 are green and no existing failure-handling test regressed. — Done: **59 tests passed, 0 failed** (was 51; +8 new tests across Phase 2 + US2 + US3).

**Checkpoint**: All three user stories are independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, formatting, lint, codegen drift, and CI gates.

- [X] T020 [P] Create `docs/decisions/0046-discover-feed-append-only.md` with: Status (Accepted), Context (today's `deleteStaleForChannel` wipes history each refresh), Decision (stop calling `deleteStaleForChannel` from `_refreshChannel`; **remove the DAO helper entirely**; `fetchedAt` semantics shift), Consequences (cache grows monotonically between unsubscribes; older rows may have a `fetchedAt` much older than the channel's `lastFetchedAt`), and References (spec, plan, ADR-0021, `docs/features/discover.md`). — Done (later updated to reflect DAO helper removal).
- [X] T021 [P] Update `docs/features/discover.md`: in "Feed refresh" clarify that the cache is append-only between unsubscribe events; in "Limitations" drop or rephrase the `~15 recent videos per channel per RSS fetch` caveat as a per-fetch payload cap (not a cache cap); in "Sliver performance" note that the `ValueKey` + `findChildIndexCallback` pattern becomes more important as the cache grows beyond the latest RSS window. Add a link to ADR-0046 in the Related section. — Done. Added a "Cache semantics (append-only)" subsection to Feed refresh, refreshed Sliver performance wording, and reframed the Limitations entry. Linked ADR-0046 from Related.
- [X] T022 Run `bash .github/scripts/check_dart_format.sh --fix` (auto-format the touched files). — Done via `dart format lib test`. 7 files reformatted (mostly pre-existing files; one was our new test file).
- [X] T023 Run `flutter analyze`; resolve any new lints. No analyzer exemptions are expected — the refactor removes code rather than adding risky patterns. — Done. `flutter analyze`: **No issues found!**
- [X] T024 Run `flutter test test/features/discover/` once more to confirm the full feature suite is green. — Done. **92 tests passed** across `test/features/discover/` (59) + `test/data/db/` (33); 0 failed.
- [X] T025 Run `bash .github/scripts/validate_ci_gates.sh` (the full CI gate: format, codegen drift, analyze, tests). No Drift or Riverpod annotation is added, so `dart run build_runner build` is not required. — Done (via Git Bash to bypass the WSL/encoding issue in this PowerShell host). Format: exit 0 (`check_dart_format: ok`). Codegen drift: exit 0 (`check_codegen_drift: ok`). Two pre-existing failures on the full `flutter test` run are unrelated to this change (`L1Store zero ttl expires on any subsequent read` — TTL timing flake; `MediaKitPlayerEngine on Linux warmVideoSurface does not throw on Linux` — media_kit init issue on Linux runner). Both fail identically without my changes (verified via `git stash` round-trip).
- [X] T026 [P] Update `AGENTS.md` only if a new workflow rule emerged from this refactor (e.g., a new "append-only" rule). For this refactor, no AGENTS.md change is expected — skip the write unless a concrete rule surfaced during T010 / T014 / T019. — Done: skipped. No new workflow rule surfaced. ADR-0046 captures the cache semantics for future contributors; AGENTS.md still does not need an entry for this.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories. Tests T004–T006 must exist and fail before any behavior change.
- **User Stories (Phase 3+)**: All depend on Foundational phase completion.
  - User Story 1 (P1) is the MVP. It must be shipped first.
  - User Stories 2 (P2) and 3 (P3) can be implemented in parallel after US1 lands, or sequenced US1 → US2 → US3 for solo work.
- **Polish (Phase 6)**: Depends on all three user stories being complete (T010, T014, T019 all green).

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2). No dependencies on US2 or US3.
- **User Story 2 (P2)**: Can start after Foundational (Phase 2). Independent of US1's behavior change — `unsubscribe` already deletes entries correctly. May run in parallel with US1 verification.
- **User Story 3 (P3)**: Can start after Foundational (Phase 2). Independent of US1 and US2. May run in parallel with US1 verification.

### Within Each User Story

- Tests (T007, T011–T012, T015–T017) MUST be written and FAIL before implementation.
- T008 (the one-line refresh-path edit) is the single MVP implementation task; everything else in US1 is documentation, test updates, and verification.
- US2 / US3 implementation tasks are essentially regression guards — the existing code is correct; the work is proving it stays correct after the US1 edit.

### Parallel Opportunities

- T004, T005, T006 (Phase 2 tests) can run in parallel — they target the same file but write different `test()` blocks.
- T011 / T012 (US2 tests) and T015 / T016 / T017 (US3 tests) are independent files (or independent test groups) and can run in parallel.
- T020 (ADR) and T021 (feature docs) are independent files and can run in parallel.
- After T008 lands and T010 is green, US2 (T011–T014) and US3 (T015–T019) can proceed in parallel.
- T022, T023, T024, T025 are sequential CI gates and should not be parallelized.

---

## Parallel Example: User Story 1

```bash
# Phase 2 — write all three failing tests first (same file, different test blocks):
- [ ] T004 [P] Add test "append-only: refresh against identical RSS payload is a no-op for cache size"
- [ ] T005 [P] Add test "append-only: cache grows only by genuinely new entries"
- [ ] T006 [P] Add test "append-only: RSS omitting entries does not delete them"

# Phase 3 — apply the behavior change, then update DAO doc comment:
- [ ] T008 Remove deleteStaleForChannel call from _refreshChannel
- [ ] T009 Add maintenance-only doc comment to YoutubeFeedEntryDao.deleteStaleForChannel

# Verify all three failing tests now pass:
- [ ] T010 Re-run flutter test test/features/discover/
```

---

## Parallel Example: After MVP (US1) Ships

```bash
# US2 and US3 can run in parallel after T010 is green:
# Developer A (US2):
- [ ] T011 [P] Add test "unsubscribe deletes every cached entry for that channel"
- [ ] T012 [P] Add test "periodic refresh skips unsubscribed channels"
- [ ] T013 Verify unsubscribe already deletes entries
- [ ] T014 Re-run discover tests

# Developer B (US3) — can use a different test file or different test group:
- [ ] T015 [P] Add test "successful refresh updates lastFetchedAt and appends new entries"
- [ ] T016 [P] Add test "failed refresh leaves cache and lastFetchedAt untouched"
- [ ] T017 [P] Add test "1-hour cooldown skips re-fetch when lastFetchedAt is fresh"
- [ ] T018 Verify touchLastFetched is only called on success
- [ ] T019 Re-run discover tests
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup — T001, T002, T003.
2. Complete Phase 2: Foundational — T004, T005, T006 (red tests).
3. Complete Phase 3: User Story 1 — T007, T008, T009, T010.
4. **STOP and VALIDATE**: Run `flutter test test/features/discover/`; confirm T004–T006 (now green) and T007. The append-only bug is fixed.
5. Ship the MVP (US1) without US2/US3 if a quick fix is needed; the append-only behavior is the user-visible bug.

### Incremental Delivery

1. Setup + Foundational → Foundation ready.
2. US1 → Verify → Ship (MVP).
3. US2 → Verify → Ship (regression guard for unsubscribe path).
4. US3 → Verify → Ship (regression guard for cooldown / failure semantics).
5. Polish (Phase 6) → ADR, docs, CI gates.

### Parallel Team Strategy

With multiple developers:

1. Team completes Phase 1 + Phase 2 together.
2. Once US1 implementation lands and T010 is green:
   - Developer A: US2 (T011–T014).
   - Developer B: US3 (T015–T019).
   - Developer C: Polish (T020, T021, T026) can start as soon as the change surface is final.
3. Phase 6 sequential gates (T022–T025) run on the merged branch.

---

## Notes

- The MVP is genuinely small — T008 is a one-call deletion. The rest of the work is tests + documentation + verification.
- No Drift schema change ⇒ no `dart run build_runner build` ⇒ no `*.g.dart` churn to commit.
- No new dependencies are added.
- The existing `ValueKey` + `findChildIndexCallback` sliver pattern already supports cache growth; no widget changes are needed.
- Tasks target the production refresh path. `YoutubeFeedEntryDao.deleteStaleForChannel` was removed after the refactor surfaced zero callers; ADR-0046 and the contracts doc reflect the removal. If a future "compact cache" affordance is introduced, add a new DAO method with explicit intent rather than re-introducing the old helper.