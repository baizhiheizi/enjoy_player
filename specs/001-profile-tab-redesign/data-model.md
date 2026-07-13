# Data Model: Profile Tab Redesign

**Feature**: Profile Tab Redesign
**Date**: 2026-07-13

## Overview

This feature does not introduce new data entities, database tables, or API contracts. It is a pure navigation and presentation-layer restructuring. All existing data models remain unchanged.

## Existing Entities (Unchanged)

### Navigation Destination (Bottom Bar / Sidebar)

The tab bar destination list changes its 4th entry:

| Index | Before | After |
|-------|--------|-------|
| 0 | Home (`/`) | Home (`/`) — unchanged |
| 1 | Discover (`/discover`) | Discover (`/discover`) — unchanged |
| 2 | Library (`/library`) | Library (`/library`) — unchanged |
| 3 | Settings (`/settings`) | **Profile** (`/profile`) |

Properties per destination:
- `icon` / `selectedIcon`: Icons for unselected/selected states
- `label`: Localized display string (from `profileTitle` ARB key)
- `route`: The target route path
- `pathPrefix`: The path prefix used by `_navIndexForPath` for highlighting

### Route Registry (AppRouter)

All route paths are preserved for backward compatibility. The change is structural:

| Route | Before | After |
|-------|--------|-------|
| `/profile` | `GoRoute.builder` (pushed) | **ShellRoute page** (tab) |
| `/settings` | ShellRoute page (tab) | `GoRoute.builder` (pushed from profile) |
| `/settings/sync` | Builder | Builder — unchanged |
| `/settings/keyboard` | Builder | Builder — unchanged |
| `/settings/ai-providers` | Builder | Builder — unchanged |
| `/settings/ai-playground` | Builder | Builder — unchanged |

### Profile Screen Composition

The expanded Profile screen (Profile tab) contains these sections, all backed by existing data sources:

1. **Identity / Hero Card** — from `userProfileProvider` (auth state)
2. **Practice Stats** — from `profilePracticeStatsProvider` + `learningStatisticsProvider`
3. **Account Card** — credits/subscription links (navigates to `/credits`, `/subscription`)
4. **Preferences Form** — name, daily goal, language settings (writes via `updateProfileRequest`)
5. **Settings Entry** — NEW: navigates to `/settings`
6. **Sign Out Button** — calls `authCtrlProvider.signOut()`

### State Transitions

No new state transitions. The existing auth state machine (`AuthCtrl`) remains the sole source of profile data:
- `AuthInitial` / `AuthLoading` / `AuthSignedOut` → sign-in prompt on Profile tab
- `AuthSignedIn` → full profile content
- `AuthAwaitingOtp` → OTP flow (same as current sidebar behavior)
