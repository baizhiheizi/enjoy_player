<!--
Sync Impact Report
Version change: 1.0.0 -> 1.1.0
Modified principles:
- Flutter Quality Gates: require validate_ci_gates / format + codegen drift before push
Added sections:
- None
Removed sections:
- None
Templates requiring updates:
- ✅ AGENTS.md
- ✅ README.md
- ✅ docs/testing.md
- ✅ docs/conventions.md
- ✅ .cursor/rules/flutter.mdc
- ✅ .github/workflows/shared/runtime.md
Follow-up TODOs:
- None
-->
# Enjoy Player Constitution

## Core Principles

### I. Architecture and Code Quality
All production Dart code MUST follow the feature-first layout under
`lib/features/<feature>/{application,data,domain,presentation}` with shared
capabilities in `lib/core` or `lib/data`. Presentation code MUST stay UI-focused,
domain models MUST remain free of Flutter widget concerns, and persistence MUST
flow through Drift DAOs backed by `AppDatabase`. Riverpod providers and
notifiers are the standard orchestration mechanism; mutable global singletons
and feature-to-feature shortcuts require documented justification in the plan.

Rationale: predictable module boundaries keep playback, library, sync, and
learning features testable without coupling unrelated surfaces.

### II. Testing Defines the Contract
Every behavior change MUST include a test plan and the narrowest automated tests
that prove the changed contract. Pure logic, parsers, repositories, Drift DAOs,
Riverpod notifiers, and bug fixes require unit tests unless the implementation
plan documents why automation is impractical. User-facing flows with navigation,
input, localization, or platform chrome require widget or integration coverage
when the behavior cannot be proven with unit tests alone. Generated code changes
MUST run `dart run build_runner build` before analysis and tests.

Rationale: Enjoy Player is local-first and cross-platform; regressions in media,
transcripts, sync, or practice flows are expensive for users to diagnose after
release.

### III. User Experience Consistency
User-facing work MUST reuse established app primitives, localization, and
interaction patterns. New tappable UI uses `EnjoyTappableSurface`,
`EnjoyTappableIcon`, or `EnjoyButton` where those primitives fit. Icon-only
actions MUST expose tooltips, keyboard affordances MUST remain documented, and
light feedback MUST route through `Haptics`. User-visible strings MUST live in
ARB localization files and feature behavior changes MUST update the matching
document in `docs/features/`.

Rationale: consistent controls, feedback, and language keep the player usable
across Android, iOS, macOS, and Windows without one-off UI behavior.

### IV. Performance Is a Requirement
Plans and specifications MUST state performance goals for user-visible flows
that affect playback, startup, scrolling, transcript rendering, sync, or media
import. UI code MUST keep expensive work out of `build` methods and list/grid
item builders. Heavy file, image, transcript, database, or audio processing MUST
be cached, streamed, paged, debounced, or moved off the main isolate when it can
block frames. Performance fixes MUST include before/after evidence or a clear
manual verification path.

Rationale: a media-learning app loses trust when playback, transcript tracking,
or large libraries feel stalled, especially on Windows desktop.

### V. Documentation and Traceability
Architectural or product-scope decisions that are costly to reverse MUST be
recorded as ADRs in `docs/decisions/`. Feature behavior changes MUST update the
matching `docs/features/` page in the same change. Agent and contributor rules
MUST stay aligned across `AGENTS.md`, `README.md`, and `docs/`. Changes that
affect release, signing, CI, or platform support MUST update the relevant runbook
before they are considered complete.

Rationale: the project already relies on ADRs, feature specs, and runbooks to
coordinate native platforms and local-first data behavior.

## Flutter Quality Gates

Supported targets are Android, iOS, macOS, and Windows. Flutter web targets,
`web/` scaffolding, and `kIsWeb` branches are out of scope unless a superseding
ADR changes platform support. `media_kit` `Player` instances MUST be owned only
by `MediaKitPlayerEngine` or `PlayerController`; YouTube playback uses the
WebView engine. Logging MUST use `package:logging` through project logging
helpers, never `print()`.

Every implementation plan MUST identify the relevant verification commands from
this set: `bash .github/scripts/validate_ci_gates.sh` (or the underlying
`check_dart_format` / `check_codegen_drift` scripts) before push, `dart run
build_runner build` for Drift or Riverpod annotations with generated files
committed, `flutter analyze`, `flutter test`, targeted widget/integration
tests, and platform compile smoke tests for platform-specific changes. Skipping
a relevant gate requires an explicit risk note in the plan or pull request.

## Development Workflow

Work begins from a user story or feature spec with independently testable
acceptance criteria. Plans MUST pass the Constitution Check before research and
MUST be rechecked after design. Tasks MUST be grouped by user story and include
quality, test, UX, performance, documentation, and verification work as first
class tasks rather than final cleanup.

Reviewers MUST verify that module boundaries are preserved, tests cover the
changed contract, user-facing behavior follows shared UI patterns, performance
risks have evidence or a stated budget, and documentation changed with behavior.
Any accepted exception MUST name the principle, the reason, and the follow-up
owner or deadline.

## Governance

This constitution supersedes conflicting project practices, templates, and
informal instructions. Amendments require a documented diff, the semantic
version bump rationale, and updates to dependent templates or guidance files in
the same change.

Versioning policy:
- MAJOR: removes or redefines a principle in a backward-incompatible way.
- MINOR: adds a principle or materially expands governance or quality gates.
- PATCH: clarifies wording without changing required behavior.

Compliance review is required for every feature plan and code review. The
Constitution Check in `.specify/templates/plan-template.md` is the planning gate,
and `AGENTS.md`, `docs/conventions.md`, and `docs/testing.md` provide runtime
development guidance.

**Version**: 1.1.0 | **Ratified**: 2026-06-30 | **Last Amended**: 2026-07-09
