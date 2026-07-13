# Research: Profile Tab Redesign

**Feature**: Profile Tab Redesign
**Date**: 2026-07-13

## Decision 1: Navigation Index Mapping for Settings Sub-paths

**Decision**: `_navIndexForPath` in `RootShell` maps both `/profile` and `/settings` (and `/settings/*` sub-paths) to index 3, ensuring the Profile tab stays highlighted when the user is in Settings.

**Rationale**: Settings is navigated to from the Profile tab. When the user is on `/settings` (or `/settings/sync`, etc.), the bottom navigation bar should show the Profile tab as selected, indicating the user is still within the "profile area." Tapping the Profile tab while in Settings should navigate back to `/profile` (the profile root), providing natural "up" navigation.

**Alternatives considered**:
- **Keep Settings at its own index**: Would require adding a 5th tab, which clutters navigation and contradicts the spec's goal of making settings a sub-entry of profile.
- **Unhighlight all tabs when in Settings**: Confusing UX — no visual indication of where the user is.
- **Dynamically switch tab index based on navigation stack**: Over-engineered; the simple prefix-matching approach handles all cases cleanly.

---

## Decision 2: ProfileScreen Refactoring — Remove Scaffold/AppBar

**Decision**: The refactored `ProfileScreen` should drop its own `Scaffold`/`AppBar` wrapper, living as a chrome-free widget (like `HomeScreen`, `DiscoverScreen`, and `LibraryScreen`). The shell provides page chrome.

**Rationale**: When Profile becomes a shell tab page (via `_shellPage` transition), the `RootShell` already provides the navigation chrome — a nested `Scaffold`+`AppBar` would create a double-app-bar look. The existing `HomeScreen`, `DiscoverScreen`, and `LibraryScreen` all render without their own `AppBar` for the same reason. On mobile, there's no back button on a tab root. On desktop, the sidebar provides navigation identity.

**Alternatives considered**:
- **Keep the AppBar for Profile**: Would create a visual duplicate (app bar inside a shell with its own chrome). Rejected as inconsistent with all other tab screens.
- **Conditionally show AppBar based on screen width**: Adds complexity for no value — the sidebar/bottom nav already identifies the page.

---

## Decision 3: Settings Account Section — Keep as "View Profile" Link

**Decision**: The Account section in the Settings hub should remain but be changed from an embedded `ProfileContent` widget (two-pane) or a compact identity card (single-column) to a simple `SettingsRow` that navigates to the Profile tab.

**Rationale**: Settings is still reachable via deep-link (`/settings`). When a user lands directly on Settings, they need a way to reach their profile. A simple "Account" row with a "View Profile" label and chevron provides this affordance without the complexity of embedding the full profile form. This also eliminates the dual-context `ProfileContent` pattern (standalone `/profile` + embedded in Settings).

**Alternatives considered**:
- **Remove Account section entirely from Settings**: Deep-linked users would have no way to reach the Profile tab from Settings without using the sidebar/bottom nav. While the bottom nav is present, explicitly surfacing the link improves discoverability.
- **Keep full ProfileContent embedding in two-pane**: Defeats the purpose of the redesign — Profile should be the primary surface, not a secondary embed within Settings.

---

## Decision 4: `ProfileContent` — Remove Dual-Context Pattern

**Decision**: Remove the `showRefreshIndicator` parameter from `ProfileContent`. The widget is now only used in the Profile tab context (`showRefreshIndicator: true` behavior). Move pull-to-refresh into the widget unconditionally.

**Rationale**: The `showRefreshIndicator` parameter existed solely for the two-pane Settings embed path, which used `showRefreshIndicator: false`. With the Account section in Settings becoming a simple link row, there is no more embed usage. Removing the parameter simplifies the widget API.

**Alternatives considered**:
- **Keep the parameter as a no-op**: Leaks implementation history into the API. Clean removal is preferred.
- **Keep the parameter for future flexibility**: Premature abstraction; the widget has one caller now.

---

## Decision 5: SidebarAccountChip Navigation

**Decision**: In `SidebarAccountChip`, change `context.push('/profile')` to `context.go('/profile')` so tapping the account chip navigates to the profile tab (not pushing a duplicate route on the stack).

**Rationale**: With Profile as a tab, `context.push('/profile')` would open a secondary instance of the profile screen on top of the existing tab page, creating confusing dual-profile navigation. `context.go()` replaces the current shell page with the profile tab, which is the expected behavior.

**Alternatives considered**:
- **Keep `context.push`**: Would navigate to `/profile` but push it on the stack — creates a bad UX where "back" from profile goes to wherever the user was before, not the same tab.
- **Remove the account chip from sidebar**: Too aggressive — the chip shows useful at-a-glance profile info (avatar, name, subscription tier). It's a helpful shortcut, especially for the upgrade CTA.

---

## Decision 6: Route Structure — Profile as Shell Page, Settings as Builder

**Decision**: `/profile` becomes a `ShellRoute` page (using `_shellPage` transition) so it participates in the tab/page stack. `/settings` remains a regular `GoRoute.builder` so it pushes over the shell (keeping the bottom nav visible with Profile selected).

**Rationale**: Tab pages should use the shell transition for smooth fade+slide animation. Settings, as a sub-screen pushed from Profile, should use the default GoRouter page transition. The bottom nav remains visible because `/settings` is still within the `ShellRoute`, and `_navIndexForPath` maps it to index 3 (Profile).

**Alternatives considered**:
- **Make /settings a ShellRoute page**: Would make Settings a 5th tab, contradicting the spec.
- **Make /profile a builder**: Would mean the Profile tab wouldn't participate in the shell transition, breaking consistency with Home/Discover/Library tabs.
