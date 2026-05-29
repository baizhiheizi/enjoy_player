## Why

Mobile bottom navigation currently exposes five destinations (Home, Discover, Library, Cloud, Settings), which is the practical maximum for readable labels and touch targets on narrow phones. Library and Cloud already present the same content shape (audio list / video grid, editorial header, Audio/Video segment) but from different sources (local Drift vs remote Enjoy index). Keeping them as separate nav items wastes scarce tab space and splits a single user mental model — "my media" — across two peers.

## What Changes

- **Merge Library and Cloud into one shell destination** labeled **Library** on mobile bottom nav and desktop sidebar.
- Add a **Local / Cloud source switch** inside the unified Library screen (above the existing Audio / Video segment).
- Drive **source mode from the URL** (`/library` default local; `/library?source=cloud`; `/cloud` redirects to cloud source).
- Make the **header and toolbar context-aware**: Import on Local; Refresh on Cloud; compact search on Local only (mobile).
- **Remove Cloud as a separate nav item** on bottom nav and sidebar; highlight Library when either `/library` or legacy `/cloud` is active.
- Preserve **local-first data separation** (ADR-0013): no automatic cloud download; Cloud mode still pages remote index and supports Add to library.
- Signed-out users **see Cloud in the source switch** but get the existing auth-required callout when selected (sign-in discovery path).
- **Visual polish**: source switch uses editorial segmented controls consistent with Audio/Video; optional subtle subtitle when Cloud is active; smooth cross-fade when switching source (respect `prefers-reduced-motion`).

## Capabilities

### New Capabilities

- `media-library-shell`: Unified Library shell route with Local/Cloud source switching, URL state, adaptive header actions, and consolidated navigation highlighting.

### Modified Capabilities

<!-- No existing openspec specs require requirement-level changes. Library import, cloud index fetch, and local-first sync behavior are unchanged; only navigation and presentation merge. -->

## Impact

- **Routing / shell**: `app_router.dart` (query param, `/cloud` redirect), `root_shell.dart` (4 bottom-nav items), `app_sidebar.dart` (remove Cloud nav row).
- **Presentation**: Refactor `LibraryScreen` into a source-aware shell; embed or compose existing local and cloud list bodies; shared chrome for segments and header.
- **Search / hotkeys**: `ensureLibraryRouteForSearch` forces `source=local`; library search hotkey disabled on cloud source.
- **Localization**: strings for source segment labels (Local / Cloud), optional cloud subtitle; nav labels unchanged except Cloud removed from shell.
- **Docs**: Update `docs/features/app-ui.md`, `library.md`, `cloud.md`; optional ADR for navigation consolidation.
- **Tests**: Router redirect/query tests, nav index mapping, widget tests for source switch and header actions.
