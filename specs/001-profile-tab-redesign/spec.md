# Feature Specification: Profile Tab Redesign

**Feature Branch**: `001-profile-tab-redesign`

**Created**: 2026-07-13

**Status**: Draft

**Input**: User description: "We need to redesign the `profile`/`settings` pages. We should make `profile` as the top-level tab, instead of the `settings`. And also we should refactor the profile screen, make the settings as an entry in the screen. Make the UX friendly, like modern/pro/beautiful application."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Profile as a top-level tab (Priority: P1)

As a user, I see a "Profile" tab in the main navigation (bottom bar on mobile, sidebar on desktop) replacing the current "Settings" tab. Tapping the Profile tab opens a redesigned profile screen that shows my account information, preferences, and provides access to settings — all in one unified place.

**Why this priority**: This is the structural change that the entire redesign depends on. Without it, the new profile screen has no navigation entry point.

**Independent Test**: Open the app on any platform and verify the 4th tab reads "Profile" with a user/avatar icon instead of "Settings" with a gear icon. Tap it and confirm the profile screen appears.

**Acceptance Scenarios**:

1. **Given** the app is open on a mobile device, **When** the user looks at the bottom navigation bar, **Then** the 4th destination is labeled "Profile" (not "Settings") and uses a user/avatar icon.
2. **Given** the app is open on desktop, **When** the user looks at the sidebar, **Then** the 4th nav item is labeled "Profile" and uses a user/avatar icon.
3. **Given** the user taps/clicks the new Profile tab, **When** the navigation completes, **Then** the profile screen is displayed.
4. **Given** the user is signed out, **When** they tap the Profile tab, **Then** a signed-out state is shown (prompting sign-in) rather than erroring or showing empty content.

---

### User Story 2 - Settings as an entry within Profile (Priority: P1)

As a user viewing the Profile screen, I can access all settings from a clearly labeled entry point within the profile screen — either as a tappable tile/section or a secondary navigation element. Settings are no longer a separate top-level tab but remain fully accessible.

**Why this priority**: This is the primary refactoring goal. Settings must remain reachable without being a top-level tab, and the transition from Profile to Settings must feel natural.

**Independent Test**: Open the Profile tab, locate the Settings entry point, tap it, and verify the full settings experience (section list, search, sub-screens) is accessible.

**Acceptance Scenarios**:

1. **Given** the user is on the Profile screen, **When** they look at the screen, **Then** a "Settings" entry (tile, row, or button) is visible and clearly labeled.
2. **Given** the user taps the Settings entry, **When** the navigation completes, **Then** the full settings screen (with section list, search field, and all sub-screens) is displayed.
3. **Given** the user navigates into a sub-screen from Settings (e.g., AI providers, keyboard shortcuts, sync status), **When** they press back, **Then** they return to the Settings screen, and pressing back again returns them to the Profile screen.
4. **Given** the user is on the Profile screen on desktop (wide layout), **When** Settings is displayed, **Then** the two-pane settings layout (if applicable) is preserved or a desktop-appropriate navigation is used.

---

### User Story 3 - Modern, beautiful Profile screen design (Priority: P2)

As a user, the Profile screen presents my identity, practice stats, language preferences, and account information in a visually appealing, modern layout that rivals pro-grade language-learning applications. The design uses clean hierarchy, appropriate spacing, visual polish, and adaptive layout.

**Why this priority**: The visual redesign delivers the "modern/pro/beautiful" UX goal. It builds on top of the structural changes from P1.

**Independent Test**: Open the Profile tab and visually inspect the layout — hero/avatar area, stats, preferences, account info, and settings entry. Verify on both mobile and desktop widths that the layout adapts appropriately.

**Acceptance Scenarios**:

1. **Given** the user is signed in, **When** they open the Profile tab, **Then** the screen shows an avatar/identity area at the top, followed by practice stats, languages/preferences, account info (credits, subscription), and a Settings entry — all with clear visual hierarchy and spacing.
2. **Given** the user is on a mobile device, **When** they view the Profile screen, **Then** the content scrolls vertically in a single column with appropriate touch targets.
3. **Given** the user is on a desktop device (wide screen), **When** they view the Profile screen, **Then** the layout adapts to use the available width with appropriate multi-column or centered-max-width layout.
4. **Given** the user scrolls the Profile screen, **When** the scroll position changes, **Then** scrolling is smooth (60fps) without jank or layout shifts.

---

### User Story 4 - Adaptive navigation maintains consistency (Priority: P3)

As a user switching between mobile and desktop layouts (e.g., resizing a window, rotating a tablet), the Profile tab and Settings access work consistently across all form factors without losing state or requiring redundant steps.

**Why this priority**: Enjoy Player is a cross-platform app (mobile + desktop). The Profile/Settings redesign must work across all supported form factors.

**Independent Test**: On a desktop device, resize the window from wide to narrow and back. Verify the Profile tab remains accessible and the Settings entry adapts appropriately at each breakpoint.

**Acceptance Scenarios**:

1. **Given** the user is on a wide desktop window with the sidebar visible, **When** the window is narrowed below the rail breakpoint, **Then** the navigation switches to bottom bar mode and the Profile tab remains accessible at index 3.
2. **Given** the user has Settings open on desktop, **When** the window is resized to a narrow width, **Then** the settings content remains usable in a single-column adapted layout.
3. **Given** any supported platform (Android, iOS, macOS, Windows, Linux), **When** the user interacts with the Profile tab and Settings entry, **Then** the navigation and layout work correctly without platform-specific breakage.

---

### Edge Cases

- **Signed-out state**: When no user is signed in, the Profile tab should show a meaningful signed-out state (e.g., prompt to sign in) rather than an empty or broken layout.
- **Deep linking**: Existing deep links to `/settings` and `/settings/*` sub-routes must continue to work. Deep links to `/profile` must also continue to work.
- **Settings search**: The settings search functionality must remain fully functional and accessible when settings is navigated to from the Profile screen.
- **Back navigation on mobile**: After navigating from Profile > Settings > sub-screen, the back button on Android and the swipe-back gesture on iOS should unwind the stack correctly (sub-screen → Settings → Profile tab).
- **Stale ProfileContent widget**: The shared `ProfileContent` widget is currently used in two places (standalone `/profile` and embedded in Settings two-pane). After the redesign, only the Profile tab context remains; the embedded use in Settings must be removed cleanly without breaking the widget.
- **Keyboard navigation**: Desktop keyboard shortcuts that reference settings sections must remain functional.
- **Screen reader order**: Accessibility focus order must flow logically from the identity area through to the Settings entry.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The main navigation (bottom bar on mobile, sidebar on desktop) MUST display "Profile" as the 4th destination, replacing "Settings" as a top-level tab.
- **FR-002**: The Profile tab MUST use a user/avatar icon consistent with the personal identity metaphor (not a gear/settings icon).
- **FR-003**: Tapping the Profile tab MUST navigate to the profile screen that displays user identity, stats, preferences, account info, and a Settings entry point.
- **FR-004**: The Settings entry within the Profile screen MUST be a clearly visible, tappable UI element that navigates to the existing settings hub screen.
- **FR-005**: The settings hub screen (with section list, search field, and sub-screen routing) MUST remain fully functional and accessible via the Profile screen's Settings entry.
- **FR-006**: All existing settings sub-screens (sync status, keyboard/hotkeys, AI providers, AI playground) MUST remain accessible through the Settings hub, reachable from Profile.
- **FR-007**: The Profile screen MUST adapt its layout across mobile (single-column scroll) and desktop (wider, potentially multi-section) breakpoints.
- **FR-008**: The signed-out state on the Profile tab MUST display a meaningful UI (e.g., sign-in prompt) rather than crashing or showing empty content.
- **FR-009**: Existing route paths `/profile`, `/settings`, and all `/settings/*` sub-routes MUST continue to resolve correctly for deep linking and backward compatibility.
- **FR-010**: Back navigation from Settings sub-screens MUST return to the Settings hub, and back from the Settings hub MUST return to the Profile screen (not to a previous tab).
- **FR-011**: The `ProfileContent` widget MUST be refactored so it no longer has the embedded-two-pane Settings usage path; the Profile tab is its sole consumer.
- **FR-012**: All existing profile features (hero card, practice stats, account card, preferences form, sign-out) MUST remain intact and accessible within the redesigned Profile screen.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture and avoid feature-to-feature shortcuts unless the plan documents an exception.
- **QR-002**: Changed behavior MUST have automated tests (widget tests for Profile screen layout, navigation, signed-out state; unit tests for any refactored logic) or a documented manual verification reason.
- **QR-003**: User-facing strings, controls, haptics, tooltips, and keyboard affordances MUST follow existing localization (ARB files updated with any new keys) and established shared UI interaction primitives from the design system.
- **QR-004**: The Profile screen MUST scroll at 60fps on target devices, including on desktop with the full content visible.
- **QR-005**: Feature behavior changes MUST update the matching documentation under `docs/features/` (specifically `docs/features/settings.md` and `docs/features/auth.md`).
- **QR-006**: The Settings search feature MUST remain responsive and return results in under 200ms for the existing settings catalog.
- **QR-007**: Navigation transitions between Profile → Settings → sub-screens MUST feel smooth (no visible lag or layout shift during transition).

### Key Entities

- **Navigation Destination**: Represents a tab in the bottom bar / sidebar. Attributes: label, icon, route path, index. The redesign swaps the 4th destination from "Settings" to "Profile".
- **Profile Screen**: The unified profile landing page. Composed of identity section, stats, preferences, account info, and a Settings entry point. Replaces the standalone `/profile` route as a full tab screen.
- **Settings Hub**: The existing searchable settings section list screen, now reached via the Profile screen's Settings entry rather than directly from the tab bar. Remains at route `/settings`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can locate and access all settings within 2 taps/clicks from the Profile tab (1: tap Profile tab, 2: tap Settings entry).
- **SC-002**: The Profile screen scrolls at a consistent 60fps on a reference device with the full profile content loaded.
- **SC-003**: 100% of existing settings sub-screens (sync, hotkeys, AI providers, AI playground) remain navigable and functional after the redesign.
- **SC-004**: All supported platforms (Android, iOS, macOS, Windows, Linux) display the Profile tab and Settings entry correctly with no platform-specific rendering or navigation bugs.
- **SC-005**: All existing deep-link URLs (`/settings`, `/settings/*`, `/profile`) continue to resolve to their respective screens without crashing.
- **SC-006**: The signed-out Profile tab state renders without errors and provides a clear path to sign in.

## Assumptions

- The existing `ProfileContent` widget will be refactored to remove the dual-context (standalone + embedded) pattern; it will only serve the Profile tab context after the redesign.
- The existing Settings screen, its search functionality, and all sub-screens remain unchanged in behavior — only their navigation entry point changes.
- The bottom navigation bar and sidebar components (`EnjoyBottomNav`, `AppSidebar`) support changing the 4th destination without architectural changes to the navigation infrastructure.
- The GoRouter `ShellRoute` and `RootShell` structure can accommodate the tab swap by changing the route mapping from `/settings` index 3 to the Profile route at index 3.
- New profile/settings documentation will update `docs/features/settings.md` and `docs/features/auth.md`; a new `docs/features/profile.md` may be warranted if the profile section outgrows `auth.md`.
- No changes to localization libraries or l10n infrastructure are needed; new display strings (if any) will be added to existing ARB files.
- The redesign targets all five supported platforms (Android, iOS, macOS, Windows, Linux); no web targets are introduced.
