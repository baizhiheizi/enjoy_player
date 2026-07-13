# Navigation Contract: Profile Tab Redesign

**Feature**: Profile Tab Redesign
**Date**: 2026-07-13

## Route Path Map

All existing deep-link paths must continue to resolve. The following routes are guaranteed:

### Shell Tab Routes (persistent, participate in tab navigation)

| Path | Screen | Notes |
|------|--------|-------|
| `/` | `HomeScreen` | Tab index 0 |
| `/discover` | `DiscoverScreen` | Tab index 1 |
| `/library` | `LibraryScreen` | Tab index 2 |
| `/profile` | `ProfileScreen` | Tab index 3 (was `/settings`) |

### Pushed Routes (overlay on shell, bottom nav visible with Profile selected)

| Path | Screen | Notes |
|------|--------|-------|
| `/settings` | `SettingsScreen` | Navigated to from Profile tab "Settings" entry |
| `/settings/sync` | `SyncStatusScreen` | Sub-screen of Settings |
| `/settings/keyboard` | `HotkeysSettingsScreen` | Sub-screen of Settings; desktop only |
| `/settings/ai-providers` | `AiProvidersScreen` | Sub-screen of Settings |
| `/settings/ai-playground` | `AiPlaygroundScreen` | Debug builds only |
| `/profile` | `ProfileScreen` | **(compat)** Also resolves as builder — backward compat for push navigations |
| `/credits` | `CreditsUsageScreen` | Unchanged |
| `/subscription` | `SubscriptionScreen` | Unchanged |
| `/player/:mediaId` | `ExpandedPlayerScreen` | Unchanged; hides bottom nav |
| `/youtube/login` | `YoutubeLoginScreen` | Unchanged |
| `/craft` | `CraftScreen` | Unchanged |
| `/sign-in` | `SignInScreen` | Outside shell; unchanged |

## Navigation Index Contract

`_navIndexForPath` in `RootShell` guarantees:

```
/profile  → 3
/settings → 3
/library  → 2
/cloud    → 2
/discover → 1
*         → 0
```

All `/settings/*` sub-paths inherit index 3 from the `/settings` prefix match.

## Sidebar Navigation Contract

The `AppSidebar` displays 4 navigation items:

| Position | Label (ARB key) | Icon | Selected when |
|----------|------------------|------|---------------|
| 1 | `homeTitle` | `home_outlined` / `home_rounded` | `path == '/'` |
| 2 | `discoverTitle` | `explore_outlined` / `explore_rounded` | `path.startsWith('/discover')` |
| 3 | `libraryTitle` | `collections_bookmark_outlined` / `collections_bookmark_rounded` | `path.startsWith('/library') \|\| path.startsWith('/cloud')` |
| 4 | **`profileTitle`** | **`person_outlined` / `person_rounded`** | **`path.startsWith('/profile') \|\| path.startsWith('/settings')`** |

Plus a `SidebarAccountChip` above the nav items showing current user info (avatar, name, subscription tier).

## Back Navigation Contract

From any Settings sub-screen (`/settings/sync`, `/settings/keyboard`, `/settings/ai-providers`, `/settings/ai-playground`):
- Platform back / back button → returns to `/settings`
- Back from `/settings` → returns to `/profile` (the profile tab)

From Profile tab (when not in a pushed sub-screen):
- Platform back on Android → minimizes app (standard tab behavior)
- No back button visible in AppBar (tab roots have no back button in the shell)

## Signed-Out State Contract

When the user is signed out (no `AuthSignedIn` state):
- `/profile` renders a sign-in prompt (same as current SidebarAccountChip signed-out state)
- Tapping the prompt navigates to `/sign-in`
- `/settings` remains accessible via deep link (Settings redirect guards still apply per ADR-0031)
