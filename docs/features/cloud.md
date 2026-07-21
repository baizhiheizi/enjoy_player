# Cloud (remote media index)

## Purpose

Browse **your** remote Enjoy **audio** and **video** metadata (`GET /api/v1/mine/audios|videos`) without automatically copying rows into the local Library. The player stays **local-first**: the Library tab only shows what exists in Drift.

## Flow

1. User opens **Library** from the shell and selects the **Cloud** source segment (or follows a `/cloud` redirect to `/library?source=cloud`).
2. Lists are loaded page by page using `updatedAfter` cursors (same API as the legacy full sync download).
3. **Add to library** inserts one row into `audios` / `videos` via the same merge shape as server JSON (`localUri` stays null; `mediaUrl` is preserved when the server provided it).
4. Items with a `mediaUrl` can play from that URL in the expanded player when the app routes them to **media_kit**. **YouTube** rows (including when the cloud payload omitted `provider` but `vid` / `source` / `mediaUrl` identify YouTube) open in the **YouTube WebView** engine, not **Locate file**. Other items without a resolvable URL still appear in the Library and use **Locate file** (hash match) like other synced metadata-only rows.

## Requirements

- Must be signed in (Enjoy account). When signed out, the screen explains that sign-in is required.

## Related

- [Sync](sync.md)
- [ADR-0013](../decisions/0013-local-first-sync.md)
- UI: [`CloudLibraryBody`](../../lib/features/cloud/presentation/cloud_library_body.dart) composed inside [`LibraryScreen`](../../lib/features/library/presentation/library_screen.dart) — same `MediaCard` row/tile primitives as local Library (editorial header, source + Video/Audio segments with Video first, generative covers).
