## Context

Today, `PlayerController.openMedia` calls `schedulePlayerOpenSideEffects`, which fire-and-forgets `TranscriptRepository.fetchCloudTranscripts` when the user is signed in. Fetch progress is invisible: UI providers only watch SQLite (`transcriptLinesForMediaProvider`, `allTranscriptsForMediaProvider`). Empty lines render `TranscriptEmptyState` even while a cloud or YouTube Worker poll is active. The CC button shows a badge only when tracks already exist; manual actions in the subtitle picker have local spinners but background fetch does not.

Persistence uses `transcript_fetch_states` as a binary “fetched once” gate with no in-flight or error surface. Primary transcript selection (`echo_sessions.transcript_id`) is set on import/extract/cloud upsert but not when tracks pre-exist without a primary.

Constraints: Riverpod architecture, Drift for persistence, signed-in cloud fetch policy unchanged, single `media_kit` player (embedded extract uses ffmpeg separately), ADR-0010/0013 sync scope.

## Goals / Non-Goals

**Goals:**

- One shared fetch lifecycle observable by CC button, transcript panel, and subtitle picker.
- Automatic transcript resolution on open: cloud/YouTube (signed in), sidecar import (local), primary auto-select when tracks exist.
- Pro-app loading UX: spinners/skeletons during fetch; friendly errors with retry.
- Consistent loading feedback for Extract/Import from empty state and picker.

**Non-Goals:**

- Automatic ffmpeg embedded extract on open (remains user-initiated).
- Changing auth policy (signed-out users still skip cloud fetch).
- Transcript editing, multi-language auto-translate, or on-video subtitle rendering.
- Uploading transcripts to cloud or changing Worker/Rails API contracts.

## Decisions

### 1. Fetch status: in-memory notifier + persisted outcome

**Choice:** Add a `@Riverpod` `TranscriptFetchCtrl` (family keyed by `mediaId`) holding `{status: idle|loading|success|empty|error, errorMessage?}`. Persist outcome extensions in `transcript_fetch_states` via Drift migration: add nullable `lastStatus` (`text`) and `lastError` (`text`).

**Rationale:** In-memory alone loses state on widget rebuild/navigation; DB alone cannot represent in-flight. Hybrid lets UI react immediately and survive brief navigation.

**Alternatives considered:**
- DB-only polling → cannot show spinner without false “loading” on revisit.
- Repository callback stream without Riverpod → harder for widgets to consume consistently.

### 2. Single orchestration entry: `resolveTranscriptsOnOpen`

**Choice:** Replace bare `fetchCloudTranscripts` call in side effects with `TranscriptRepository.resolveOnOpen(mediaId)` that sequentially:
1. Auto-select primary if tracks exist and session primary is null.
2. Import sidecar `.srt`/`.vtt` if playable URI is a local file path (same directory, basename match, language from filename hint).
3. If signed in, run existing cloud/YouTube fetch (respecting `transcript_fetch_states` unless forced).

Each step updates fetch ctrl status; cloud step sets `loading` at start.

**Rationale:** One pipeline avoids race between sidecar import and cloud fetch fighting for primary selection.

**Sidecar matching rules:**
- For `file:///path/to/movie.mp4`, scan same directory for `movie.srt`, `movie.vtt`, `movie.<lang>.srt`, etc.
- Skip files already imported (deterministic transcript id exists).
- Use existing `SubtitleParserFacade` + `importSubtitle` path.

### 3. Primary auto-select on open

**Choice:** Extract `_maybeSetPrimaryTranscript` logic into `ensurePrimaryTranscript(mediaId)` called at start of `resolveOnOpen` and after any upsert. Uses existing source priority: official → auto → ai → user, then `createdAt`.

**Rationale:** Fixes panel empty / picker-has-tracks mismatch without user action.

### 4. UI state matrix

| Fetch status | Has lines | Panel shows | CC button |
|--------------|-----------|-------------|-----------|
| loading | no | Skeleton or fetching copy | Spinner overlay |
| loading | yes (local) | Lines | Badge (optional subtle pulse) |
| success/empty | no | Empty state | Plain icon |
| error | no | Friendly error + Retry | Plain or warning tint |
| idle | no | Empty state | Plain icon |
| any | yes | Lines | Badge |

**Choice:** `TranscriptPanel` watches `transcriptFetchStatusProvider(mediaId)` alongside `transcriptLinesForMediaProvider`. Prefer skeleton over empty when `status == loading && lines.isEmpty`.

**CC button:** Wrap icon with small `CircularProgressIndicator` when loading and no tracks yet; keep badge when tracks exist.

**Picker:** Show a slim banner or disable “Refresh from cloud” with shared loading state when background fetch runs; manual refresh sets same ctrl to loading.

### 5. Error handling alignment

**Choice:** Map repository exceptions to user-facing friendly strings (reuse `transcriptErrorFriendlyTitle/Hint` l10n). Retry invalidates fetch ctrl and calls `resolveOnOpen(..., forceCloud: true)`.

**YouTube Worker `failed`:** Do **not** mark fetch state as success-with-empty; persist `lastStatus = error` so UI can show retry. Adjust repository to only `upsertFetched` on ready with stored rows or definitive empty from server.

### 6. Shared action loading for Extract/Import

**Choice:** Small `TranscriptActionButton` widget or mixin used by empty state and picker sheet, accepting `Future<void> Function()` and managing local `_busy` state with spinner in leading icon slot.

**Rationale:** DRY; empty state currently lacks spinners.

### 7. Concurrency guard

**Choice:** `TranscriptFetchCtrl` ignores duplicate `resolveOnOpen` calls while `loading` for the same `mediaId`. Manual refresh while background fetch runs joins the same in-flight future.

## Risks / Trade-offs

- **[Risk] Sidecar false positives** (wrong `.srt` in folder) → Mitigation: only match basename patterns; user can delete track in picker.
- **[Risk] Drift migration for fetch states** → Mitigation: nullable columns with defaults; backfill `lastStatus = success` where row exists.
- **[Risk] Long YouTube poll blocks “empty” UI** → Mitigation: loading state is correct UX; consider future timeout message after N seconds (optional follow-up).
- **[Risk] ffmpeg extract still manual** → Accepted non-goal; empty state copy unchanged for embedded case.
- **[Trade-off] Signed-out users see no cloud loading** → Existing policy; local sidecar still runs without auth.

## Migration Plan

1. Ship Drift schema bump (`lastStatus`, `lastError` on `transcript_fetch_states`).
2. Deploy app update; on first open per media, `resolveOnOpen` runs new pipeline.
3. Existing `transcript_fetch_states` rows treated as prior success (skip cloud unless user refreshes).
4. Rollback: new columns ignored by older builds; fetch ctrl is additive.

## Open Questions

- Should CC spinner show when **re-fetching** (`force: true`) while tracks already exist? **Proposed:** subtle progress on refresh only inside picker; CC keeps badge.
- Sidecar language `und` when filename has no hint — import as `und` or prompt? **Proposed:** import as `und`; user can re-import with language dialog if needed (matches low-friction auto-load goal).
