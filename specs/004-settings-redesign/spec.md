# Feature Specification: Settings Redesign

**Feature Branch**: `[004-settings-redesign]`

**Created**: 2026-07-01

**Status**: Draft

**Input**: User description: "The current settings pages are ok, but far from good enough. It's kind of messy and ugly. User might be hard to find what they want. The features is all there, but not user friendly, not beautiful. Help me to redesign them, make it pro and beautiful, and easy to use."

## Clarifications

### Session 2026-07-01

- Q: Should the redesigned Settings hub add a search/filter box so users can jump straight to a setting by typing? → A: Yes — add a lightweight search/filter field at the top of the hub.
- Q: On wide desktop windows, should Settings switch to a persistent two-pane layout (category rail + detail pane), instead of one long scrolling column of stacked cards? → A: Yes — two-pane category rail + detail pane above a width breakpoint; narrower widths (including mobile) keep the single scrolling column.
- Q: Should low-frequency sections (Developer/Advanced, About) be collapsed by default to shorten the page? → A: Yes — collapse Developer/Advanced and About by default; everyday sections (Account, Cloud sync, Appearance & Language, AI providers, Recording, Keyboard shortcuts) stay expanded.

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.

  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - Find any setting quickly (Priority: P1)

A user opens Settings looking for one specific thing (e.g. "change my learning language" or "check sync status") and wants to locate and act on it in seconds, without reading through unrelated sections or expanding accordions to see what's inside.

**Why this priority**: Discoverability is the core complaint — "features is all there, but not user friendly" means the information architecture, not the feature set, is the problem. Fixing findability delivers the most value with the least risk, since underlying preference logic is untouched.

**Independent Test**: Can be fully tested by opening Settings on a fresh install (signed in, no customization) and timing how long it takes a first-time tester to locate and open "Keyboard shortcuts", "Display language", and "Cloud sync status" — each should be visually distinct and reachable without scrolling past unrelated dense content blocks.

**Acceptance Scenarios**:

1. **Given** the Settings hub is open, **When** the user scans the screen, **Then** every section has a clear heading, a short one-line description, and a consistent icon so the user can tell at a glance what lives in it.
2. **Given** the user is looking for a specific setting (e.g. keyboard shortcuts), **When** they scan the hub, **Then** the relevant row is visually grouped under an unambiguous section heading and does not require expanding a debug-style accordion to discover it exists.
3. **Given** the user is on a narrow (mobile) screen, **When** they open Settings, **Then** rows do not truncate their titles/values in a way that hides the setting's current value.
4. **Given** the user types a query into the Settings search field (e.g. "keyboard" or "language"), **When** results are shown, **Then** matching rows across all sections (including collapsed ones) are surfaced immediately without the user needing to manually expand or scroll to find them.

---

### User Story 2 - Understand current state and change it confidently (Priority: P2)

A user wants to see the current value of a setting (current language, sync status, mic in use, current tier) at a glance, and change it with a clear, modern control (sheet, dialog, or inline picker) that confirms the change succeeded.

**Why this priority**: Once a user finds a setting, the interaction itself needs to feel "pro" — clear current-state, low-friction editing, and visible confirmation. This is the second-most-common friction point after discoverability, and depends on User Story 1's section structure being in place.

**Independent Test**: Can be fully tested by changing the display language, the learning language, and the microphone input device from Settings and confirming each change is reflected immediately in the row's value and with a success notice, without navigating away from the hub (except for full sub-screens like keyboard shortcuts or sync status, which is expected).

**Acceptance Scenarios**:

1. **Given** a setting has a current value (e.g. display language = English), **When** the user views its row, **Then** the current value is shown clearly (not clipped, not just an icon) before they tap into it.
2. **Given** the user changes a value in a picker/sheet, **When** the change is applied, **Then** the row updates immediately and the user gets a brief success confirmation.
3. **Given** a setting is temporarily unavailable (e.g. loading, or gated by learning-language capability), **When** the user views the row, **Then** the row explains why (loading skeleton, or a disabled state with a short explanation) rather than silently failing or looking broken.

---

### User Story 3 - Feel the app is polished and trustworthy (Priority: P3)

A user visually compares Settings to the rest of the app (Home, Library, Player) and perceives consistent, premium visual quality — spacing, typography, color, and motion feel intentional rather than default/inconsistent.

**Why this priority**: Visual polish matters for perceived quality and trust, but it is the layer that sits on top of correct structure (P1) and confident interaction (P2) — polishing a poorly organized screen has less impact than fixing organization first.

**Independent Test**: Can be fully tested with a side-by-side visual review of the redesigned Settings hub against the Home/Library screens, verifying it uses the same design tokens (spacing, radius, type scale, color roles) documented in `docs/features/app-ui.md`, with no bespoke one-off styling.

**Acceptance Scenarios**:

1. **Given** the redesigned Settings hub, **When** compared to other primary screens (Home, Library), **Then** spacing, corner radius, card treatment, and typography are visually consistent (same design tokens, no bespoke styles).
2. **Given** the user opens a settings sub-screen (keyboard shortcuts, sync status) or a picker (language, microphone), **When** viewed alongside the hub, **Then** the visual language (headers, cards, list rows, dividers) matches the hub rather than looking like a separate app.
3. **Given** the user has reduced-motion or accessibility text scaling enabled, **When** they use Settings, **Then** layouts remain usable (no overlapping/clipped text, no motion-dependent affordances) per existing platform accessibility conventions.
4. **Given** the user resizes a desktop window across the two-pane breakpoint, **When** the layout switches between the two-pane (category rail + detail pane) and single-column presentation, **Then** the transition preserves the user's current section/scroll position and does not feel jarring or lose selection state.

---

### Edge Cases

- What happens when the account/profile fails to load (network error)? The existing inline retry affordance must remain available and visually consistent with the redesigned error style used elsewhere in the hub.
- What happens when a section has no content yet available (e.g. no microphone devices detected, sync never run)? Each section must show a clear empty/neutral state rather than a blank or missing row.
- What happens with very long values (long user email, long device name, long language label) on narrow mobile widths? Values must truncate gracefully with the full value available via tooltip/long-press or the destination screen, never breaking layout.
- How does the redesigned hub behave across Android, iOS, macOS, and Windows input patterns (touch, mouse hover, keyboard focus/tab order)? All interactive rows must expose hover/focus states on desktop and remain tap-friendly (minimum touch target) on mobile.
- What happens for developer/debug-only settings in non-release builds? They must remain visually and semantically separated ("advanced"/"developer" styling) from user-facing settings so a debug build doesn't look "messier" than a release build.
- What happens when the user's account is Free vs Pro (subscription tier)? Tier-gated settings (if any exist today or are added) must clearly indicate gating rather than silently hiding or looking identical to ungated settings.
- What happens when a Settings search query matches nothing? The hub must show a clear "no results" empty state with an easy way to clear the query, rather than an empty screen.
- What happens to a collapsed section (Developer/Advanced, About) when it contains the row the user is searching for, or when it contains a currently-invalid/erroring state (e.g. a developer API URL that failed to save)? Search results must auto-expand the containing section, and a section with an active error/warning must not stay silently collapsed — it should surface a badge/indicator on the collapsed header.
- What happens when the desktop window is resized right at the two-pane/single-column breakpoint repeatedly (e.g. dragging the window edge)? The layout must not thrash (flicker or lose scroll/selection state) as it crosses the breakpoint.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Settings hub MUST present its existing sections (Account, Cloud sync, Appearance & Language, AI providers, Recording, Keyboard shortcuts, Developer, About) with a redesigned visual hierarchy that groups related settings and clearly separates unrelated ones, without removing or hiding any currently reachable setting.
- **FR-002**: Every settings row MUST display, at minimum: an icon or visual marker, a title, and — where applicable — its current value or state, without requiring the user to tap in to discover the current value.
- **FR-003**: Users MUST be able to reach every currently-available settings action (language pickers, microphone picker, keyboard shortcuts editor, cloud sync status, AI provider config, developer API URL editors, about/update) through the redesigned hub using no more taps/clicks than the current implementation requires.
- **FR-004**: The redesigned hub MUST preserve all existing navigation destinations and routes (`/settings`, `/settings/sync`, `/settings/keyboard`, `/settings/ai-providers`, `/settings/ai-playground`, `/profile`, `/sign-in`) exactly as they exist today; this is a visual/structural redesign, not a re-scoping of settings functionality.
- **FR-005**: The redesigned hub MUST continue to gate developer/debug-only settings (API base URL editors, AI playground) behind the existing non-release-build check, and MUST present them with a distinct "advanced" visual treatment so they are clearly separated from user-facing settings.
- **FR-006**: The redesigned hub MUST preserve existing conditional visibility rules (e.g. keyboard shortcuts section only on desktop, learning-language capability gating, signed-in vs signed-out account/sync copy) with equivalent or clearer visual signaling than today.
- **FR-007**: All loading, error, and empty states currently implemented (account load failure with retry, sync status loading/error, language preferences loading, microphone empty state) MUST be preserved and re-styled to match the redesigned visual language, not removed.
- **FR-008**: The redesigned hub MUST remain fully navigable via keyboard (tab order, focus rings) and via touch, matching or exceeding current desktop hover/focus and mobile tap-target behavior.
- **FR-009**: All user-visible strings added or changed as part of the redesign MUST be added to the localization ARB files under `lib/l10n/` for every currently supported locale, consistent with existing localization coverage.
- **FR-010**: The Settings hub MUST offer a search/filter field that matches against section titles and row titles (case-insensitive, substring match) across all sections — including collapsed ones — and MUST auto-expand any collapsed section containing a match while highlighting or scrolling to the matching row(s). An empty query MUST restore the normal grouped view.
- **FR-011**: On desktop widths at or above the app's existing sidebar/wide-layout breakpoint, the Settings hub MUST present a persistent two-pane layout — a left category rail listing all sections and a right detail pane showing the selected section's rows — while narrower widths (including all mobile widths) MUST continue to use a single scrolling column of grouped sections. Switching between the two presentations at the breakpoint MUST preserve the user's current section selection and scroll position.
- **FR-012**: The Developer/Advanced and About sections MUST render collapsed by default; all other sections (Account, Cloud sync, Appearance & Language, AI providers, Recording, Keyboard shortcuts) MUST render expanded by default. Users MUST be able to expand/collapse any collapsible section manually, and a section containing an active error or warning state MUST surface a visible indicator even while collapsed.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture and avoid feature-to-feature shortcuts unless the plan documents an exception.
- **QR-002**: Changed behavior MUST have automated tests (widget tests for the redesigned hub and any new/changed shared components) or a documented manual verification reason where automated coverage is impractical (e.g. pure visual polish).
- **QR-003**: User-facing strings, controls, haptics, tooltips, and keyboard affordances MUST follow existing localization and shared UI patterns (`EnjoyButton`, `Haptics`, `showEnjoySheet`/`showEnjoyAlertDialog`, `EditorialHeader`).
- **QR-004**: The redesigned hub MUST remain responsive: initial render and section expansion/navigation must not introduce visible jank (dropped frames) versus the current implementation on the same reference devices/build configuration.
- **QR-005**: Feature behavior changes (if any structural/navigational change is introduced beyond pure visual redesign) MUST update `docs/features/settings.md` in the same change.

### Key Entities *(include if feature involves data)*

- **Settings Section**: A named grouping (e.g. "Account", "Cloud sync", "Appearance & Language") with a title, short description/hint, icon, and an ordered list of Settings Rows. Purely a presentation grouping — carries no new persisted data beyond what already exists.
- **Settings Row**: A single actionable or informational entry within a section (title, optional subtitle, optional current-value indicator, optional trailing control, tap destination). Maps 1:1 to existing preference/state values (display language, learning language, native language, microphone device, sync status, developer URLs, etc.) already defined elsewhere in the app; the redesign does not introduce new underlying settings values.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-time tester can locate and open any of five representative settings (display language, learning language, keyboard shortcuts, cloud sync status, microphone picker) in under 10 seconds each, without prior guidance.
- **SC-002**: 100% of settings and navigation destinations reachable in the current Settings hub remain reachable in the redesigned hub, verified by a route/action checklist walkthrough.
- **SC-003**: The redesigned hub uses only shared design tokens and shared interactive primitives already defined in `docs/features/app-ui.md` (spacing, radius, elevation, motion, `EnjoyButton`/`Haptics`/modal helpers) — zero bespoke one-off colors, radii, or spacing values introduced.
- **SC-004**: All new or changed user-visible strings are present in every currently supported locale's ARB file with no missing-translation fallback warnings in `flutter analyze` / `flutter gen-l10n` output.
- **SC-005**: Every interactive settings row exposes a visible keyboard focus ring and a minimum touch target consistent with existing shared list-row conventions, verified via manual keyboard-navigation and touch-target review on at least one desktop and one mobile build.
- **SC-006**: The redesigned hub maintains equivalent or better perceived load performance than the current implementation, with no new synchronous work added to initial frame build (verified by comparing widget build/profile traces before and after on a representative account state).
- **SC-007**: Using the Settings search field, a tester can locate any of the same five representative settings from SC-001 in under 5 seconds each by typing a partial match, including settings inside collapsed sections.
- **SC-008**: On a desktop window resized across the two-pane breakpoint at least 10 times in a row, the layout switches correctly every time with no flicker, dropped selection, or lost scroll position.

## Assumptions

- This is a **visual and information-architecture redesign** of the existing Settings hub and its sub-screens/pickers, not a re-scoping of what settings exist or how their underlying logic works; all current preferences, providers, and persistence remain unchanged.
- The existing dark-only, Cinematic Editorial design system (`docs/features/app-ui.md`) is the target visual language — this redesign does not introduce a new theme, light mode, or alternate design direction.
- "Pro and beautiful" is interpreted as: consistent use of existing shared design tokens/components, clearer section grouping, clearer current-value display, and more confident empty/loading/error states — not a request for a new visual identity.
- The Settings hub's login-only access requirement (ADR-0031) and its existing conditional sections (desktop-only keyboard shortcuts, debug-only developer tools, learning-language capability gating) remain in force and unchanged by this redesign.
- Sub-screens reachable from Settings (`/settings/sync`, `/settings/keyboard` i.e. hotkeys editor, `/settings/ai-providers`, `/settings/ai-playground`) are in scope for matching visual language but their internal domain logic (sync queue mechanics, hotkey conflict detection, AI provider validation) is out of scope for this change.
- Given the current hub file is documented as ~1566 LOC across many private widgets (`docs/features/settings.md`, referencing Issue #45's deferred split plan), the redesign is expected to also improve maintainability by splitting the screen into smaller, reusable components — but this is a technical means to the UX end, not a separate goal to be traded off against user-facing polish.
- The two-pane desktop layout (FR-011) reuses the app's existing desktop/wide-layout breakpoint concept (documented in `docs/features/app-ui.md` as the ≥900px sidebar threshold) rather than introducing a new bespoke breakpoint value; the plan phase should confirm the exact value against that existing token.
- "Search/filter" (FR-010) is a client-side, in-memory match against already-loaded section/row titles — it is not a new backend search feature and requires no new API or persisted query history.
- Section collapse/expand state (FR-012) is treated as ephemeral UI state for this change (resets each time Settings is opened) unless the plan phase determines persisting it is low-cost and worthwhile.
