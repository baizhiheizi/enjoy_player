# Implementation Plan: Profile Tab Redesign

**Branch**: `001-profile-tab-redesign` | **Date**: 2026-07-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-profile-tab-redesign/spec.md`

## Summary

Redesign navigation so **Profile** becomes the 4th top-level tab (replacing Settings in the bottom bar and sidebar), and **Settings** becomes an entry point within the Profile screen. The Profile screen is visually polished with a modern UX. All existing settings functionality remains intact but is reached via Profile instead of via a direct tab.

## Technical Context

**Language/Version**: Dart ^3.12, Flutter stable 3.x

**Primary Dependencies**: Riverpod (state management), GoRouter (navigation), media_kit (player — unchanged), Drift (persistence — unchanged)

**Storage**: N/A (no new storage; existing Drift AppDatabase for profile/settings unchanged)

**Testing**: `flutter test` (widget tests for ProfileScreen, RootShell navigation), `flutter analyze`

**Target Platform**: Android, iOS, macOS, Windows, Linux (no Flutter web)

**Project Type**: Flutter native mobile/desktop app

**Performance Goals**: Profile screen scrolls at 60fps; settings search returns in <200ms (unchanged)

**Constraints**: Must preserve all existing route paths (`/profile`, `/settings`, `/settings/*`) for deep-link and backward compatibility; no `print()` calls; no new `media_kit` `Player()` instances; localization via ARB files

**Scale/Scope**: 4 navigation destinations; ~5 files changed in RootShell + AppSidebar + AppRouter; ProfileContent refactored (~1 widget parameter removed, 1 Settings entry section added); Settings two-pane layout updated (~1 embedded widget replaced with link row)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- [x] All changes stay in existing feature directories: `lib/features/auth/presentation/`, `lib/features/settings/presentation/`, `lib/features/player/presentation/`, and `lib/core/routing/`. No new features created.
- [x] No new domain models. Persistence (profile preferences via `authCtrlProvider`, settings state via existing Riverpod providers) unchanged.
- [x] Riverpod providers for auth, settings search, section selection, collapse — all unchanged.
- [x] No `print()` calls introduced; no `media_kit` `Player()` additions.

### II. Testing Defines the Contract

Required automated tests:
- **RootShell widget test**: Verify 4th nav destination shows Profile icon/label, selecting it navigates to `/profile`
- **AppSidebar widget test**: Verify profile nav item exists, settings nav item removed
- **ProfileScreen widget test**: Verify Settings entry tile is present, tapping navigates to `/settings`
- **AppRouter test**: Verify `/profile` resolves as a shell page, `/settings` resolves correctly, deep links work
- **ProfileContent refactor**: Existing `profile_content` widget tests updated to reflect removed `showRefreshIndicator` and added Settings entry

`dart run build_runner build` required if any `@riverpod` annotations change (unlikely).

### III. User Experience Consistency

- [x] All new/updated user-facing strings use existing ARB keys (`profileTitle`, `settingsTitle`, `settingsAccountOpenProfile`). No new l10n keys needed for basic redesign.
- [x] Tappable controls use existing shared primitives (no new custom controls needed).
- [x] Haptics: `Haptics.selection` on new nav item taps (already used in sidebar).
- [x] Tooltips: existing sidebar nav items already use the nav label as tooltip text (implicit via `ListTile`).
- [x] Docs updates: `docs/features/settings.md` and `docs/features/auth.md`.

### IV. Performance Is a Requirement

- [x] Profile screen: existing content (hero card, stats, preferences, sign out) is lightweight with no new heavy widgets. 60fps scrolling expected.
- [x] Settings: no changes to search/rendering logic — existing <200ms search performance preserved.
- [x] Navigation: tab switching uses existing `context.go()` with fade transitions (~180ms) — no new animation overhead.

### V. Documentation and Traceability

- [x] Update `docs/features/auth.md` — Profile section: document new tab role; remove mention of two-pane Settings embedding.
- [x] Update `docs/features/settings.md` — Routes section: note Settings is now reached via Profile tab entry; update Account section description.
- [x] No new ADR required — this is a UI restructuring, not an architectural decision.
- [x] No constitution violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/001-profile-tab-redesign/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── routing/
│       └── app_router.dart                          # /profile → shell page; /settings → builder
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       ├── profile_screen.dart                   # Refactored: removed Scaffold/AppBar (tab shell supplies chrome)
│   │       └── widgets/
│   │           ├── profile_content.dart              # Refactored: remove showRefreshIndicator; add Settings entry tile
│   │           └── sidebar_account_chip.dart         # Minor: context.push → context.go for /profile
│   ├── player/
│   │   └── presentation/
│   │       ├── root_shell.dart                       # 4th destination → Profile icon/label/route
│   │       └── widgets/
│   │           └── app_sidebar.dart                  # Bottom nav item → Profile; sidebar chip unchanged
│   └── settings/
│       └── presentation/
│           └── widgets/
│               └── settings_layout_two_pane.dart     # Account pane: replace ProfileContent embed → link row
```

**Structure Decision**: No new features or directories. All changes are within existing feature areas and `lib/core/routing/`. The profile screen's `Scaffold`/`AppBar` is removed since `RootShell` already provides the page chrome as a shell tab.

## Complexity Tracking

No constitution violations — this section is not applicable.
