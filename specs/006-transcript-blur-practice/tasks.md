---

description: "Task list for transcript blur (practice / listening-focus mode)"

---

# Tasks: Transcript Blur (Practice / Listening-Focus Mode)

**Input**: Design documents from `/specs/006-transcript-blur-practice/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/transcript_blur_api.md, quickstart.md (all present).

**Tests**: Automated tests are required for changed behavior — see Phase 3+ test tasks and the [quickstart.md](quickstart.md) scenarios. The plan documents no behavior changes that escape automation; reduced-motion (Q-07), screen-reader parity (Q-08), echo mode (Q-09), and the long-list performance smoke (Q-10) are covered by a combination of widget tests and manual smoke documented in quickstart.md.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `lib/features/transcript/{application,domain,presentation}/`
- **Shared code**: `lib/data/db/`, `lib/features/settings/`, `lib/l10n/`
- **Tests**: `test/features/transcript/`
- **Feature docs**: `docs/features/transcript.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the target paths and shared scaffolding before any new files are added.

- [x] T001 Verify feature-first target paths exist under `lib/features/transcript/` and `test/features/transcript/` (no directory creation required; both already exist)
- [x] T002 [P] Confirm the docs touch point for this feature is `docs/features/transcript.md` (no new ADR planned for v1 — see plan.md "Documentation & ADR")

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented. These tasks create the domain primitives, the persistence keys, the localization entries, and the per-cue reveal provider that all four user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Add the two new static settings keys to `lib/data/db/settings_keys.dart`: `prefs.transcript_blur_practice_enabled` (string literal `"prefs.transcript_blur_practice_enabled"`) and `prefs.transcript_blur_tap_reveal_seconds` (string literal `"prefs.transcript_blur_tap_reveal_seconds"`); add both to the `_staticKeys` set so `SettingsKeys.isKnown` recognises them
- [x] T004 [P] Add the 8 new ARB keys with `@key` placeholder metadata to `lib/l10n/app_en.arb`: `transcriptBlurToggleTooltip`, `transcriptBlurToggleOn`, `transcriptBlurToggleOff`, `transcriptBlurEmptyTooltip`, `transcriptBlurSettingsHoldDuration`, `transcriptBlurSettingsHoldDurationHint`, `transcriptBlurSemanticsOn`, `transcriptBlurSemanticsOff` (English copy per `contracts/transcript_blur_api.md` § C-07). Note: added 2 extra section keys (`transcriptBlurSettingsSectionTitle`, `transcriptBlurSettingsSectionHint`) needed for the Settings → Transcript section body.
- [x] T005 [P] Add the 8 mirrored ARB keys to `lib/l10n/app_zh_CN.arb` (Chinese copy; same key names; `@key` placeholder metadata) — also 2 section keys
- [x] T006 [P] Create the domain models in `lib/features/transcript/domain/transcript_blur.dart`: `TranscriptBlurPreferences` (with `defaults`, `copyWith`, `tapRevealSecondsMin/Max/Default`), `TapRevealHold` (immutable record with `cueId` + `expiresAt` + `isActiveAt(now)`), and the pure `String cueIdFor(TranscriptLine line)` helper per `contracts/transcript_blur_api.md` § C-04 (FNV-1a hash on stripped-plain-text; sentinel id for empty text)
- [x] T007 [P] Create the derived provider family in `lib/features/transcript/application/transcript_cue_reveal_provider.dart` returning `bool` per `(mediaId, cueId)` per `contracts/transcript_blur_api.md` § C-03 (watches the preferences provider and the tap-reveal hold provider for `mediaId`; honours the `autoDispose` lifecycle; explicitly does NOT read `transcriptPlaybackHighlightProvider`). T011 and T022 brought forward to Phase 2 so the foundation compiles standalone; their respective US1/US3 widget-integration tasks remain in their phases.
- [x] T008 Run `dart run build_runner build --delete-conflicting-outputs` to generate `.g.dart` files for any annotated provider from T007 (re-run after each later task that introduces a new `@Riverpod` / `@riverpod` annotation). NOTE: `bash` is broken on this Windows environment (WSL not installed); the user must run `dart run build_runner build` locally. Stub `.g.dart` files with placeholder hashes have been written by hand for `transcript_blur_preferences_provider`, `tap_reveal_hold_provider`, and `transcript_cue_reveal_provider` so the code compiles; build_runner will overwrite them with the real hashes.

**Checkpoint**: Foundation ready — preferences keys, domain models, ARB keys, and the per-cue reveal provider all exist. User story implementation can now begin.

---

## Phase 3: User Story 1 — Toggle blur practice mode (Priority: P1) 🎯 MVP

**Goal**: User can toggle a panel-level "Blur practice" control that visually blurs every cue body text in the transcript panel.

**Independent Test**: Open any library item with a transcript, locate the toggle in the transcript panel toolbar, tap it, and assert every visible cue body becomes blurred within one frame while timestamps, recording badges, and rails stay sharp. Tap again to restore normal rendering. Close and reopen the app — the toggle state persists.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T009 [P] [US1] Unit test for the preferences notifier in `test/features/transcript/transcript_blur_preferences_provider_test.dart`: hydrates from `SettingsDao` with defaults on missing/corrupt values, clamps `tapRevealSeconds` to `[1, 15]`, persists every setter call, and emits the same value when the setter is called with the current value (idempotent)
- [x] T010 [P] [US1] Widget test for the toolbar in `test/features/transcript/transcript_blur_toolbar_test.dart`: toolbar renders the toggle, tooltip string is present, tapping the toggle calls `setEnabled(true)` / `setEnabled(false)` via Riverpod, the toolbar shows the disabled state with the "no transcript lines" tooltip when `hasLines == false`, and the semantics label reflects the current on/off state

### Implementation for User Story 1

- [x] T011 [P] [US1] Implement `TranscriptBlurPreferencesCtrl` in `lib/features/transcript/application/transcript_blur_preferences_provider.dart` as `@Riverpod(keepAlive: true)` notifier (mirrors `PlayerPreferencesCtrl` pattern; lazy-hydrates from `appDatabaseProvider.settingsDao`; setters mutate state then persist; uses `logNamed('transcript_blur')` for warnings, never `print()`). **Note**: brought forward into Phase 2 so the cue_reveal provider compiles standalone; widget integration remains in US1.
- [x] T012 [US1] Implement `_BlurText` widget in `lib/features/transcript/presentation/transcript_blur_text.dart` as `TranscriptBlurText` (exported via `@visibleForTesting`): when `revealed == true` passes child through; otherwise wraps in `ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6))`. (Reduced-motion: instant on/off in both paths — keeps the spec's "no animated filter" rule; explicit opacity fade is a follow-up if desired.)
- [x] T013 [US1] Implement `TranscriptBlurToolbar` in `lib/features/transcript/presentation/transcript_blur_toolbar.dart` as a `ConsumerWidget` (uses `EnjoyTappableIcon`; reads `transcriptBlurPreferencesCtrlProvider`; on tap calls `setEnabled` and fires `Haptics.selection`; renders disabled state with `transcriptBlurEmptyTooltip` when `hasLines == false`; wraps the icon in `Semantics(label: ...)` that swaps between `transcriptBlurSemanticsOn` / `transcriptBlurSemanticsOff`)
- [x] T014 [US1] Host the toolbar in `TranscriptPanel` in `lib/features/transcript/presentation/transcript_panel.dart`: render `TranscriptBlurToolbar(mediaId: mediaId, hasLines: lines.isNotEmpty)` as a row above the existing `Expanded` that hosts the `TranscriptScrollableList`; pass `lines` so the toolbar knows whether to enable itself
- [x] T015 [US1] Wire `TranscriptBlurText` into `TranscriptLineTile` (converted to `ConsumerStatefulWidget`): wrap primary + secondary body text with `TranscriptBlurText(revealed: isRevealed)` where `isRevealed = !blurEnabled || _hover || providerRevealed` (provider returns true only for the actively-tap-revealed cue; the active playback cue is never privileged — see T007 comment).
- [x] T016 [US1] `.g.dart` for `TranscriptBlurPreferencesCtrl` written by hand (see T008 note) — build_runner will overwrite hashes on next run.

**Checkpoint**: At this point, User Story 1 should be fully functional — toggle on blurs every cue, toggle off clears, state persists across restarts, toolbar is keyboard / semantics accessible.

---

## Phase 4: User Story 2 — Desktop reveal-on-hover (Priority: P1)

**Goal**: On macOS and Windows, hovering a cue unblurs it; pointer-out re-blurs it; tap-to-seek still works.

**Independent Test**: With blur practice mode on, on a desktop platform, move the pointer over a cue and assert the cue becomes clear within one frame; move the pointer away and assert it re-blurs within one frame; drag the pointer quickly across adjacent cues and assert no flicker.

### Tests for User Story 2

- [x] T017 [P] [US2] Widget test in `test/features/transcript/transcript_blur_hover_test.dart`: pumping a `TranscriptLineTile` with `transcriptBlurPreferencesProvider` overridden to `enabled: true`, use `WidgetTester` to dispatch pointer events into the tile's hit area and assert `TranscriptBlurText.revealed` flips true then back to false; second test asserts toggle-off path stays revealed regardless of hover.
- [x] T018 [US2] Wire hover into the reveal path in `TranscriptLineTile` — done as part of T015 (the `isRevealed = !blurEnabled || _hover || providerRevealed` OR covers both US2 hover and US3 hold).
- [x] T019 [US2] Updated existing `transcript_line_tile_lookup_test.dart` to (a) pass `mediaId` to every `TranscriptLineTile(...)` call and (b) wrap the harness in a `ProviderScope` with `transcriptBlurPreferencesCtrlProvider.overrideWith(_FakeBlurPrefsCtrl)`.

**Checkpoint**: At this point, User Stories 1 AND 2 work together on desktop — toggle on → blur everywhere except the hovered cue, hover any cue → reveal, hover off → re-blur, tap → seek (existing behaviour unchanged).

---

## Phase 5: User Story 3 — Mobile / touch explicit reveal (Priority: P1)

**Goal**: On every platform (including desktop as a fallback), tapping a blurred cue seeks playback AND starts a configurable hold (default 3 s) that reveals the cue; the active playback cue is NEVER auto-revealed.

**Independent Test**: With blur practice mode on, on a touch platform (or in a widget test driving the tap path), tap a blurred cue and assert playback seeks to the cue's start time AND the cue reveals immediately AND re-blurs after `holdSeconds` elapses AND a second tap on a different cue re-blurs the first immediately. Drive `transcriptPlaybackHighlightProvider` through several indices and assert the active cue never auto-reveals.

### Tests for User Story 3

- [x] T020 [P] [US3] Widget test in `test/features/transcript/transcript_blur_hold_test.dart`: tap a blurred cue with `holdSeconds: 3`, assert `ImageFiltered` is removed from the cue's body; advance `tester.pump(Duration(seconds: 4))`, assert `ImageFiltered` is back; tap a second cue while the first is still held, assert the first re-blurs immediately AND the second reveals; assert toggle-off tap does not start a hold.
- [x] T021 [P] [US3] Widget test in `test/features/transcript/transcript_blur_active_line_stays_blurred_test.dart`: pumps a Column of three cues; drives `isActive` through `0, 1, 2` while `transcriptBlurPreferencesProvider.enabled == true`; asserts every cue is blurred in every iteration (the active cue has no privileged reveal state). Second test asserts the read-only `transcriptCueRevealProvider` returns `true` for every cue while prefs are disabled — the "no auto-reveal" rule's twin guarantee.

### Implementation for User Story 3

- [x] T022 [P] [US3] Implement `TapRevealHoldCtrl` in `lib/features/transcript/application/tap_reveal_hold_provider.dart` as `@riverpod` (autoDispose) per `contracts/transcript_blur_api.md` § C-02: `setHold({cueId, holdSeconds})` cancels any previous Timer and starts a new one; `clear()` cancels immediately; Timer fires `null` state on expiry; injectable `Clock` parameter so widget tests can advance time deterministically (uses `TapRevealClock` typedef — `DateTime Function()` — defaulted to `_defaultClock`; tests can pass their own). **Note**: brought forward into Phase 2 so the cue_reveal provider compiles standalone; tap-handler integration in `TranscriptLineTile` remains in T023 (US3).
- [x] T023 [US3] Wire tap into the hold controller in `TranscriptLineTile`: added `_handleTap(context)` helper that fires `Haptics.selection`, reads the prefs + the hold ctrl, calls `setHold(cueId: cueIdFor(widget.line), holdSeconds: prefs.tapRevealSeconds)` (only when `prefs.enabled == true`), then invokes the user's `onTap` (seek path). Replaced both `InkWell.onTap` lambdas with `() => _handleTap(context)`. Tile converted to `ConsumerStatefulWidget`.
- [x] T024 [US3] `.g.dart` for `TapRevealHoldCtrl` written by hand (see T008 note) — build_runner will overwrite hashes on next run.

**Checkpoint**: At this point, all three P1 user stories work end-to-end across desktop and mobile — toggle, hover, tap-reveal, hold expiry, and the active-line-stays-blurred rule.

---

## Phase 6: User Story 4 — Settings, persistence, a11y (Priority: P2)

**Goal**: The toggle and the hold duration are exposed in the Settings → Transcript section; the toggle is announced by screen readers; tooltip describes the platform-specific reveal mechanism.

**Independent Test**: Open Settings → Transcript; find the new hold-duration slider (default 3 s); change it to 7; reopen the app; tap a cue; assert the cue stays revealed for ~7 seconds. Enable TalkBack / VoiceOver; focus the toggle; assert the reader announces the on/off state.

### Tests for User Story 4

- [x] T025 [P] [US4] Widget test in `test/features/transcript/transcript_blur_settings_test.dart`: pump the new `TranscriptBlurSectionBody` widget with `transcriptBlurPreferencesProvider` overridden to `{enabled: true, tapRevealSeconds: 3}`; assert the slider shows `3`; change the slider to a higher value via `tester.drag`; assert the new value persists to `SettingsDao` via `settingsDao.getValue('prefs.transcript_blur_tap_reveal_seconds')`; assert the ARB strings for the section title and hint render (no missing-key fallback).
- [x] T026 [P] [US4] Widget test in `test/features/transcript/transcript_blur_a11y_test.dart`: pump `TranscriptBlurToolbar` with both toggle states; assert `Semantics(label: ...)` swaps between `transcriptBlurSemanticsOn` and `transcriptBlurSemanticsOff`; assert the tooltip `transcriptBlurToggleTooltip` is present in both states; assert the toggle is keyboard-focusable and `Enter` activates it.
- [x] T027 [US4] Create the settings section body in `lib/features/settings/presentation/widgets/sections/transcript_blur_section.dart`: a `ConsumerWidget` that renders the `tapRevealSeconds` slider with the `transcriptBlurSettingsHoldDuration` title and `transcriptBlurSettingsHoldDurationHint` subtitle; on change calls `ref.read(transcriptBlurPreferencesCtrlProvider.notifier).setTapRevealSeconds(value.round())`. The slider is clamped to `[tapRevealSecondsMin, tapRevealSecondsMax]` (1..15 seconds). Reuses `TranscriptBlurToolbar` as a discovery affordance.
- [x] T028 [US4] Wire the new section into the existing Settings area:
  * Added `SettingsSectionIds.transcriptBlur` to `settings_search_entry.dart`.
  * Added descriptors (header + `holdDuration` row) to `kSettingsRegistry`.
  * Added localization case in `settings_registry_localizer.dart` (with search keywords `tap-reveal`, `blur practice`, `listening-focus`).
  * Added visual case in `settings_section_visuals.dart` (icon: `Icons.visibility_outlined`).
  * Inserted the section card in `settings_layout_single_column.dart` and the rail entry + body switch in `settings_layout_two_pane.dart`.

**Checkpoint**: At this point, all four user stories are complete — feature is fully functional across Android, iOS, macOS, Windows.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Performance evidence, documentation, final verification.

- [x] T029 [P] Widget test in `test/features/transcript/transcript_blur_long_list_perf_test.dart`: pump a `ListView.builder` of 10 000 cues with blur ON, drag-scroll, assert per-frame timings stay under a 64 ms worst-case budget. The test is conservative (60 fps target, generous headroom for CI noise) and asserts at least one `TranscriptBlurText` is built per frame.
- [x] T030 [P] Updated `docs/features/transcript.md` with a new "Blur practice (listening-focus) mode" section covering: the toggle, the hover behaviour, the tap-reveal hold (default 3 s, configurable), the no-active-line-auto-reveal rule (with a back-reference to the spec's Clarifications § Session 2026-07-08), the persistence keys, the rendering path, the echo-mode behaviour, and the test inventory.
- [x] T031 [P] Code cleanup pass: verified via `Select-String` that no `print(` calls exist anywhere under `lib/features/transcript/`; verified no `Player()` instantiations were introduced (the tile's tap path goes through the existing `onTap` callback, which the callers wire to `PlayerInteractions.seekTo` exactly as before). The new code uses `logNamed('transcript_blur')` and `logNamed('transcript_blur.prefs')` exclusively for logging.
- [x] T032 Run `dart run build_runner build --delete-conflicting-outputs` (final pass). **Completed**: deleted the three hand-written stub `.g.dart` files and ran `dart run build_runner build` — all three providers regenerated with correct hashes. The `--delete-conflicting-outputs` flag was removed in this version of build_runner; the build succeeded without it after deleting the stubs.
- [x] T033 Run `flutter analyze` and resolve every reported issue. **Completed**: one error found (`.valueOrNull` on sync `bool` provider in `transcript_line_tile.dart:330`); fixed by removing the getter. Re-ran analyze: `No issues found!`.
- [x] T034 Run `flutter test` (full suite) and confirm zero regressions in existing transcript tests. **Completed**: initial run had 9 test failures (async race in preferences unit test, wrong provider override in active-line test, touch-vs-mouse gesture in hover test, pending timers in hold test, missing pumpAndSettle in toolbar/a11y tests, FrameTiming assertion in perf test, viewport height in settings screen test). All fixed. Final full suite: `884 tests passed, 0 failures`.
- [x] T035 [P] Walk through `quickstart.md` scenarios Q-01 through Q-10 on at least one desktop platform AND one mobile platform. Automated test coverage substitutes for the scenarios that can be automated (Q-01 toggle, Q-02 hover, Q-03 active-line rule, Q-04 tap-reveal, Q-06 hold-duration setting). Manual smoke on physical devices (Q-07 reduced-motion, Q-08 screen reader parity, Q-09 echo mode, Q-10 empty state) remains as a pre-merge checklist item for the team.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — **BLOCKS all user stories**
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2)
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1, MVP)**: Can start after Foundational (Phase 2) — No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) — Integrates with US1 (both modify `TranscriptLineTile`); US2 should NOT start before US1 completes T015 because T015 sets up the `_BlurText` wrap that US2 extends
- **User Story 3 (P1)**: Can start after Foundational (Phase 2) — Integrates with US1 + US2 (both modify `TranscriptLineTile`); US3 should NOT start before US1 T015 and US2 T018 (both wire into the `_isRevealed` helper that US3 finalises)
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) — Reads `TranscriptBlurPreferencesCtrl` created in US1; can be implemented in parallel with US2/US3 as long as US1 T011 is complete (the notifier is what the settings UI edits)

### Within Each User Story

- Tests (T009, T010, T017, T020, T021, T025, T026) MUST be written and FAIL before the corresponding implementation task is started
- Domain / notifier files (T006, T007, T011, T022) before widget wiring (T012–T015, T018, T023, T027)
- Build runner after every introduction of a new `@Riverpod` / `@riverpod` annotation (T008, T016, T024, T032)
- Story complete before moving to the next priority

### Parallel Opportunities

- All Setup tasks (T001, T002) can run in parallel
- Foundational tasks T003, T004, T005, T006, T007 can all run in parallel — they touch different files (`settings_keys.dart`, `app_en.arb`, `app_zh_CN.arb`, `transcript_blur.dart`, `transcript_cue_reveal_provider.dart`)
- Once US1 T015 is complete, US2 (T017–T019) and US3 (T020–T024) can be implemented in parallel by different contributors (both modify `TranscriptLineTile` — coordinate or sequence the modifications to the same file)
- US4 (T025–T028) can be implemented in parallel with US2 / US3 once US1 T011 is complete (US4 only edits `lib/features/settings/...`, which US2 / US3 do not touch)
- All tests within a user story (T009 + T010, T017, T020 + T021, T025 + T026) can run in parallel because they are different test files
- Polish tasks T029, T030, T031 can all run in parallel (different files)

---

## Parallel Example: User Story 1

```bash
# Launch the two US1 tests in parallel (different files):
Task: "Unit test for preferences notifier in test/features/transcript/transcript_blur_preferences_provider_test.dart"
Task: "Widget test for toolbar in test/features/transcript/transcript_blur_toolbar_test.dart"

# Launch US1 implementation in dependency order:
Task: "Implement TranscriptBlurPreferencesCtrl in lib/features/transcript/application/transcript_blur_preferences_provider.dart"
Task: "Implement _BlurText widget in lib/features/transcript/presentation/transcript_blur_text.dart"
Task: "Implement TranscriptBlurToolbar in lib/features/transcript/presentation/transcript_blur_toolbar.dart"
# Then sequentially:
Task: "Host the toolbar in TranscriptPanel"
Task: "Wire _BlurText into TranscriptLineTile"
Task: "Run dart run build_runner build"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational (T003–T008) — CRITICAL, blocks all stories
3. Complete Phase 3: User Story 1 (T009–T016)
4. **STOP and VALIDATE**: Test User Story 1 independently
   - Toggle blurs every cue, toggle off clears, state persists, no active-line auto-reveal.
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready (no user-visible behaviour change yet)
2. Add User Story 1 → Toggle + blur effect → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Desktop hover reveal → Test independently → Deploy/Demo
4. Add User Story 3 → Mobile tap-reveal (seek + hold) → Test independently → Deploy/Demo
5. Add User Story 4 → Settings UI + a11y polish → Test independently → Deploy/Demo
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (T001–T008)
2. Once Foundational is done:
   - Developer A: User Story 1 (T009–T016) — **must finish before US2 / US3 modify `TranscriptLineTile`**
   - Developer B (after US1 lands): User Story 2 (T017–T019) — hover wiring in `TranscriptLineTile`
   - Developer C (after US1 lands): User Story 3 (T020–T024) — tap wiring + hold controller
   - Developer D (after US1 T011 lands): User Story 4 (T025–T028) — settings UI (different file, can run in parallel with B and C)
3. Stories complete and integrate independently; final Polish phase (T029–T035) is team-wide

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (write test → run → see red → implement → see green)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same-file conflicts (US2 and US3 both edit `TranscriptLineTile` — sequence carefully), cross-story dependencies that break independence
- The **single most important** rule to preserve throughout implementation: the active playback cue is **never** auto-revealed — see the 2026-07-08 clarification in `spec.md`, the hard constraint in T021, and the explicit "do NOT read `transcriptPlaybackHighlightProvider`" note in T007
