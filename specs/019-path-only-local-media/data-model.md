# Data Model: Path-Only Local Media

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

## Entities

### Local library media item (`VideoRow` / `AudioRow`)

Existing Drift rows for user-local (and Craft) media. Relevant fields:

| Field | Type | Notes |
|-------|------|--------|
| `id` | text PK | Deterministic UUID v5 from content hash + user for local imports |
| `vid` / `aid` | text | Content-addressed identity string |
| `provider` | text | `user` (local pick), `craft`, `youtube`, … |
| `title` | text | From filename basename on local import |
| `language` | text | Content language BCP-47 |
| `localUri` | text? | Playable reference: external `file://` **or** app-managed `file://…/media/{hash}{ext}` |
| `md5` | text? | Chunked content fingerprint (hex); required for relocate |
| `size` | int? | Byte length; used in cheap trust |
| `localMtimeMs` | int? | **NEW** — `File.stat().modified` ms since epoch at link/copy time; null on legacy rows |
| `mediaUrl` | text? | Remote URL if any (unchanged) |
| sync / timestamps | … | Unchanged; `localUri` / `localMtimeMs` stay device-local on sync merge |

### Playable reference

Logical roles (not a separate table):

| Kind | Detection | On delete |
|------|-----------|-----------|
| **External link** | `localUri` path outside `{documents}/media/` | Leave file on disk |
| **App-managed copy** | path under `{documents}/media/` | Delete file with library row |

### Content fingerprint

Unchanged algorithm: web-aligned partial SHA-256 (`chunkedContentSha256HexFromFileSync`). Stored in `md5`.

### Locate / re-link request

Not persisted. Triggered when open cannot resolve a trusted playable local file but `md5` is present → existing `MediaNeedsRelocateException` + Locate UI.

## Validation rules

1. Import MUST set `md5`, `size`, and `localMtimeMs` (when `stat` succeeds) whenever a local file is linked or copied.
2. Re-link MUST refuse picks whose chunked hash ≠ stored `md5`.
3. Cheap trust on open: if `size` is non-null and live size ≠ stored → untrusted. If `localMtimeMs` non-null and live mtime ms ≠ stored → untrusted.
4. Legacy rows with null `localMtimeMs`: size-only trust (or size skipped if `size` null → existence only until next successful re-link).
5. Same user + same `md5` → same `id`; re-import replaces row fields, does not create a second row.

## State transitions

```text
[no row]
    │ import (link or copy)
    ▼
[playable + trusted]
    │ file missing / trust fail
    ▼
[needs relocate] ──pick + hash match──► [playable + trusted]
    │
    │ delete
    ▼
[gone]  (+ delete app-managed file if applicable)
```

## Migration

- `schemaVersion`: 13 → **14**
- Add `local_mtime_ms` INTEGER NULL to `videos` and `audios` via `_addColumnIfMissing`
- No data backfill required (null until next import/re-link)

## Sync

- Serializers continue to omit or ignore device-local path fields (`localUri`, and `localMtimeMs` if ever present in JSON — do not upload).
- Merge preserves local `localUri` / `localMtimeMs` on download (same as today’s `localUri` preserve).
