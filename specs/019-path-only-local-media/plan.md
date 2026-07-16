# Implementation Plan: Path-Only Local Media

**Branch**: `019-path-only-local-media` | **Date**: 2026-07-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/019-path-only-local-media/spec.md`

## Summary

Stop always copying picked local audio/video into `{appDocuments}/media/`. Prefer a lasting external `file://` link when the OS gives a durable absolute path that `media_kit` can open (typical on desktop); otherwise fall back to today’s durable app-managed copy so Android/iOS remain playable after restart. Extend open resolution with a cheap size/mtime trust check, keep full chunked fingerprint for import/re-link, reuse deterministic library ids on re-import, delete app-managed copies on library delete (never external sources), and leave legacy full copies untouched (no reclaim UI).

## Technical Context

**Language/Version**: Dart `^3.12.0`, Flutter stable (3.x), Drift `^2.31.0`, Riverpod `^3.3.1`.

**Primary Dependencies**: Existing `file_picker` (`12.0.0-beta.4`), `path_provider`, `cross_file`, Drift `AppDatabase`, `FileStorage`, `MediaLibraryRepository`, `resolvePlayableSource` / locate UI. No new third-party packages in v1. Playback remains `media_kit` via `PlayerController` only.

**Storage**: Drift `videos` / `audios` (`localUri`, `md5`, `size`) plus new nullable `localMtimeMs` on both tables (schema **14**). App-managed media still under `{getApplicationDocumentsDirectory()}/media/` when copy fallback or `importBytes` (Craft) runs. External links store absolute `file://` URIs outside that directory.

**Testing**: `flutter test` unit/repository tests for `FileStorage` link-vs-copy, trust helpers, `importMedia` / `relocateLocalFile` / `deleteMedia`; `playback_open_resolver` trust-failure → relocate; widget/manual smoke for locate UI. `dart run build_runner build` after Drift schema change. Manual verification on at least one desktop OS and one mobile OS (see [quickstart.md](./quickstart.md)).

**Target Platform**: Android, iOS, macOS, Windows, Linux (no Flutter web).

**Project Type**: Flutter native mobile/desktop app.

**Performance Goals**:

- Desktop link import of multi‑GB files: UI stays responsive — hash in existing isolate; **no** full byte stream copy when linking (SC-002 / QR-004).
- Open path: existence + `stat` size/mtime only (no full hash on happy path).
- Full chunked hash only on import, re-link, or cheap-trust failure path before accepting a new pick.

**Constraints**:

- Prefer-link-then-copy on **all** platforms when lasting absolute-path access exists; otherwise durable copy (clarification Q4).
- `media_kit` requires a readable absolute filesystem path (or `file://`); Android/iOS SAF `content://` without a durable path → copy fallback (research D1).
- No legacy reclaim/migration UI (clarification Q5).
- Sync continues metadata-only; `localUri` stays device-local.
- Supersede ADR-0005 “copy into app documents” for local import; Craft/`importBytes` still writes app-managed files.
- No `print()`; no extra `Player()`.

**Scale/Scope**: Same library scale; multi‑GB local files common on desktop; mobile typically smaller but must not break after restart.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- ✅ Changes stay in `lib/data/files/` (`FileStorage`, helpers), `lib/data/db/` (schema + DAOs), `lib/data/db/media_target_resolver.dart`, `lib/features/library/` (repository delete/import), `lib/features/player/` (open trust → relocate). No feature↔feature shortcuts.
- ✅ Domain/helpers UI-free; persistence via Drift DAOs.
- ✅ Riverpod unchanged for orchestration; no new mutable global singleton.
- ✅ No new `Player()`; no `print()`.

### II. Testing Defines the Contract

- ✅ Unit: link vs copy decision, app-managed path detection, cheap trust (size/mtime).
- ✅ `FileStorage` tests: link leaves source path; copy when ephemeral; hash expect; no duplicate bytes under `media/` when linking.
- ✅ Repository: import link, re-import same fingerprint reuses id, relocate updates URI without copy when linkable, delete removes app copy / preserves external.
- ✅ `resolvePlaybackOpen`: missing file + trust fail → `MediaNeedsRelocateException`.
- ✅ `build_runner` after schema 14.
- ✅ Manual: desktop no-dupe disk; mobile playable after kill (quickstart).

### III. User Experience Consistency

- ✅ Reuse Locate media UI; adjust copy only if needed (ARB).
- ✅ Import chooser / language picker / busy dialog unchanged at product level.
- ✅ Docs: `docs/features/library.md`, `docs/features/player.md`; ADR-0050; `docs/tech-stack.md` Files row; supersede note on ADR-0005.

### IV. Performance Is a Requirement

- ✅ Link path skips full copy; hash remains isolate-based.
- ✅ Open trust is `stat`-cheap; full hash gated.

### V. Documentation and Traceability

- ✅ ADR-0050 path-linked local media (partial supersession of ADR-0005).
- ✅ Feature docs + tech-stack update in same change.
- ✅ No constitution exceptions.

**Post-design re-check**: Gates still pass. Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/019-path-only-local-media/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── file-storage-link.md
│   └── media-open-trust.md
└── tasks.md                 # /speckit-tasks (not this command)
```

### Source Code (repository root)

```text
lib/data/files/
├── file_storage.dart              # link-preferring import + delete app-managed
├── lasting_local_access.dart      # NEW: canLinkExternally / isAppManagedMediaPath
└── chunked_file_hash.dart         # unchanged

lib/data/db/
├── app_database.dart              # schemaVersion 14 + migration
├── tables/videos.dart             # + localMtimeMs
├── tables/audios.dart             # + localMtimeMs
└── media_target_resolver.dart     # cheap trust before LocalFilePlayableSource

lib/features/library/data/
└── library_repository.dart        # importMedia / relocate / deleteMedia

lib/features/player/application/
└── playback_open_resolver.dart    # trust failure → relocate (via resolver null + hash)

test/data/files/
test/features/library/
test/features/player/

docs/features/library.md
docs/features/player.md
docs/tech-stack.md
docs/decisions/0005-mvp-scope-local-only.md   # superseded-by note only if process allows; else ADR-0050 alone
docs/decisions/0050-path-linked-local-media.md
docs/decisions/README.md
```

**Structure Decision**: Extend existing data/library/player modules; no new feature package. Shared lasting-access helpers live in `lib/data/files/` next to `FileStorage`.

## Complexity Tracking

> None — no constitution violations.
