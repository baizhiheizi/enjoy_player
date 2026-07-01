# Quickstart: Validating the Settings Redesign

Prerequisites: a signed-in Enjoy account (Settings requires login — ADR-0031), a debug build (to see the Developer section), and access to at least one desktop-class build (Windows/macOS) plus one mobile-class build (Android/iOS) or an equivalent resizable simulator/window.

## Setup

```bash
flutter pub get
dart run build_runner build   # after pulling in the new @riverpod providers
flutter gen-l10n              # after ARB key additions
```

## Automated checks

```bash
flutter analyze
flutter test test/features/settings/
flutter test                  # full suite — confirm no regressions elsewhere
```

Expected: zero analyzer warnings, all new and existing Settings tests green.

## Manual validation scenarios

Each scenario below maps to a Success Criterion in [spec.md](./spec.md).

### 1. Route/action completeness walkthrough (SC-002)

From the redesigned Settings hub, confirm you can still reach every one of these without any missing/removed entry point:
- Profile (`/profile`) or Sign-in (`/sign-in`) depending on auth state
- Cloud sync status (`/settings/sync`)
- Display / learning / native language pickers (inline)
- AI providers (`/settings/ai-providers`)
- Microphone picker (inline dialog)
- Keyboard shortcuts (`/settings/keyboard`) — desktop builds only
- Developer: API base URL editors + AI playground (`/settings/ai-playground`) — debug builds only
- About / update prompt

Expected: 100% reachable, same destinations as before the redesign.

### 2. Findability timing (SC-001, SC-007)

Without prior guidance, time how long it takes to locate and open each of: display language, learning language, keyboard shortcuts, cloud sync status, microphone picker —
- **Without** using search: target <10s each.
- **Using** the search field (type a partial match like "keyboard" or "mic"): target <5s each, including a setting that lives inside a currently-collapsed section (e.g. type "playground" or "API" to confirm the Developer section auto-expands and surfaces the match).

### 3. Two-pane / single-column layout switch (FR-011, SC-008)

On a desktop build, resize the window across the `breakpointRail` (900px) threshold at least 10 times in a row (drag the window edge back and forth). Confirm:
- No flicker or visual glitching during the switch.
- The selected rail section (when in two-pane mode) is preserved after crossing back into two-pane mode.
- Scroll position within the currently-visible section is not lost.

### 4. Default collapse behavior (FR-012)

Open Settings fresh (debug build): confirm Account, Cloud sync, Appearance & Language, AI providers, Recording, and Keyboard shortcuts (desktop) render **expanded**, while Developer and About render **collapsed**. Manually expand Developer, then trigger a save failure (e.g. an invalid API base URL) — confirm a badge/indicator is visible on the Developer header even after collapsing it again.

### 5. No-results search state

Type a nonsense query (e.g. "zzzzz") into the search field. Confirm a clear "no settings found" empty state appears with a way to clear the query, not a blank screen.

### 6. Cross-platform visual consistency (SC-003, SC-005)

- Compare the redesigned hub side-by-side with Home/Library on the same build — spacing, radius, card treatment, and typography should feel identical (same tokens, no bespoke one-off values).
- On desktop: tab through every interactive row/rail item and confirm a visible focus ring on each.
- On mobile: confirm every interactive row meets the existing minimum touch-target size (no regression vs. today's `_SettingsTile`).

### 7. Accessibility — reduced motion / text scaling (User Story 3, Acceptance Scenario 3)

With OS-level reduced-motion and largest text-scale settings enabled, open Settings and its sub-screens/pickers — confirm no overlapping/clipped text and no motion-dependent affordance (e.g. collapse/expand still works via a visible chevron tap target, not only an animation cue).

## Sign-off

All 7 scenarios pass → redesign is ready to close out `docs/features/settings.md` updates and move to `/speckit-tasks`.
