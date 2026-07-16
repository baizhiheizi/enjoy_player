# Quickstart: Path-Only Local Media

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Validation guide for implementers after `/speckit-tasks` / implementation. No full test suites here — see contracts and data-model for invariants.

## Prerequisites

- Signed-in Enjoy Player build (import requires session per ADR-0031).
- A large local video (≥ ~500 MB recommended for disk-dupe check) on desktop.
- A small local audio/video for mobile smoke.
- Dev tree green baseline: `bash .github/scripts/validate_ci_gates.sh` (or analyze + test).

## Automated checks (CI / local)

```bash
dart run build_runner build   # after schema 14
flutter analyze
flutter test test/data/files/
flutter test test/features/library/library_repository_test.dart
flutter test test/features/player/playback_open_resolver_test.dart
bash .github/scripts/validate_ci_gates.sh --fix
```

Expected:

- Link import test: destination under `media/` is **absent** or unchanged size; `localUri` points at source path.
- Ephemeral/temp path import test: file appears under `media/{hash}…`.
- Trust mismatch (size or mtime) → `MediaNeedsRelocateException`.
- Delete app-managed → file gone; delete external link → source file still exists.
- Re-import same bytes → same media id (single row).

## Manual — desktop (Windows / macOS / Linux)

1. Note free space and size of a large sample video `S`.
2. Import via Library → From file; choose content language; wait for import dialog.
3. Confirm player opens and plays.
4. Confirm Enjoy app documents `media/` did **not** grow by ~`S` (SC-001).
5. Move or rename the source file; reopen the item → Locate media file.
6. Pick the moved file → playback works; still no new full copy under `media/`.
7. Pick a different file → clear hash-mismatch error; library item unchanged.
8. Delete the library item → original source file still on disk.

## Manual — mobile (Android and/or iOS)

1. Import a local video/audio via system picker.
2. Force-quit the app; relaunch; open the item → playback works (copy fallback and/or durable path).
3. If the item is under app storage, delete from library → confirm storage for that media is released (best-effort; use OS storage tools if needed).
4. Optional: if a durable external path was linked, delete should not remove the user’s gallery/files original.

## Docs to update in the same PR

- [docs/features/library.md](../../docs/features/library.md) — import no longer always copies.
- [docs/features/player.md](../../docs/features/player.md) — trust check + relocate.
- [docs/tech-stack.md](../../docs/tech-stack.md) — Files row.
- [docs/decisions/0050-path-linked-local-media.md](../../docs/decisions/0050-path-linked-local-media.md) — new ADR.
- [docs/decisions/README.md](../../docs/decisions/README.md) — index entry.

## Out of scope smoke

- Legacy library items that already live under `media/` still play (no reclaim UI).
- Craft from text still imports synthesized audio into app media.
- YouTube import/playback unchanged.
