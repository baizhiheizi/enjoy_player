# Implementation Plan: Profile Update Form

**Branch**: `main` (spec directory `020-profile-update-form` is independent of git branch naming; create `020-profile-update-form` when implementing) | **Date**: 2026-07-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/020-profile-update-form/spec.md`

## Summary

Redesign account identity editing in Enjoy Player: the Profile hero shows **Enjoy ID** (not email); a dedicated **Edit profile** screen hosts username + avatar editing and read-only Enjoy ID / email / Mixin ID; Preferences keeps learning/display controls and drops username. Avatar persistence and Mixin ID values depend on [enjoy_web#227](https://github.com/baizhiheizi/enjoy_web/issues/227) — the client ships the form and username path immediately, gates avatar upload behind the new API contract, and shows a not-linked Mixin state until `mixinId` is returned.

## Technical Context

**Language/Version**: Dart ^3.12, Flutter stable (SDK constraint in `pubspec.yaml`)

**Primary Dependencies**: Riverpod 3 (`authCtrlProvider`, existing auth repository), go_router, `file_picker` (already pinned), `http` multipart via `ApiClient`, CachedNetworkImage / existing avatar URL helpers, shared UI (`EnjoyButton`, `EnjoyCard`, `EnjoyTappableSurface`, `SettingsRow`, `AppNotice`)

**Storage**: No new Drift tables. Profile snapshot remains in `flutter_secure_storage` via `SecureTokenStore` cached profile JSON (existing). Local avatar pick is ephemeral until a successful server save.

**Testing**: `flutter test` — unit tests for `UserProfile` JSON (`mixinId`), avatar request validation helpers; widget tests for hero Enjoy ID, edit-form field roles, preferences without username, save success/error feedback with faked `AuthRepository`

**Target Platform**: Android, iOS, macOS, Windows, Linux (no Flutter web). Image pick via `file_picker` (project already uses it for media import).

**Project Type**: Flutter native mobile/desktop app

**Performance Goals**: Edit profile opens interactively within 1s on a warm session; username save feedback within 3s under normal network (QR-004). Avatar upload shows in-progress UI; avoid decoding full images on the UI isolate beyond a small preview (cap client-side file size before upload).

**Constraints**: Login-only access (ADR-0031). Single authenticated profile API surface (`GET/PATCH /api/v1/profile` + forthcoming avatar path from #227). Do not edit `enjoy_web` from this repo. Do not invent Mixin IDs. Do not claim avatar save success without server confirmation.

**Scale/Scope**: One new route (`/profile/edit`), one new screen, hero + preferences surgery, domain field `mixinId`, AuthApi/repository avatar method, ~15–25 ARB keys × 3 locales, docs update to `docs/features/auth.md`. Backend dependency tracked externally.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- **Pass**: Changes stay in `lib/features/auth/{application,data,domain,presentation}`, `lib/data/api/services/auth_api.dart`, `lib/core/routing/app_router.dart`, and `lib/l10n/`.
- **Pass**: `UserProfile` / request models remain UI-free domain types.
- **Pass**: Profile mutations continue through `AuthRepository` + `authCtrlProvider` — no new mutable singletons.
- **Pass**: No `print()`; no `media_kit` `Player()` involvement.

### II. Testing Defines the Contract

- **Required**: Unit — `UserProfile.fromJson` reads `mixinId` / ignores absent; username validation (trim/non-empty); optional avatar file preflight (size/extension) pure helper.
- **Required**: Widget — `ProfileHeroCard` shows Enjoy ID not email; Edit profile shows editable vs read-only roles; Preferences no longer hosts the username field; save success updates hero after mocked `updateProfile`.
- **Manual**: Real device/desktop image pick + upload once #227 is deployed; cross-platform picker smoke on at least one mobile and one desktop OS.
- **Codegen**: Only if new `@riverpod` annotations are added; prefer reusing `authCtrlProvider` to avoid unnecessary codegen.

### III. User Experience Consistency

- **Pass**: New strings in `app_en.arb` / `app_zh.arb` / `app_zh_CN.arb`.
- **Pass**: Tappable avatar/edit entry uses `EnjoyTappableSurface` / `EnjoyButton` / existing row patterns; icon-only actions get tooltips.
- **Required**: Update `docs/features/auth.md` (Profile / Edit profile / Preferences split).

### IV. Performance Is a Requirement

- **Pass**: Avatar file size check before upload; preview uses file path / memory bytes already loaded for upload — no unbounded full-resolution decode in `build`.
- **Evidence**: Manual timing for open form + username save; upload progress indicator for large images.

### V. Documentation and Traceability

- **Required**: `docs/features/auth.md` — hero Enjoy ID, `/profile/edit`, Preferences without username, avatar/Mixin API dependency.
- **No new ADR**: Reversible UX/IA split within existing auth feature; avatar transport follows whatever #227 documents (multipart or signed blob). If #227 introduces a novel client upload pattern worth locking, file a thin ADR in the implementation PR — not required at plan time.
- **External**: [baizhiheizi/enjoy_web#227](https://github.com/baizhiheizi/enjoy_web/issues/227) for avatar + `mixin_id`.
- **No exception required.**

**Post-design re-check**: All gates pass. See [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md).

## Project Structure

### Documentation (this feature)

```text
specs/020-profile-update-form/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── profile-api.md
│   └── profile-edit-ui.md
└── tasks.md             # Phase 2 (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
lib/features/auth/
├── domain/
│   ├── user_profile.dart              # UPDATE — optional mixinId
│   ├── update_profile_request.dart    # unchanged for name; avatar via separate API method
│   └── avatar_pick_constraints.dart   # NEW — max bytes, allowed extensions (pure)
├── data/
│   └── auth_repository.dart           # UPDATE — updateAvatar(...) when API ready
├── application/
│   └── auth_controller.dart           # UPDATE — updateAvatar forwarding
└── presentation/
    ├── profile_edit_screen.dart       # NEW — Edit profile form
    ├── profile_preferences_screen.dart # UPDATE — remove username field
    ├── widgets/
    │   ├── profile_hero_card.dart     # UPDATE — Enjoy ID; optional tap → edit
    │   ├── profile_content.dart       # UPDATE — Edit profile entry
    │   └── profile_identity_row.dart  # NEW (optional) — read-only labeled row + copy
    └── …

lib/data/api/services/
└── auth_api.dart                      # UPDATE — uploadAvatar / parse mixinId via profile JSON

lib/core/routing/
└── app_router.dart                    # UPDATE — /profile/edit child route

lib/l10n/
├── app_en.arb / app_zh.arb / app_zh_CN.arb

test/features/auth/
├── domain/user_profile_test.dart      # UPDATE or NEW
├── domain/avatar_pick_constraints_test.dart  # NEW
└── presentation/
    ├── profile_hero_card_test.dart    # NEW/UPDATE
    ├── profile_edit_screen_test.dart  # NEW
    └── profile_preferences_screen_test.dart  # UPDATE — no username

docs/features/auth.md                  # UPDATE
```

**Structure Decision**: Keep all identity UI in the existing `auth` feature. Prefer a new `/profile/edit` sibling of `/profile/preferences` over overloading Preferences. Abstract avatar upload in `AuthRepository` so the presentation layer does not hard-code multipart vs signed-blob once #227 lands.

## Complexity Tracking

> No constitution violations.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|---------------------------------------|
| — | — | — |

## Implementation Phases (for `/speckit-tasks`)

### Phase A — Enjoy ID + Edit profile shell (no backend wait)

1. Hero secondary line → Enjoy ID (`profile.id`).
2. Route `/profile/edit` + `ProfileEditScreen` with username save via existing `PATCH` / `UpdateProfileRequest(name:)`.
3. Read-only rows: Enjoy ID, email, Mixin (not-linked until `mixinId` present).
4. Remove username from Preferences; keep goal/languages.
5. Entry point from Profile (tap hero and/or Edit profile row).
6. Tests + ARB + `docs/features/auth.md` partial update.

### Phase B — Avatar + Mixin ID (depends on enjoy_web#227)

1. Parse `mixinId` on `UserProfile`; show value when present.
2. Implement `AuthApi`/`AuthRepository` avatar upload per finalized #227 contract.
3. `file_picker` → preview → validate → upload with progress → refresh auth state.
4. Failure paths (cancel, oversize, network, API unavailable).
5. Widget/unit tests with fakes; manual cross-platform picker smoke.

### Phase C — Polish & verify

1. Copy affordances for Enjoy ID / Mixin ID.
2. Full CI gates: `bash .github/scripts/validate_ci_gates.sh --fix`.
3. Finalize auth feature docs.
