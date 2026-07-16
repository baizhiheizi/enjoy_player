# Tasks: Path-Only Local Media

**Input**: Design documents from `specs/019-path-only-local-media/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are required for changed behavior (constitution + plan). Manual platform smoke is required for US3 per quickstart.md.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Shared code**: `lib/data/files/`, `lib/data/db/`
- **Feature code**: `lib/features/library/`, `lib/features/player/`
- **Tests**: `test/data/files/`, `test/features/library/`, `test/features/player/`
- **Feature docs**: `docs/features/library.md`, `docs/features/player.md`
- **ADRs**: `docs/decisions/0050-path-linked-local-media.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm touch points and doc/ADR targets before code changes

- [x] T001 Confirm affected paths from plan (`lib/data/files/`, `lib/data/db/`, `lib/features/library/data/library_repository.dart`, `lib/features/player/application/playback_open_resolver.dart`, `lib/data/db/media_target_resolver.dart`) against current tree
- [x] T002 [P] Identify doc/ADR targets: `docs/features/library.md`, `docs/features/player.md`, `docs/tech-stack.md`, `docs/decisions/0050-path-linked-local-media.md`, `docs/decisions/README.md`, supersession note for `docs/decisions/0005-mvp-scope-local-only.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema + lasting-access helpers that all stories need

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 [P] Add nullable `localMtimeMs` column to `Videos` in `lib/data/db/tables/videos.dart`
- [x] T004 [P] Add nullable `localMtimeMs` column to `Audios` in `lib/data/db/tables/audios.dart`
- [x] T005 Bump `schemaVersion` to 14 and add migration step adding `local_mtime_ms` via `_addColumnIfMissing` for videos and audios in `lib/data/db/app_database.dart`
- [x] T006 Run `dart run build_runner build` and commit regenerated Drift `*.g.dart` outputs
- [x] T007 [P] Implement `canLinkExternally` and `isAppManagedMediaPath` in `lib/data/files/lasting_local_access.dart` per `contracts/file-storage-link.md` and research D1–D2
- [x] T008 [P] Add unit tests for lasting-access helpers in `test/data/files/lasting_local_access_test.dart` (temp/cache → false; durable absolute path → true; `{documents}/media/` detection)
- [x] T009 Extend `FileImportResult` with `mtimeMs` (nullable int) in `lib/data/files/file_storage.dart`
- [x] T010 [P] Implement pure `localUriTrusted` helper (size + optional mtime, no full hash) in `lib/data/files/local_uri_trust.dart` per `contracts/media-open-trust.md`
- [x] T011 [P] Add unit tests for `localUriTrusted` in `test/data/files/local_uri_trust_test.dart` (exists, size mismatch, mtime mismatch, legacy null mtime)

**Checkpoint**: Schema 14 + helpers tested — user story implementation can begin

---

## Phase 3: User Story 1 - Import without doubling disk use (Priority: P1) 🎯 MVP

**Goal**: Prefer lasting external link on import; fall back to app-managed copy; re-import same fingerprint reuses the library row without a second full-size copy.

**Independent Test**: Import a durable-path file → plays and `media/` does not grow by ~file size; import from temp/cache path → copy under `media/` and plays; re-import same bytes → same media id.

### Tests for User Story 1

- [x] T012 [P] [US1] Extend `test/data/files/file_storage_test.dart` for link path (no duplicate under `media/`), ephemeral/temp path (copy under `media/`), and `expectedHashHex` mismatch without orphan temps
- [x] T013 [P] [US1] Extend `test/features/library/library_repository_test.dart` for link import storing external `localUri` + `localMtimeMs`, copy-fallback import, and re-import same fingerprint reuses id / refreshes URI

### Implementation for User Story 1

- [x] T014 [US1] Implement `importOrLinkPickedFile` (hash in isolate; link vs copy via `canLinkExternally`; optional `expectedHashHex`) in `lib/data/files/file_storage.dart` per `contracts/file-storage-link.md`
- [x] T015 [US1] Make `importPickedFile` / `importPickedFileExpectingHash` thin wrappers around `importOrLinkPickedFile` in `lib/data/files/file_storage.dart`; keep `importBytes` writing under `media/`
- [x] T016 [US1] Update `importMedia` in `lib/features/library/data/library_repository.dart` to use link-or-copy, persist `localMtimeMs`, and on existing deterministic id refresh URI/size/mtime and enqueue sync `update` instead of `create` when the row already existed
- [x] T017 [US1] Verify import hashing stays off the UI isolate (existing `Isolate.run` path) and document any residual main-isolate cost in the PR notes for QR-004

**Checkpoint**: US1 independently testable — desktop link import saves disk; ephemeral paths still import

---

## Phase 4: User Story 2 - Re-link when the source file is missing (Priority: P1)

**Goal**: Missing or untrusted local files open Locate; successful re-link prefers link-or-copy with hash match; mismatch leaves prior URI unchanged.

**Independent Test**: Seed row with fingerprint + path; delete/alter file or break size/mtime → Locate; matching pick updates URI without unnecessary copy; wrong file rejected.

### Tests for User Story 2

- [x] T018 [P] [US2] Extend `test/features/player/playback_open_resolver_test.dart` for size/mtime trust failure → `MediaNeedsRelocateException` when `md5` present
- [x] T019 [P] [US2] Extend `test/features/library/library_repository_test.dart` for `relocateLocalFile` link success, hash mismatch (URI unchanged), and old app-managed file cleanup when relocating to a new path

### Implementation for User Story 2

- [x] T020 [US2] Wire `localUriTrusted` into `resolvePlayableSource` / `_localUriPlayable` path in `lib/data/db/media_target_resolver.dart` using row `size` + `localMtimeMs` (pass trust fields from callers or load inside resolver)
- [x] T021 [US2] Ensure `resolvePlaybackOpen` in `lib/features/player/application/playback_open_resolver.dart` still throws `MediaNeedsRelocateException` when trust fails and fingerprint exists
- [x] T022 [US2] Update `relocateLocalFile` in `lib/features/library/data/library_repository.dart` to use `importOrLinkPickedFile` with `expectedHashHex`, persist `localMtimeMs`, and delete previous app-managed media when the path changes
- [x] T023 [US2] Smoke-check Locate UI still works end-to-end via existing `lib/features/player/presentation/locate_media_screen.dart` + `PlayerController.relocateAndOpen` (adjust ARB only if copy must mention re-link vs copy)

**Checkpoint**: US2 independently testable — missing/untrusted file → locate → hash-matched re-link

---

## Phase 5: User Story 3 - Reliable behavior on every supported platform (Priority: P2)

**Goal**: Same import/re-link UX on Android, iOS, macOS, Windows, Linux; lasting-path heuristic drives link vs copy without platform-only product forks.

**Independent Test**: Automated heuristic coverage for ephemeral vs durable paths; manual smoke on ≥1 desktop and ≥1 mobile per `quickstart.md`.

### Tests for User Story 3

- [x] T024 [P] [US3] Add platform-oriented cases in `test/data/files/lasting_local_access_test.dart` (paths under temp/cache rejected; absolute durable paths accepted) documenting the mobile copy-fallback expectation from research D1

### Implementation for User Story 3

- [x] T025 [US3] Harden `canLinkExternally` against known picker cache / ephemeral roots in `lib/data/files/lasting_local_access.dart` so typical Android/iOS picks fall back to durable copy while desktop Downloads/Movies-style paths link
- [x] T026 [US3] Execute manual desktop smoke from `specs/019-path-only-local-media/quickstart.md` (no ~S growth under `media/`; relocate after move) and record results in the PR description
- [x] T027 [US3] Execute manual mobile smoke from `quickstart.md` (import → force-quit → relaunch → play) on Android and/or iOS and record results in the PR description

**Checkpoint**: US3 validated — all platforms import; mobile survives restart via copy when link is impossible

---

## Phase 6: User Story 4 - Delete and cloud metadata stay coherent (Priority: P3)

**Goal**: Delete removes app-managed copies only; never deletes external sources; cloud metadata rows without local files still use locate.

**Independent Test**: Delete linked item → source file remains; delete copied item → `media/` file gone; null `localUri` + `md5` still raises relocate on open.

### Tests for User Story 4

- [x] T028 [P] [US4] Extend `test/features/library/library_repository_test.dart` for `deleteMedia`: external `localUri` file preserved; app-managed `media/` file deleted
- [x] T029 [P] [US4] Confirm sync serializers omit device-local path/trust fields in `test/features/sync/sync_serializers_test.dart` (add `localMtimeMs` assertion if the field could leak)

### Implementation for User Story 4

- [x] T030 [US4] Implement `deleteAppManagedMedia` in `lib/data/files/file_storage.dart` (or helper next to it) per `contracts/file-storage-link.md`
- [x] T031 [US4] Call `deleteAppManagedMedia` from `deleteMedia` in `lib/features/library/data/library_repository.dart` after successful row delete (capture `localUri` before delete); never delete external paths
- [x] T032 [US4] Verify cloud / null-`localUri` + fingerprint open path still throws `MediaNeedsRelocateException` via existing resolver tests in `test/features/player/playback_open_resolver_test.dart` (add case if missing)

**Checkpoint**: US4 independently testable — safe delete + locate for synced metadata-only rows

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Docs, ADR, gates, and regression safety

- [x] T033 [P] Write ADR `docs/decisions/0050-path-linked-local-media.md` (prefer-link-then-copy; supersedes ADR-0005 import-copy bullet) and index it in `docs/decisions/README.md`
- [x] T034 [P] Update `docs/features/library.md` import section (link vs copy; re-import reuse; delete app-managed)
- [x] T035 [P] Update `docs/features/player.md` locate / trust-check behavior
- [x] T036 [P] Update Files row in `docs/tech-stack.md` (link when lasting path; else copy)
- [x] T037 [P] Add superseded-by note on `docs/decisions/0005-mvp-scope-local-only.md` pointing at ADR-0050 for import storage only
- [x] T038 Ensure Craft/`importBytes` path still writes under `media/` and has a regression assertion in `test/data/files/file_storage_test.dart` or craft repository tests
- [x] T039 Run `bash .github/scripts/validate_ci_gates.sh --fix` (format + codegen drift) and fix until green
- [x] T040 Run `flutter analyze` and `flutter test`; fix until green

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS** all user stories
- **US1 (Phase 3)**: Depends on Foundational — 🎯 MVP
- **US2 (Phase 4)**: Depends on Foundational; benefits from US1 `importOrLinkPickedFile` (prefer completing US1 first)
- **US3 (Phase 5)**: Depends on US1 (+ US2 for relocate smoke)
- **US4 (Phase 6)**: Depends on Foundational; delete cleanup benefits from US1 app-managed path detection
- **Polish (Phase 7)**: Depends on completed stories intended for the PR

### User Story Dependencies

- **US1 (P1)**: After Phase 2 — no dependency on other stories
- **US2 (P1)**: After Phase 2; practically after T014–T015 (shared import API)
- **US3 (P2)**: After US1 import path exists; manual smokes after US2 relocate works
- **US4 (P3)**: After Phase 2; `isAppManagedMediaPath` from T007; optional after US1 for realistic fixtures

### Parallel Opportunities

- T003/T004, T007/T010, T008/T011 in Foundational once schema tasks start
- US1 tests T012/T013 in parallel before or while implementing T014
- US2 tests T018/T019 in parallel
- US4 tests T028/T029 in parallel
- Polish doc tasks T033–T037 in parallel

### Parallel Example: User Story 1

```text
Task: "Extend file_storage_test.dart for link vs copy"
Task: "Extend library_repository_test.dart for import + re-import"
# Then sequentially:
Task: "Implement importOrLinkPickedFile"
Task: "Wire importMedia"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1–2
2. Complete Phase 3 (US1)
3. **STOP and VALIDATE**: link import disk savings + copy fallback + re-import reuse
4. Optionally ship MVP behind the same import UI with locate still on existence-only until US2

### Incremental Delivery

1. Setup + Foundational → schema + helpers
2. US1 → storage win on desktop
3. US2 → trust + re-link without re-copy
4. US3 → platform hardening + manual evidence
5. US4 → delete hygiene
6. Polish → ADR/docs/CI green

### Suggested MVP Scope

**US1 only** (T001–T017): delivers the primary storage goal. US2 is the next must-have before calling the feature complete for path-linked libraries.

---

## Notes

- [P] = different files, no incomplete-task dependency
- Do not add legacy reclaim/migration UI (clarification Q5 / out of scope)
- Do not store `content://` as `localUri` in v1 (research D1)
- Every edit must leave `flutter analyze` / `flutter test` green before considering the story done

