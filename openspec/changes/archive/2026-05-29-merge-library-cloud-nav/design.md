## Context

Enjoy Player uses a platform-adaptive shell ([ADR-0009](../decisions/0009-platform-adaptive-shell.md)): `EnjoyBottomNav` below 900px, `AppSidebar` at ≥900px. Both currently expose **five** destinations — Home, Discover, Library, Cloud, Settings.

`LibraryScreen` and `CloudScreen` are structurally parallel:

| Layer | Library (local) | Cloud (remote) |
|-------|-----------------|----------------|
| Header | `EditorialHeader` + Import | `EditorialHeader` + Refresh |
| Kind filter | `SegmentedButton` Audio / Video | Same |
| Body | `MediaCardRow` / `MediaCardTile` | Same + pagination |
| Data | Drift via `libraryFilteredListsProvider` | HTTP via `CloudIndexRepository` |
| Auth | Guest OK | Signed-in required |

ADR-0013 keeps **data** separate (local-first; cloud is browse-and-copy). This change only **consolidates navigation and presentation** — no sync or repository behavior changes.

The cinematic editorial design system ([docs/features/app-ui.md](../../docs/features/app-ui.md)) already defines segmented controls, editorial headers, and motion tokens. The unified screen must feel native to that system, not like two screens glued together.

## Goals / Non-Goals

**Goals:**

- Reduce mobile bottom nav to **four items** by merging Library + Cloud into one **Library** destination.
- Introduce a **Local / Cloud source switch** as the primary axis above Audio / Video.
- Preserve **URL-addressable state** (`?source=local|cloud`) and **backward-compatible** `/cloud` deep links.
- Deliver **editorial-quality UI**: consistent segments, context-aware header, subtle motion, accessible semantics.
- Apply the same consolidation on **desktop sidebar** (one Library row; no separate Cloud row).
- Keep search hotkey and sidebar search targeting **Local source only**.

**Non-Goals:**

- Merging Drift and remote data models; unified search across local + cloud; cloud item badges for "already in library" (future polish).
- Moving Settings out of bottom nav (separate change).
- Renaming the tab to "Collection" or "My Media" (keep **Library** — familiar, matches local-first story).
- Auto-prompt sign-in modal when selecting Cloud while signed out (keep inline `AuthRequiredCallout`).

## Decisions

### 1. Single route `/library` with query param `source`

**Decision:** Canonical route is `/library`. Query param `source` ∈ `{local, cloud}`; default **omitted = local**. `/cloud` and `/cloud?…` **redirect** to `/library?source=cloud` (preserve other query keys if any added later).

**Rationale:** One shell page key; bottom nav highlights Library for both; shareable/bookmarkable cloud view; go_router redirect avoids breaking existing links or docs.

**Alternative considered:** Path segments `/library/local`, `/library/cloud` — clearer URLs but more router churn and duplicate route definitions.

### 2. Presentation: `MediaLibraryScreen` shell composing existing bodies

**Decision:** Evolve `LibraryScreen` into a **source-aware shell** (`media_library_screen.dart` or renamed in place). Extract:

- `LocalLibraryTabBody` — current `_AudioLibraryBody` / `_VideoLibraryBody` + search bar logic from `library_screen.dart`
- `CloudLibraryTabBody` — delegate to refactored bodies from `cloud_screen.dart` (pagination state stays in cloud subtree)

Shell owns:

- `TabController` for Audio / Video (shared across sources)
- Source segment UI + sync from URL
- `EditorialHeader` with dynamic subtitle / trailing
- `AnimatedSwitcher` (220ms, `Curves.easeOutCubic`) between local and cloud column subtrees

**Rationale:** Minimal duplication; cloud pagination state remains scoped; library search providers unchanged.

**Alternative considered:** New `features/media_collection/` module — rejected as over-abstraction for a nav merge.

### 3. Visual hierarchy — "two rails, one page"

**Decision:** Vertical stack inside the Library scaffold body:

```
┌─────────────────────────────────────────────────────────────┐
│  EditorialHeader                                            │
│    title: "Library"  (always)                               │
│    subtitle: "CLOUD" (uppercase label, primary color)         │
│              only when source=cloud                         │
│    trailing: Import (local) | Refresh (cloud)               │
├─────────────────────────────────────────────────────────────┤
│  Source segment  [  Local  |  Cloud  ]   ← full width       │
│  Kind segment    [  Audio  |  Video  ]   ← full width       │
│  Search field    (local only, mobile < rail breakpoint)     │
├─────────────────────────────────────────────────────────────┤
│  AnimatedSwitcher → TabBarView (audio | video bodies)       │
└─────────────────────────────────────────────────────────────┘
```

**Segment styling:** Reuse the **exact** `SegmentedButton.styleFrom` block already duplicated in Library and Cloud (extract to `library_segment_style.dart` or `EnjoySegmentedControl` in `core/theme/widgets/` to avoid a third copy). Both segments use:

- `radiusFull` pill shape
- `surfaceContainerHighest` track at 45% alpha
- `primaryContainer` selected fill at 65% alpha
- `labelMedium` w600, icons 16px for kind; source segment **without icons** (text-only — cleaner, avoids icon crowding on narrow phones)

**Spacing rhythm** (from tokens):

- Header bottom → source segment: `space12`
- Source → kind: `space8` (tighter — reads as one control cluster)
- Kind → search: `space12`
- Horizontal gutters: `space24` (match existing Library)

**Cloud subtitle:** Use existing `EditorialHeader.subtitle` — uppercase tracked label in primary (`l10n.librarySourceCloudEyebrow`, e.g. "CLOUD" / "云端") so the hero title stays "Library" while mode is unmistakable.

### 4. Source switch interaction

**Decision:**

- Tapping Local / Cloud updates URL via `context.go('/library?source=…')` (or `replace` when already on library with different source — prefer `go` for history consistency).
- **Preserve** `TabController` index (audio/video) when switching source — user expectation: "same kind, different catalog."
- **Do not** reset cloud pagination cursors when switching away and back within a session (StatefulWidget subtree keyed by `ValueKey('cloud-body')` kept alive via `Offstage` or separate state holder — prefer **`IndexedStack`** for local vs cloud subtrees so cloud fetch state survives tab toggles).

**Rationale:** IndexedStack avoids re-fetch churn and preserves scroll position; matches "switch lens, same telescope" metaphor.

### 5. Navigation shell updates

**Decision:**

| Surface | Before | After |
|---------|--------|-------|
| Bottom nav | 5 items | 4: Home, Discover, **Library**, Settings |
| Sidebar | 5 nav rows | 4: remove Cloud row |
| `_navIndexForPath` | `/cloud` → 3 | `/library`, `/cloud` → 2 (Library slot) |
| Sidebar selected | `path.startsWith('/library')` OR cloud | `path.startsWith('/library')` OR `path.startsWith('/cloud')` |

Cloud icon removed from nav; cloud remains reachable via source switch and `/cloud` redirect.

### 6. Search and hotkeys

**Decision:**

- `ensureLibraryRouteForSearch` → `router.go('/library')` or `router.go('/library?source=local')` explicitly.
- Compact search bar visible only when `source=local` AND width < `breakpointRail`.
- Sidebar search field unchanged; on tap still navigates to library local.
- `librarySearchHotkeyEnabledForPath`: unchanged (disabled on player/auth routes).

### 7. Auth UX in Cloud source

**Decision:** When `source=cloud` and signed out, show full-body `AuthRequiredCallout` (existing widget, `AuthRequiredSurface.cloud`) **below** the header and segments — segments remain interactive so user can switch back to Local without signing in.

**Rationale:** Avoid trapping guest users; preserve sign-in discovery without modal interruption.

### 8. Motion and accessibility

**Decision:**

- Source change: `AnimatedSwitcher` with 220ms fade + 8px vertical slide (match shell page transition feel).
- Honor `MediaQuery.disableAnimations` — instant swap when reduced motion preferred.
- Semantics: source segment exposes "Library source, Local selected" / "Cloud selected"; kind segment unchanged.
- Focus order: header trailing → source segment → kind segment → search (if shown) → list.

### 9. Localization

**Decision:** Add ARB keys:

| Key | EN | Purpose |
|-----|-----|---------|
| `librarySourceLocal` | Local | Source segment |
| `librarySourceCloud` | Cloud | Source segment |
| `librarySourceCloudEyebrow` | Cloud | Header subtitle when cloud active |
| `librarySourceSwitchSemantics` | Library source | Semantics container label |

Reuse existing `libraryTitle`, `cloudRefreshTooltip`, `actionImport`, tab audio/video strings.

### 10. Provider for source (optional thin layer)

**Decision:** Parse `source` from `GoRouterState` in the screen — **no new Riverpod provider required** for v1. If tests need it, add `librarySourceFromUri(Uri)` pure function in `core/routing/` or `features/library/application/`.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Vertical chrome eats list space on small phones | Compact segments (`visualDensity.compact`); cloud mode hides search; subtitle only one line |
| Users think cloud items are downloaded | Unchanged "Add to library" on cloud cards; docs update; future badge optional |
| `/cloud` bookmarks break | Permanent redirect to `/library?source=cloud` |
| Double TabController confusion | Shell owns one controller; cloud/local bodies receive `kindIndex` only |
| IndexedStack keeps cloud HTTP state in memory | Acceptable — cloud lists are paginated, not huge; dispose on sign-out if needed |
| Segment control duplication | Extract shared style helper in this change |

## Migration Plan

1. Ship router redirect first ( `/cloud` → `/library?source=cloud` ) — safe backward compat.
2. Implement unified screen behind `/library`; wire source param.
3. Remove Cloud from nav; update docs and l10n.
4. No DB migration; no sync changes.
5. **Rollback:** Revert nav list and route mapping; keep `/cloud` route as standalone page again.

## Open Questions

- **None blocking.** Optional follow-up: "In library" badge on cloud rows already copied locally (not in this change).
