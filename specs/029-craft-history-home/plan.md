# Implementation Plan: Craft History & First-Class Entry

**Branch**: `029-craft-history-home` | **Date**: 2026-07-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/029-craft-history-home/spec.md`

## Summary

Promote Craft to a first-class Home entry (button beside Import + global hotkey `c`), add a Craft-branded history list of saved `provider == 'craft'` library items with reopen-to-edit, update-in-place save via a new repository update API, and brand Chinese product surfaces with Latin **Craft** (retire 自制). No draft persistence; no new shell tab; library remains the system of record.

## Technical Context

**Language/Version**: Dart 3.x / Flutter (stable channel per repo)

**Primary Dependencies**: Flutter, Riverpod, go_router, Drift (`AppDatabase`), existing Craft Express/Advanced (`CraftController`), hotkeys module, ARB l10n

**Storage**: Existing Drift `Audios` + `Transcripts` rows (`provider = 'craft'`); no new tables. New **update-by-id** path for edit saves.

**Testing**: `flutter test` (unit + widget), `flutter analyze`, `bash .github/scripts/validate_ci_gates.sh --fix` before push; codegen only if new `@Riverpod` / Drift annotations require it

**Target Platform**: Android, iOS, macOS, Windows, Linux (no web)

**Project Type**: Cross-platform Flutter desktop/mobile app

**Performance Goals**: History open + first paint of filtered Craft list &lt; 300ms for typical libraries (&lt;200 Craft items); hotkey→Craft navigation feels &lt;1s (SC-002); no expensive work inside list tile `build` beyond displaying already-loaded fields

**Constraints**: Single `media_kit` player ownership unchanged; no `print()`; persistence only via Drift DAOs/repos; global hotkey must not steal text-field input; edit save must not create unexplained duplicate Craft rows (FR-012)

**Scale/Scope**: Home trailing + hotkey + Craft history UI + controller load/edit + repo update + l10n/docs/ADR; Library header Craft parity out of scope

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Plan response |
|-----------|--------|---------------|
| I. Architecture | Pass | Craft history/edit in `lib/features/craft/`; list via library repository; Home CTA in `library` presentation; hotkey in `hotkeys`; no feature↔feature shortcuts beyond existing routing |
| II. Testing | Pass | Unit tests for `loadForEdit` / update save / history filter; widget tests for Home Craft CTA, history empty/list, hotkey description registration; repo update tests |
| III. UX consistency | Pass | `EnjoyPage` / `EmptyState` / `EnjoyButton` or outlined buttons; tooltips on icon-only history; ARB strings; update `docs/features/craft.md` |
| IV. Performance | Pass | Filter/sort on watched stream; budget noted above; escalate to DAO `WHERE provider` if needed |
| V. Documentation | Pass | ADR-0061 + craft feature doc; hotkey listed in bindings help via definitions |
| Flutter Quality Gates | Pass | `validate_ci_gates.sh --fix`, analyze, test; no web |

**Post-design re-check**: Pass — contracts stay inside craft/library/hotkeys; update API is repository-owned; no unjustified complexity.

## Project Structure

### Documentation (this feature)

```text
specs/029-craft-history-home/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── README.md
│   ├── home-craft-entry.md
│   ├── craft-history-edit.md
│   └── localization-branding.md
└── tasks.md             # /speckit-tasks (not this command)
```

### Source Code (repository root)

```text
lib/features/library/presentation/
  home_screen.dart                 # Craft + Import trailing Row
  library_actions.dart             # Import Craft row copy (kept)

lib/features/hotkeys/
  domain/hotkey_definitions.dart   # global.craft
  presentation/app_hotkeys_keyboard_listener.dart
  presentation/hotkeys_description.dart

lib/features/craft/
  application/craft_controller.dart
  domain/craft_job_state.dart
  presentation/craft_screen.dart
  presentation/craft_history_*.dart  # new list UI

lib/features/library/
  application/library_media_provider.dart  # craftHistoryProvider (or craft app provider)
  data/library_repository.dart             # updateCraftedFromText, get craft row helpers

lib/core/routing/app_router.dart           # optional /craft/history route

lib/l10n/app_en.arb
lib/l10n/app_zh.arb
lib/l10n/app_zh_CN.arb

docs/features/craft.md
docs/decisions/0061-craft-first-class-history.md
docs/decisions/README.md

test/features/craft/...
test/features/library/...
test/features/hotkeys/...
```

**Structure Decision**: Extend existing feature modules; history UI lives under `craft/presentation`; persistence extensions stay on `MediaLibraryRepository` (library data layer) consumed by Craft application code.

## Complexity Tracking

> No constitution violations requiring justification.

## Phase 0 / Phase 1 outputs

- [research.md](./research.md) — decisions R1–R9
- [data-model.md](./data-model.md) — entities + edit/save transitions
- [contracts/](./contracts/) — Home entry, history/edit APIs, branding strings
- [quickstart.md](./quickstart.md) — manual + automated validation

## Implementation notes (for `/speckit-tasks`)

1. **P1**: Home Craft button + `global.craft` hotkey + l10n product-name updates (can ship independently).
2. **P2**: History list provider + UI + empty state.
3. **P2**: `loadForEdit` + `updateCraftedFromText` + save branch + tests.
4. **P3**: Finish ZH `自制` retirement audit; ADR + feature docs.
5. Verification: analyze, targeted tests, `validate_ci_gates.sh --fix`.
