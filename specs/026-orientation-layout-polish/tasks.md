# Tasks: Phone / Tablet Orientation & Player Layout Polish

**Input**: Design documents from `/specs/026-orientation-layout-polish/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are required (spec QR-002, constitution II, plan Phase 0 R6). Write story tests so they fail before the matching implementation where practical.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Shared code**: `lib/core/platform/`
- **Player UI**: `lib/features/player/presentation/layouts/`
- **Tests**: `test/core/platform/`, `test/features/player/`
- **Feature docs**: `docs/features/player.md`, `docs/features/app-ui.md`
- **ADRs**: `docs/decisions/0059-phone-tablet-orientation-and-player-aspect-layout.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm scope and documentation targets before code changes

- [x] T001 Confirm target paths from plan: `lib/core/platform/`, `lib/main.dart`, `lib/features/player/presentation/layouts/video_player_layout.dart`, `ios/Runner/Info.plist`, and test dirs under `test/core/platform/` + `test/features/player/`
- [x] T002 [P] Identify doc/ADR deliverables: `docs/features/player.md`, `docs/features/app-ui.md`, and new `docs/decisions/0059-phone-tablet-orientation-and-player-aspect-layout.md`; skim [contracts/orientation-policy.md](contracts/orientation-policy.md) and [contracts/player-content-layout.md](contracts/player-content-layout.md)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Pure helpers shared by orientation policy and player layout — MUST complete before story wiring

**⚠️ CRITICAL**: No user story wiring (main / VideoPlayerLayout / Info.plist) until this phase is complete

- [x] T003 Create `DeviceFormFactor` enum, `kTabletShortestSideLogical` (600), and `resolveDeviceFormFactor` in `lib/core/platform/device_form_factor.dart` per [data-model.md](data-model.md) and [contracts/orientation-policy.md](contracts/orientation-policy.md)
- [x] T004 [P] Add `preferredOrientationsFor` (phone → portraitUp/Down; tablet → all four; desktop → null) in `lib/core/platform/device_form_factor.dart` (or adjacent helper in the same library)
- [x] T005 [P] Create `usePlayerSideBySideLayout({required double width, required double height})` in `lib/core/platform/player_content_layout.dart` per [contracts/player-content-layout.md](contracts/player-content-layout.md) (`width > height` → true)
- [x] T006 Export/document the helpers with brief dartdoc linking the 600 dp tablet threshold and square→stacked rule; ensure no widget imports in these pure files beyond `foundation` / `services` as needed for `TargetPlatform` / `DeviceOrientation`

**Checkpoint**: Pure APIs exist and compile; story implementation can begin

---

## Phase 3: User Story 1 - Phones stay upright; tablets may rotate (Priority: P1) 🎯 MVP

**Goal**: Phone-class devices lock to portrait app-wide; tablet-class devices allow auto-rotation; desktop skips orientation lock

**Independent Test**: On a phone with OS auto-rotate on, tilt while browsing — app stays portrait. On a tablet, rotate — app follows. Desktop windows remain freely resizable.

### Tests for User Story 1

- [x] T007 [P] [US1] Unit tests for `resolveDeviceFormFactor` and `preferredOrientationsFor` in `test/core/platform/device_form_factor_test.dart` (desktop always desktop; mobile &lt;600 phone; ≥600 tablet; orientation lists match contract)
- [x] T008 [P] [US1] Add a focused bootstrap helper testable without full `main` if extracted (e.g. `logicalShortestSideFromView` / `applyPreferredOrientationsForFormFactor`) in `lib/core/platform/device_form_factor.dart` + cases in `test/core/platform/device_form_factor_test.dart`; otherwise document manual-only verification for `SystemChrome` in the test file comment

### Implementation for User Story 1

- [x] T009 [US1] Wire bootstrap in `lib/main.dart`: after `WidgetsFlutterBinding.ensureInitialized()`, resolve form factor from primary view logical shortest side + `defaultTargetPlatform`, then `await SystemChrome.setPreferredOrientations(...)` when non-null; log failures with `logNamed` and never block `runApp`
- [x] T010 [US1] Tighten iPhone orientations in `ios/Runner/Info.plist` (`UISupportedInterfaceOrientations`) to portrait-only; leave `UISupportedInterfaceOrientations~ipad` allowing all orientations
- [x] T011 [US1] Smoke-check Android leaves orientation unlocked in `android/app/src/main/AndroidManifest.xml` (no `android:screenOrientation` lock); rely on `SystemChrome` per research R3

**Checkpoint**: US1 MVP — phone lock + tablet rotate policy applied at startup; unit tests green

---

## Phase 4: User Story 2 - Player video + transcript follow orientation (Priority: P1)

**Goal**: `VideoPlayerLayout` uses window aspect (landscape → side-by-side, portrait/square → stacked), not `breakpointTranscriptSideBySide`

**Independent Test**: Widget surfaces 800×1000 stack; 700×400 side-by-side; phones remain stacked under US1 lock. Transport bar may still use the 720 width breakpoint.

### Tests for User Story 2

- [x] T012 [P] [US2] Unit tests for `usePlayerSideBySideLayout` in `test/core/platform/player_content_layout_test.dart` (900×600 true; 800×1000 false; 700×400 true; 600×600 false)
- [x] T013 [P] [US2] Update widget expectations in `test/features/player/video_player_layout_test.dart` to the aspect fixtures in [contracts/player-content-layout.md](contracts/player-content-layout.md); remove assertions that treat width&gt;720 alone as side-by-side

### Implementation for User Story 2

- [x] T014 [US2] Replace the `breakpointTranscriptSideBySide` side-by-side gate in `lib/features/player/presentation/layouts/video_player_layout.dart` with `usePlayerSideBySideLayout(width: constraints.maxWidth, height: constraints.maxHeight)`
- [x] T015 [US2] Confirm `lib/features/player/presentation/widgets/global_transport_bar.dart` (and any other width packing) still uses `breakpointTranscriptSideBySide` — do not remove the token from `lib/core/theme/enjoy_tokens.dart`
- [x] T016 [US2] Run `flutter test test/core/platform/player_content_layout_test.dart test/features/player/video_player_layout_test.dart` and fix regressions until green

**Checkpoint**: US2 independently delivers aspect-based player content layout

---

## Phase 5: User Story 3 - Orientation changes stay calm and usable (Priority: P2)

**Goal**: Aspect/orientation switches do not clear the media session, jump progress, or strand an unusable transcript split

**Independent Test**: On tablet/desktop, play media with transcript, flip aspect several times — position stays continuous (±1s), cue findable, controls reachable; split width re-clamps sensibly in landscape

### Tests for User Story 3

- [x] T017 [P] [US3] Extend `test/features/player/video_player_layout_test.dart` to pump landscape → portrait → landscape and assert the layout widget (and stub transcript) remain mounted without requiring a new `VideoPlayerLayout` key/remount that would drop in-State `_transcriptWidthPx`
- [x] T018 [P] [US3] Add assertion or dedicated case that a user-set transcript split width survives a temporary stacked phase and re-applies (clamped) when returning to side-by-side in `test/features/player/video_player_layout_test.dart`

### Implementation for User Story 3

- [x] T019 [US3] Review `lib/features/player/presentation/layouts/video_player_layout.dart` State so aspect toggles only switch Row/Column branches — no engine recreate, no clearing `_transcriptWidthPx` on constraint changes; fix if any reset was introduced
- [x] T020 [US3] Walk [quickstart.md](quickstart.md) tablet rotate + desktop reshape playback scenarios; note any overflow or session glitches and fix in the player layout/chrome only if caused by this feature

**Checkpoint**: US3 stability guarantees hold with automation + manual quickstart notes

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Docs, ADR, and repo quality gates

- [x] T021 [P] Write ADR `docs/decisions/0059-phone-tablet-orientation-and-player-aspect-layout.md` (phone lock vs tablet rotate; aspect-based player split; 720 retained for transport); link from `docs/decisions/README.md` if that index lists ADRs
- [x] T022 [P] Update `docs/features/player.md` wide-layout section to describe orientation/aspect-driven stack vs side-by-side
- [x] T023 [P] Update `docs/features/app-ui.md` `VideoPlayerLayout` row to match the new rule
- [x] T024 Run full verification: `flutter analyze`, `flutter test`, and `bash .github/scripts/validate_ci_gates.sh` (or `--fix`); no `build_runner` unless annotations were added
- [x] T025 Complete remaining [quickstart.md](quickstart.md) manual phone/tablet/desktop checks and record pass/fail in the PR description

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS** all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (T003–T004 especially)
- **User Story 2 (Phase 4)**: Depends on Foundational (T005 especially); can proceed in parallel with US1 after Phase 2
- **User Story 3 (Phase 5)**: Depends on US2 implementation (T014); benefits from US1 on real phones
- **Polish (Phase 6)**: Depends on US1 + US2 (US3 recommended before merge)

### User Story Dependencies

- **User Story 1 (P1)**: After Foundational — no dependency on US2/US3
- **User Story 2 (P1)**: After Foundational — independently testable via widget sizes without device rotation
- **User Story 3 (P2)**: After US2 layout switch exists; validates stability of that switch

### Within Each User Story

- Tests marked first SHOULD fail before wiring/implementation where practical
- Pure helpers (Phase 2) before bootstrap / layout call sites
- Story complete before treating the next priority as done

### Parallel Opportunities

- T002 || T001 (docs skim vs path confirm)
- T004 || T005 after T003 started (orientations vs layout helper — different files)
- T007 || T008 (US1 tests)
- T012 || T013 (US2 tests)
- T017 || T018 (US3 tests)
- After Phase 2: US1 (T007–T011) and US2 (T012–T016) can run in parallel on different files
- T021 || T022 || T023 (docs/ADR)

---

## Parallel Example: User Story 1

```bash
# After Phase 2, in parallel:
Task: "Unit tests in test/core/platform/device_form_factor_test.dart"
Task: "Bootstrap SystemChrome wiring design notes / extract helper if needed"

# Then sequential:
Task: "Wire lib/main.dart orientation apply"
Task: "Tighten ios/Runner/Info.plist iPhone orientations"
```

## Parallel Example: User Story 2

```bash
# After Phase 2, in parallel:
Task: "Unit tests in test/core/platform/player_content_layout_test.dart"
Task: "Rewrite fixtures in test/features/player/video_player_layout_test.dart"

# Then sequential:
Task: "Switch predicate in video_player_layout.dart"
Task: "Confirm global_transport_bar.dart still uses 720 breakpoint"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational helpers
3. Complete Phase 3: User Story 1 (phone lock / tablet rotate)
4. **STOP and VALIDATE** on a phone + tablet (or simulators)
5. Demo orientation policy even before player layout changes

### Incremental Delivery

1. Setup + Foundational → pure APIs ready
2. US1 → shippable orientation policy MVP
3. US2 → player aspect layout (largest UX fix for tablets)
4. US3 → harden rotation/session stability
5. Polish → ADR + feature docs + CI gates

### Parallel Team Strategy

1. Together: Phase 1–2
2. Dev A: US1 (`main.dart`, Info.plist, form-factor tests)
3. Dev B: US2 (`player_content_layout.dart`, `video_player_layout.dart`, layout tests)
4. Together: US3 + Polish

---

## Notes

- [P] tasks = different files, no dependencies on incomplete sibling tasks
- Do **not** remove `breakpointTranscriptSideBySide` from tokens — transport packing still needs it
- No new Settings UI or ARB strings in v1
- No `build_runner` unless a `@Riverpod` annotation is introduced (prefer pure functions)
- Commit after each task or logical group; stop at checkpoints to validate independently
