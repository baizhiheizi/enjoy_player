# Quickstart: Profile Tab Redesign

**Feature**: Profile Tab Redesign
**Date**: 2026-07-13

## Prerequisites

- Enjoy Player development environment set up (Flutter SDK, platform toolchains per `README.md`)
- A running instance of the app (or test runner) with a signed-in state for full profile content
- (Optional) Resizeable window for testing desktop adaptive layout

## Validation Scenarios

### 1. Profile Tab in Bottom Navigation (Mobile / Narrow Window)

Run the app on an Android emulator, iOS simulator, or desktop window narrower than 900px.

```bash
flutter run
```

**Verify**:
1. Bottom navigation bar shows 4 destinations: Home, Discover, Library, **Profile** (person icon)
2. Settings (gear icon) is **not** present in the bottom nav
3. Tap the Profile tab → Profile screen loads with hero card, stats, preferences, and a "Settings" entry tile
4. The Profile tab is highlighted (selected state) when viewing the Profile screen

### 2. Profile Tab in Sidebar (Desktop / Wide Window)

Resize the window wider than 900px (or run on a desktop start).

**Verify**:
1. Sidebar shows 4 nav items: Home, Discover, Library, **Profile** (person icon)
2. A "Settings" link is **not** in the sidebar nav items
3. The `SidebarAccountChip` shows the current user (avatar, name, subscription tier)
4. Click the Profile nav item → Profile screen loads in the main content area
5. Click the SidebarAccountChip → navigates to the Profile tab (not pushing a duplicate)

### 3. Settings Entry from Profile

**Verify**:
1. On the Profile screen, locate the "Settings" entry tile (gear icon, "Settings" label)
2. Tap/click it → navigates to the Settings hub screen
3. The full settings hub is displayed: section list, search field, all sections
4. Bottom nav still shows Profile tab selected (index 3 highlighted)
5. Press back / tap the Profile tab → returns to the Profile screen

### 4. Settings Sub-screens and Back Navigation

**Verify**:
1. From Settings, tap into any sub-section (e.g., Cloud Sync → `/settings/sync`)
2. The sub-screen loads correctly
3. Press back → returns to the Settings hub
4. Press back again → returns to the Profile screen

### 5. Deep Links and Backward Compatibility

Use `adb shell` (Android) or manually navigate:

```bash
# Android deep link test
adb shell am start -W -a android.intent.action.VIEW -d "enjoyplayer:///settings" ai.enjoy.player
```

Or use the desktop URL scheme.

**Verify**:
1. Navigating to `/settings` directly (deep link) opens the Settings hub
2. Navigating to `/profile` directly opens the Profile screen
3. All `/settings/*` sub-paths (sync, keyboard, ai-providers, ai-playground) resolve correctly
4. No crashes or "Page not found" errors on any existing deep-link path

### 6. Signed-Out State

Run the app in a signed-out state (clear auth tokens).

**Verify**:
1. Tap the Profile tab → shows a sign-in prompt (not a blank screen or error)
2. The prompt offers a clear path to sign in
3. The Settings entry tile on Profile screen still appears (navigates to settings hub where it redirects per auth guard)

### 7. Automated Test Suite

```bash
flutter test
flutter analyze
bash .github/scripts/validate_ci_gates.sh
```

All existing tests must pass. New widget tests (to be implemented in tasks phase) should pass:
- `RootShell` test: 4th destination is Profile
- `ProfileScreen` test: Settings entry present, tapping navigates
- `AppRouter` test: route resolution for `/profile` and `/settings`

### 8. Platform Smoke Tests

On each platform, verify the Profile tab renders correctly:

| Platform | Quick Test |
|----------|-----------|
| Android | `flutter run -d android` |
| iOS | `flutter run -d ios` (simulator) |
| macOS | `flutter run -d macos` |
| Windows | `flutter run -d windows` |
| Linux | `flutter run -d linux` |

For each: check bottom nav (narrow) and sidebar (wide) show Profile as tab 4, and Settings is reachable from within Profile.

## Expected Outcomes

- No regressions in existing settings functionality (search, section collapse, all sub-screens)
- Profile tab is the new primary identity/settings entry point
- All 5 platforms render consistently
- Existing tests pass; new widget tests cover the navigation changes
