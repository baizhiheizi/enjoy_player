# ADR-0050: Path-linked local media (prefer link, copy fallback)

## Status

Accepted

## Context

ADR-0005 imported local media by always copying into app documents. That doubles disk use for large videos on desktop. Users wanted lasting links to the source file, with locate + fingerprint re-link when the source moves, while remaining reliable on Android and iOS where picker paths are often ephemeral. `media_kit` needs a readable absolute filesystem path (not a bare SAF `content://` URI).

## Decision

1. **Prefer lasting external link** when the picked path is an absolute, existing file outside OS temp/cache; store that path as `localUri` and do **not** duplicate bytes under `{documents}/media/`.
2. **Otherwise copy** into `{documents}/media/{contentHash}{ext}` (existing durable app-managed layout) so import remains playable after restart on every supported platform.
3. Persist nullable **`localMtimeMs`** with `size` for cheap open trust (size + mtime). Full chunked fingerprint runs at import / re-link / trust failure — not on every successful open.
4. **Re-import** of the same fingerprint for the same user reuses the deterministic library id and refreshes the playable reference.
5. **Delete / re-link cleanup** removes app-managed copies under `media/` only when unreferenced by the current library **and** other per-user SQLite files on the device (shared `{hash}{ext}` paths); never deletes externally linked source files. Re-import that switches away from an app-managed path performs the same unreferenced cleanup.
6. **No legacy reclaim UI** for previously always-copied items in this change.
7. Craft / `importBytes` continues to write app-managed files.

## Consequences

- Desktop libraries avoid multi‑GB duplication when files live on a durable path.
- Typical mobile picker caches fall back to copy (meets cross-platform reliability).
- Partially supersedes ADR-0005’s “copy into app documents” import storage rule; other ADR-0005 MVP scope items are unchanged.
- Future work may add SAF persistable URI + native open if mobile storage pressure warrants it.

## References

- Spec: `specs/019-path-only-local-media/`
- Related: [ADR-0005](0005-mvp-scope-local-only.md), [ADR-0003](0003-player-core-media-kit.md)
