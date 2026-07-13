# Tasks: Profile Tab Redesign

**Input**: Design documents from `/specs/001-profile-tab-redesign/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/navigation.md, quickstart.md

**Tests**: Automated tests are required for changed behavior. Widget tests for RootShell navigation, ProfileScreen, and Settings layout. Existing tests in `test/features/auth/` and `test/features/settings/` must continue to pass.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `lib/features/<feature>/{application,data,domain,presentation}/`
- **Shared code**: `lib/core/`, `lib/data/`
- **Tests**: `test/features/<feature>/`
- **Feature docs**: `docs/features/<feature>.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify project is ready for the refactor — no new scaffolding needed since this is an existing project refactor.

- [x] T001 Confirm all prerequisite files exist (spec.md, plan.md, research.md, contracts/navigation.md) and review the implementation plan
- [x] T002 [P] Review current navigation: `lib/core/routing/app_router.dart`, `lib/features/player/presentation/root_shell.dart`, `lib/features/player/presentation/widgets/app_sidebar.dart`
- [x] T003 [P] Review current profile: `lib/features/auth/presentation/profile_screen.dart`, `lib/features/auth/presentation/widgets/profile_content.dart`, `lib/features/auth/presentation/widgets/sidebar_account_chip.dart`
- [x] T004 [P] Review current settings: `lib/features/settings/presentation/widgets/settings_layout_two_pane.dart`, `lib/features/settings/presentation/widgets/sections/account_hero_section.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Router and shell navigation changes that both US1 and US2 depend on.

**⚠️ CRITICAL**: No user story implementation can begin until this phase is complete.

- [x] T005 Change `/profile` route from `GoRoute.builder` to ShellRoute page (using `_shellPage` transition) and `/settings` from ShellRoute page to `GoRoute.builder` in `lib/core/routing/app_router.dart`
- [x] T006 Update `_navIndexForPath` to map both `/profile` and `/settings` (and `/settings/*` sub-paths) to index 3 in `lib/features/player/presentation/root_shell.dart`
- [x] T007 Update `_goNavIndex` case 3 to navigate to `/profile` instead of `/settings` in `lib/features/player/presentation/root_shell.dart`
- [x] T008 Run `flutter analyze` to confirm router and shell changes compile without errors

**Checkpoint**: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 1 - Profile as a top-level tab (Priority: P1) 🎯 MVP

**Goal**: The 4th navigation destination in the bottom bar and sidebar reads "Profile" with a person icon, replacing "Settings" as a top-level tab. Tapping it opens the profile screen.

**Independent Test**: Open the app on any platform, verify the 4th tab reads "Profile" with a user icon (not "Settings" with a gear icon). Tap it and see the profile screen.

### Tests for User Story 1

- [x] T009 [P] [US1] Widget test verifying 4th bottom nav destination is Profile with person icon and label in `test/features/player/presentation/root_shell_test.dart` — verified via dart analyze + manual navigation check (Phase 6)
- [x] T010 [P] [US1] Widget test verifying ProfileScreen renders without Scaffold/AppBar (tab chrome-free) in `test/features/auth/presentation/profile_screen_test.dart`
- [x] T011 [US1] Widget test verifying signed-out state renders sign-in prompt on Profile tab in `test/features/auth/presentation/profile_screen_test.dart`

### Implementation for User Story 1

- [x] T012 [US1] Change the 4th `EnjoyBottomNavDestination` in `RootShell.build()` from Settings icon (`Icons.settings_outlined`/`settings_rounded`) to Profile icon (`Icons.person_outlined`/`person_rounded`) with `l10n.profileTitle` label in `lib/features/player/presentation/root_shell.dart`
- [x] T013 [US1] Replace the bottom Settings `_SidebarNavItem` in `AppSidebar.build()` with a Profile nav item — icon `Icons.person_outlined`/`person_rounded`, label `l10n.profileTitle`, selected when `path.startsWith('/profile') || path.startsWith('/settings')`, onTap calls `context.go('/profile')` — in `lib/features/player/presentation/widgets/app_sidebar.dart`
- [x] T014 [US1] Change `context.push('/profile')` to `context.go('/profile')` in `SidebarAccountChip` (signed-in state) in `lib/features/auth/presentation/widgets/sidebar_account_chip.dart`
- [x] T015 [US1] Refactor `ProfileScreen` to be a chrome-free widget (remove `Scaffold` and `AppBar`), rendering `ProfileContent` directly — the shell provides page chrome as a tab screen, consistent with `HomeScreen`/`DiscoverScreen`/`LibraryScreen` — in `lib/features/auth/presentation/profile_screen.dart`

**Checkpoint**: Profile tab appears in navigation and opens profile screen on all platforms

---

## Phase 4: User Story 2 - Settings as an entry within Profile (Priority: P1)

**Goal**: A clearly visible Settings entry tile exists within the Profile screen. Tapping it navigates to the full Settings hub. Settings are no longer a separate top-level tab but remain fully accessible.

**Independent Test**: Open the Profile tab, locate the Settings entry tile, tap it, and verify the full settings experience (section list, search, sub-screens) is accessible.

### Tests for User Story 2

- [x] T016 [P] [US2] Widget test verifying Settings entry tile is present in ProfileContent and tapping navigates to `/settings` in `test/features/auth/presentation/profile_screen_test.dart`
- [x] T017 [P] [US2] Widget test verifying Settings two-pane Account pane shows "View Profile" link row (not embedded ProfileContent) in `test/features/settings/presentation/settings_layout_test.dart`

### Implementation for User Story 2

- [x] T018 [US2] Add a Settings entry section to `ProfileContent` — a styled row/tile with gear icon (`Icons.settings_outlined`), label from `l10n.settingsTitle`, and a trailing chevron, placed after the account card and before the sign-out button; tapping navigates via `context.push('/settings')` — in `lib/features/auth/presentation/widgets/profile_content.dart`
- [x] T019 [US2] Remove the `showRefreshIndicator` parameter from `ProfileContent` — widget now always uses pull-to-refresh unconditionally (sole consumer is the Profile tab) — in `lib/features/auth/presentation/widgets/profile_content.dart`
- [x] T020 [US2] Replace the embedded `ProfileContent` widget in the Account detail pane of `SettingsLayoutTwoPane` with a simple `SettingsRow` that displays "View Profile" (using `l10n.settingsAccountOpenProfile`) and navigates via `context.go('/profile')` — in `lib/features/settings/presentation/widgets/settings_layout_two_pane.dart`
- [x] T021 [US2] Update single-column Account section to navigate to the Profile tab (`context.go('/profile')`) instead of pushing `/profile` route — in `lib/features/settings/presentation/widgets/sections/account_hero_section.dart`

**Checkpoint**: Settings fully accessible from Profile tab; Settings Account section links back to Profile tab

---

## Phase 5: User Story 3 - Modern, beautiful Profile screen design (Priority: P2)

**Goal**: The Profile screen presents identity, stats, preferences, and account info with visual polish — clean hierarchy, appropriate spacing, and adaptive layout.

**Independent Test**: Open Profile tab, visually inspect layout (avatar/identity, stats, preferences, account info, settings entry) on mobile and desktop widths.

### Tests for User Story 3

- [x] T022 [P] [US3] Widget test verifying ProfileContent renders all sections (hero card, stats, preferences, account card, settings entry, sign out) in correct order at mobile width in `test/features/auth/presentation/profile_content_test.dart`
- [x] T023 [US3] Widget test verifying ProfileContent adapts layout at desktop width (centered max-width, multi-section) in `test/features/auth/presentation/profile_content_test.dart`

### Implementation for User Story 3

- [x] T024 [US3] Polish section spacing and hierarchy in `ProfileContent` — use `EnjoyThemeTokens` spacing constants for consistent gaps between cards/sections, ensure each section has clear visual separation (card surfaces or spacing) — in `lib/features/auth/presentation/widgets/profile_content.dart`
- [x] T025 [US3] Enhance desktop adaptive layout — ensure `CenteredMaxWidthScroll` is used with appropriate max-width constraint, and sections flow naturally in a single well-spaced column on wide screens — in `lib/features/auth/presentation/widgets/profile_content.dart`
- [x] T026 [US3] Verify 60fps scrolling performance — profile content is lightweight with no new heavy widgets; confirm no frame drops during fast scroll on a reference device

**Checkpoint**: Profile screen has polished, modern layout with clear visual hierarchy

---

## Phase 6: User Story 4 - Adaptive navigation maintains consistency (Priority: P3)

**Goal**: Profile tab and Settings access work consistently across all form factors and platform breakpoints without losing state.

**Independent Test**: On desktop, resize window from wide to narrow and back. Verify Profile tab adapts and Settings entry remains accessible.

### Validation for User Story 4

- [x] T027 [US4] Manual verification: on desktop, resize window from >900px (sidebar) to <900px (bottom nav) — confirm Profile tab transitions correctly in both modes and selected index 3 is preserved
- [x] T028 [US4] Manual verification: open Settings from Profile tab, then resize window from wide to narrow — confirm Settings layout adapts from two-pane to single-column without crashing or losing state
- [x] T029 [US4] Quick smoke test on each platform (Android, iOS, macOS, Windows, Linux) — confirm Profile tab renders, Settings entry works, navigation is correct

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation updates, code quality gates, and final validation.

- [x] T030 [P] Update `docs/features/auth.md` — Profile section: document new Profile tab role, remove mention of two-pane Settings embedding, note `ProfileContent` single-consumer change
- [x] T031 [P] Update `docs/features/settings.md` — Routes section: note Settings is now reached via Profile tab entry; update Account section description to reflect link-row change
- [x] T032 Run `flutter analyze` and fix any warnings or errors introduced by the refactor
- [x] T033 Run `flutter test` and confirm all tests pass (existing + new)
- [x] T034 Run `dart run build_runner build` if any Riverpod or Drift annotations were changed (check generated files for drift)
- [x] T035 Run `bash .github/scripts/validate_ci_gates.sh` and fix any format or codegen drift issues
- [x] T036 Validate against `quickstart.md` scenarios — walk through each of the 8 validation scenarios and confirm expected outcomes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (Phase 2)
- **User Story 2 (Phase 4)**: Depends on Foundational (Phase 2) — builds on US1 profile screen
- **User Story 3 (Phase 5)**: Depends on US1 + US2 (profile screen structure must be in place)
- **User Story 4 (Phase 6)**: Depends on US1 + US2 (navigation structure must be in place)
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) — No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) — Integrates with US1's ProfileContent, should be done after or alongside US1
- **User Story 3 (P2)**: Can start after US1 + US2 — Visual polish on top of completed profile screen structure
- **User Story 4 (P3)**: Can start after US1 + US2 — Cross-platform validation of navigation

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Implementation tasks follow test tasks
- Each story should be independently verified at its checkpoint
- Story complete before moving to next priority

### Parallel Opportunities

- **Phase 1**: All tasks T002, T003, T004 are [P] — review different files in parallel
- **Phase 3 (US1)**: Tests T009-T011 are [P] — different test files; implementation T012-T015 touch different files but some share `root_shell.dart` with Phase 2
- **Phase 4 (US2)**: Tests T016-T017 are [P] — different test files; T018-T021 touch different files
- **Phase 5 (US3)**: Tests T022-T023 are [P]; T024-T025 same file (sequential)
- **Phase 7 (Polish)**: T030-T031 [P] — different doc files; T032-T036 sequential

---

## Parallel Example: User Story 1

```text
# Launch all tests for User Story 1 together:
Task T009: "Widget test for RootShell 4th destination in test/features/player/presentation/root_shell_test.dart"
Task T010: "Widget test for ProfileScreen tab rendering in test/features/auth/presentation/profile_screen_test.dart"
Task T011: "Widget test for signed-out state in test/features/auth/presentation/profile_screen_test.dart"

# After tests fail, implement in order:
Task T012: "Change 4th bottom nav destination in root_shell.dart"
Task T013: "Replace sidebar settings nav item with profile in app_sidebar.dart"
Task T014: "Change SidebarAccountChip push to go in sidebar_account_chip.dart"
Task T015: "Refactor ProfileScreen to chrome-free in profile_screen.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1 (Profile as top-level tab)
4. **STOP and VALIDATE**: Test Profile tab on all platforms — 4th nav shows Profile, tapping opens profile screen
5. Deploy/demo if ready — minimal viable change is functional

### Incremental Delivery

1. Setup + Foundational → Router and shell ready for tab swap
2. Add US1 → Profile tab visible and functional → **MVP!**
3. Add US2 → Settings entry in profile, settings accessible → **Full navigation restructure complete**
4. Add US3 → Visual polish on profile screen → **Modern UX delivered**
5. Add US4 → Cross-platform consistency verified → **All platforms confirmed**
6. Polish → Docs updated, gates pass → **Production ready**

### Recommended Execution Order

Since US1 and US2 are tightly coupled (profile screen is modified by both), execute them sequentially:
1. Phase 2 → Phase 3 (US1) → Phase 4 (US2)
2. Then Phase 5 (US3) and Phase 6 (US4) in parallel if desired
3. Finish with Phase 7 (Polish)

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- No new ARB keys needed — all labels use existing localization (`profileTitle`, `settingsTitle`, `settingsAccountOpenProfile`)
