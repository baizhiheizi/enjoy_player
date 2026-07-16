# Research: Path-Only Local Media

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

> Clarification session 2026-07-16 resolved product questions. This document resolves remaining technical unknowns for the plan.

## Decisions

### D1. “Lasting access” means a durable absolute filesystem path `media_kit` can open

- **Decision**: Prefer linking when the picked path is an absolute, still-readable file path that is **not** under app ephemeral dirs (temp / cache). Otherwise copy into `{documents}/media/{hash}{ext}` (existing behavior). Do **not** store bare Android `content://` / iOS security-scoped bookmarks as `localUri` in v1.
- **Rationale**: Enjoy’s local engine opens `file://` / absolute paths via `media_kit`. Flutter `File` and media_kit do not reliably play from SAF content URIs without native bridging. `file_picker` FAQ notes Android/iOS often expose cached copies, not durable originals; persistable SAF grants (even if/when exposed by `file_picker` betas) still do not yield a stable absolute path for mpv without extra work.
- **Alternatives considered**:
  - Android SAF persistable URI as `localUri` — rejected for v1: playback stack expects filesystem paths; would need a new open path and grant lifecycle.
  - Always copy on mobile, link only on desktop — rejected by clarification Q4 (uniform prefer-link rule); mobile simply fails the lasting-path heuristic more often and falls back to copy, which still satisfies FR-003.
  - Symlinks into `media/` — rejected: still breaks when target moves; Windows privilege issues; no benefit over storing the real path.

### D2. Link-vs-copy heuristic (`canLinkExternally`)

- **Decision**: Link iff all hold: (1) non-empty absolute path, (2) `File(path).exists()`, (3) path is **outside** `getTemporaryDirectory()`, `getApplicationCacheDirectory()`, and any known picker cache root we detect, (4) optionally: on Android/iOS, also require path **outside** the app’s own sandbox temp-like areas even if under documents siblings that are known ephemeral. Paths already under `{documents}/media/` count as app-managed (copy destination), not “external link,” but are durable.
- **Rationale**: Ephemeral picker caches look like absolute paths but vanish or get recycled — treating them as links would reintroduce locate churn. Desktop Downloads/Movies paths pass the heuristic.
- **Alternatives considered**:
  - Platform hard-split (`Platform.isIOS || isAndroid` → always copy) — rejected: contradicts uniform prefer-link; heuristic already yields copy on typical mobile picks.
  - Probe “survives restart” during import — impossible without restart; heuristic is the practical proxy.

### D3. Cheap open trust = size + optional mtime; full hash gated

- **Decision**: Persist `size` (already present) and new `localMtimeMs` (nullable int, milliseconds since epoch from `File.stat().modified`) at import/re-link. On open, after `exists`: compare live `stat.size` to stored `size`; if `localMtimeMs != null`, also compare modified ms. Mismatch → treat as unreadable for playable resolution → `MediaNeedsRelocateException` when fingerprint exists. Full chunked SHA-256 only on import, re-link, and accepting a newly picked file after trust failure.
- **Rationale**: Clarification Q1; multi‑GB full hash on every open is unacceptable (QR-004). Size+mtime catches in-place replacements with high probability; full hash remains the authority at link time.
- **Alternatives considered**:
  - Existence only — rejected: fails the replaced-in-place edge case.
  - Full hash every open — rejected: performance.
  - Size only — weaker; mtime is cheap when available; null mtime on legacy rows → size-only until next re-link refreshes metadata.

### D4. Schema 14: `localMtimeMs` on `videos` and `audios`

- **Decision**: Add nullable `IntColumn localMtimeMs` to both tables; bump `schemaVersion` to **14** with `_addColumnIfMissing` (same pattern as prior migrations). Do not sync this column to the server (device-local trust metadata, like `localUri`).
- **Rationale**: Need durable trust metadata next to `size` without overloading unrelated fields. Nullable keeps legacy rows valid.
- **Alternatives considered**:
  - Store mtime inside a JSON settings blob — rejected: harder to query/test; belongs on the media row.
  - Recompute nothing / skip trust for legacy — rejected: size already exists for most imports.

### D5. Re-import reuses deterministic id (already insertOrReplace)

- **Decision**: Keep `enjoyLocalVideoVid` / `enjoyLocalAudioAid` from content hash + userId. `importMedia` continues to compute the same id; `VideoDao`/`AudioDao` `InsertMode.insertOrReplace` updates the row. Explicitly refresh `localUri`, `size`, `localMtimeMs`, `updatedAt`; if a row already existed, enqueue `SyncAction.update` instead of `create` when sync is wired.
- **Rationale**: Clarification Q2; matches existing id scheme and Craft/YouTube dedupe patterns.
- **Alternatives considered**: Always new UUID rows — rejected by clarification.

### D6. Delete: remove app-managed file only

- **Decision**: `isAppManagedMediaPath(uri)` true when the path is under `{documents}/media/`. On `deleteMedia`, after deleting the Drift row (and sync enqueue), if app-managed, `File.delete` best-effort. Never delete external linked paths. Also best-effort delete local thumbnail under `media_thumbs/` as today if such cleanup exists or is added consistently.
- **Rationale**: Clarification Q3; prevents orphaned multi‑GB copies from copy-fallback imports.
- **Alternatives considered**: Never delete bytes — storage leak. Confirm dialog — unnecessary friction for internal copies.

### D7. Relocate uses same link-preferring import

- **Decision**: Replace `importPickedFileExpectingHash`’s always-copy with shared `importOrLinkPickedFile(..., expectedHashHex:)` used by both import and relocate. On success, update `localUri` / size / mtime; if previous URI was app-managed and new URI is external (or a different app-managed path), delete the old app-managed file when no longer referenced (same hash path is shared — only delete if path differs and old was app-managed).
- **Rationale**: Clarifications Q1/Q4; avoids second full copy on desktop re-link.
- **Alternatives considered**: Relocate always copies — defeats storage goal.

### D8. Legacy copies and Craft unchanged

- **Decision**: No reclaim UI or background migration (clarification Q5). `FileStorage.importBytes` / Craft continue writing under `media/`. YouTube unchanged.
- **Rationale**: Scope control; generated audio has no external source.

### D9. ADR-0050 supersedes ADR-0005 import storage bullet

- **Decision**: New ADR **0050** records prefer-link-then-copy and mobile copy fallback; marks ADR-0005’s “copy into app documents” as superseded for local import (MVP scope otherwise intact).
- **Rationale**: Constitution V — costly-to-reverse storage decision.

### D10. No new dependencies for v1

- **Decision**: Stay on current `file_picker`; do not adopt SAF persistable URI plugins yet.
- **Rationale**: Playback cannot consume content URIs without more native work; heuristic + copy fallback meets “works on all platforms.”
- **Alternatives considered**: Wait for file_picker SAF APIs + custom content-URI player — deferred follow-up if desktop savings prove valuable and mobile storage becomes painful.

## Resolved Technical Context unknowns

| Topic | Resolution |
|-------|------------|
| How to detect lasting access | D1–D2 absolute durable path heuristic |
| Open trust without multi‑GB hash | D3 size + mtime |
| Schema | D4 `localMtimeMs`, v14 |
| Re-import | D5 deterministic id + replace |
| Delete semantics | D6 |
| Relocate | D7 |
| Legacy / Craft | D8 |
| Docs | D9 |
| Packages | D10 |
