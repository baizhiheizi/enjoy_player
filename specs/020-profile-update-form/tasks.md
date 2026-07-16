# Tasks: Profile Update Form

**Input**: Design documents from `/specs/020-profile-update-form/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Backend status**: [baizhiheizi/enjoy_web#227](https://github.com/baizhiheizi/enjoy_web/issues/227) is **CLOSED**. Avatar = Active Storage `signed_id` from `POST /api/v1/direct_uploads`, then `PATCH /api/v1/profile` with `user.avatar`; profile JSON includes `mixinId`; max **2MB**; content types **JPEG/PNG/WebP**.

**Tests**: Required (constitution + plan QR-002). Write failing tests before or with implementation; keep green before merging.

**Organization**: Tasks grouped by user story for independent delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no incomplete dependencies)
- **[Story]**: US1–US4 map to spec user stories
- Exact file paths in every task

## Path Conventions

- Feature: `lib/features/auth/{application,data,domain,presentation}/`
- API: `lib/data/api/`
- Tests: `test/features/auth/`
- Docs: `docs/features/auth.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Align design artifacts with the resolved enjoy_web API and confirm touch points

- [x] T001 Update `specs/020-profile-update-form/contracts/profile-api.md` for resolved #227: `mixinId` on GET; avatar via `POST /api/v1/direct_uploads` → `PATCH` `user.avatar` (signed_id); 2MB; JPEG/PNG/WebP; blank clears
- [x] T002 [P] Update `specs/020-profile-update-form/research.md` Decision 4 and Assumptions to mark #227 resolved and lock the direct-upload + signed_id approach
- [x] T003 [P] Update `specs/020-profile-update-form/data-model.md` avatar max size default to **2 MiB** to match server `AVATAR_MAX_SIZE`
- [x] T004 [P] Confirm touch list: `lib/features/auth/presentation/widgets/profile_hero_card.dart`, `profile_content.dart`, `profile_preferences_screen.dart`, `lib/core/routing/app_router.dart`, `lib/data/api/services/auth_api.dart`, `docs/features/auth.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain + API plumbing every story needs. **No user-story UI until this phase completes.**

**⚠️ CRITICAL**: Blocks US1–US4

- [x] T005 Add optional `mixinId` to `UserProfile` (`fromJson` / `toJson` / `copyWith`) in `lib/features/auth/domain/user_profile.dart`
- [x] T006 [P] Create `lib/features/auth/domain/avatar_pick_constraints.dart` with max **2 MiB**, allowed extensions/MIME (`jpeg`/`png`/`webp`), and a pure validate helper returning a typed failure reason
- [x] T007 [P] Add unit tests for `mixinId` parsing and avatar constraints in `test/features/auth/domain/user_profile_test.dart` and `test/features/auth/domain/avatar_pick_constraints_test.dart`
- [x] T008 Implement Active Storage direct-upload client (checksum + create blob + PUT bytes) against `POST /api/v1/direct_uploads` in `lib/data/api/services/direct_uploads_api.dart` (use authenticated `ApiClient` / existing bearer flow)
- [x] T009 Wire `DirectUploadsApi` provider (or factory) next to other API services in `lib/data/api/` (follow existing `authApi` / repository injection patterns; add `@riverpod` only if required by local conventions)
- [x] T010 Extend `AuthApi` / `UpdateProfileRequest` (or dedicated method) so profile PATCH can send `avatar` signed_id in `lib/data/api/services/auth_api.dart` and `lib/features/auth/domain/update_profile_request.dart`
- [x] T011 Add `AuthRepository.updateAvatar` (direct upload → PATCH avatar → cache profile) and `AuthController.updateAvatar` in `lib/features/auth/data/auth_repository.dart` and `lib/features/auth/application/auth_controller.dart`
- [x] T012 [P] Add repository/API unit tests with fakes for direct-upload + avatar attach success/failure in `test/features/auth/data/auth_repository_avatar_test.dart` (or extend existing auth repository tests)
- [x] T013 [P] Add shared ARB keys for edit-profile / Enjoy ID / Mixin / avatar errors in `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`, `lib/l10n/app_zh_CN.arb` (run flutter gen-l10n as needed)

**Checkpoint**: Profile model understands `mixinId`; avatar upload path callable from controller; constraints + tests green

---

## Phase 3: User Story 1 - Profile card shows Enjoy ID (Priority: P1) 🎯 MVP

**Goal**: Hero secondary line shows Enjoy ID (`profile.id`), not email

**Independent Test**: Sign in → Profile tab → secondary line is Enjoy ID (e.g. `24000001`), not email

### Tests for User Story 1

- [x] T014 [P] [US1] Widget test: `ProfileHeroCard` shows Enjoy ID and not email when they differ in `test/features/auth/presentation/profile_hero_card_test.dart`

### Implementation for User Story 1

- [x] T015 [US1] Change secondary line in `lib/features/auth/presentation/widgets/profile_hero_card.dart` from `profile.email` to Enjoy ID (`profile.id`), with copy-friendly plain text styling
- [x] T016 [US1] Add/adjust localization if the ID needs a visible prefix/label (optional; prefer bare ID per spec) in `lib/l10n/app_*.arb` and hero widget

**Checkpoint**: US1 demoable without edit form

---

## Phase 4: User Story 2 - Dedicated profile update form (Priority: P1)

**Goal**: `/profile/edit` for username save + identity display; Preferences no longer edits username

**Independent Test**: Profile → Edit profile → change username → Save → hero shows new name; Preferences has no username field

### Tests for User Story 2

- [x] T017 [P] [US2] Widget test: edit form hydrates username and saves via mocked `authCtrl` in `test/features/auth/presentation/profile_edit_screen_test.dart`
- [x] T018 [P] [US2] Widget/smoke test: `ProfilePreferencesScreen` has no username field in `test/features/auth/presentation/profile_preferences_screen_test.dart`

### Implementation for User Story 2

- [x] T019 [US2] Register child route `edit` → `ProfileEditScreen` under `/profile` in `lib/core/routing/app_router.dart`
- [x] T020 [US2] Create `lib/features/auth/presentation/profile_edit_screen.dart` with username `TextFormField`, Save via `UpdateProfileRequest(name:)`, success/error `AppNotice`, loading state
- [x] T021 [US2] Add Profile entry to edit (hero tap and/or `SettingsRow`) in `lib/features/auth/presentation/widgets/profile_content.dart` and/or `profile_hero_card.dart` without breaking Upgrade CTA
- [x] T022 [US2] Remove username field and name from save payload in `lib/features/auth/presentation/profile_preferences_screen.dart` (keep goal/languages/locale)

**Checkpoint**: US1 + US2 work; username lives only on Edit profile

---

## Phase 5: User Story 3 - Upload and update avatar (Priority: P1)

**Goal**: Pick image → preview → direct upload → PATCH avatar → hero/sidebar show new avatar

**Independent Test**: Edit profile → pick JPEG/PNG/WebP ≤2MB → Save → hero + sidebar chip show new avatar after success

### Tests for User Story 3

- [x] T023 [P] [US3] Widget/unit test: oversize/unsupported file blocked before network in `test/features/auth/domain/avatar_pick_constraints_test.dart` / edit-screen tests
- [x] T024 [P] [US3] Repository test: mocked direct-upload + PATCH updates cached `avatarUrl` in `test/features/auth/data/auth_repository_avatar_test.dart`

### Implementation for User Story 3

- [x] T025 [US3] Add avatar tap/`file_picker` image pick + local preview + clear-pending on dismiss in `lib/features/auth/presentation/profile_edit_screen.dart`
- [x] T026 [US3] On Save with pending avatar: validate → `authCtrl.updateAvatar` with progress UI; on failure keep prior remote avatar and show localized error in `profile_edit_screen.dart`
- [x] T027 [US3] Ensure successful avatar update refreshes `authCtrlProvider` so `ProfileHeroCard` and `sidebar_account_chip.dart` pick up new `avatarUrl` without app restart
- [x] T028 [US3] Manual smoke note (document in PR): picker on one mobile + one desktop OS per `specs/020-profile-update-form/quickstart.md` Phase B

**Checkpoint**: Full identity edit path (name + avatar) works against live/staging API

---

## Phase 6: User Story 4 - Clear editable vs read-only identity (Priority: P2)

**Goal**: Enjoy ID, email, Mixin ID are display-only (copy optional); Mixin shows not-linked when absent

**Independent Test**: Open Edit profile → cannot edit Enjoy ID / email / Mixin; Mixin not-linked when `mixinId` null

### Tests for User Story 4

- [x] T029 [P] [US4] Widget test: read-only identity rows (no enabled editors) and Mixin not-linked state in `test/features/auth/presentation/profile_edit_screen_test.dart`

### Implementation for User Story 4

- [x] T030 [P] [US4] Add read-only identity row widget (label + value + optional copy) in `lib/features/auth/presentation/widgets/profile_identity_row.dart`
- [x] T031 [US4] Render Enjoy ID, email, Mixin ID (or not-linked) via identity rows on `lib/features/auth/presentation/profile_edit_screen.dart`
- [x] T032 [US4] Optional copy-to-clipboard + notice for Enjoy ID / Mixin ID using existing clipboard/notice patterns

**Checkpoint**: All four stories independently verifiable

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Docs, contracts sync, CI gates

- [x] T033 [P] Update Profile / Preferences / Edit profile / avatar+Mixin API behavior in `docs/features/auth.md`
- [x] T034 [P] Refresh `specs/020-profile-update-form/quickstart.md` to remove “API unavailable” gating and point at direct-upload flow
- [x] T035 Run `flutter analyze` and fix issues from this feature
- [x] T036 Run `flutter test test/features/auth/` (and any new API tests) until green
- [x] T037 Run `bash .github/scripts/validate_ci_gates.sh --fix` before push
- [x] T038 [P] If any `@riverpod` / codegen annotations were added, run `dart run build_runner build` and commit generated `*.g.dart`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Immediate
- **Phase 2 (Foundational)**: After Setup — **blocks all stories**
- **Phase 3 (US1)**: After Foundational — MVP
- **Phase 4 (US2)**: After Foundational; integrates with US1 hero but testable alone via route
- **Phase 5 (US3)**: After Foundational (+ practical after US2 screen exists for UI); API ready (no backend wait)
- **Phase 6 (US4)**: After US2 screen shell exists (rows live on edit form)
- **Phase 7 (Polish)**: After desired stories complete

### User Story Dependencies

| Story | Depends on | Notes |
|-------|------------|--------|
| US1 Enjoy ID on hero | Phase 2 (light) | Can start right after T005 if needed; no avatar API |
| US2 Edit form + move username | Phase 2 + ideally US1 | Route + screen |
| US3 Avatar upload | Phase 2 (T008–T011) + US2 screen | **#227 resolved — implement fully** |
| US4 Read-only identity | US2 screen | Uses `mixinId` from T005 |

### Parallel Opportunities

- T002/T003/T004 after T001 starts
- T006/T007 parallel with T005
- T008–T009 then T010–T011 (API before repository)
- T014 with T015 after foundation
- T017/T018 parallel
- T023/T024 parallel with T025 once repository exists
- T030 parallel with early US4 tests
- T033/T034 parallel in polish

---

## Parallel Example: Foundational + US1

```bash
# After T005:
Task: "T006 avatar_pick_constraints.dart"
Task: "T007 domain unit tests"
Task: "T008 direct_uploads_api.dart"

# US1 MVP slice:
Task: "T014 profile_hero_card_test.dart"
Task: "T015 hero Enjoy ID secondary line"
```

## Parallel Example: User Story 3 (avatar)

```bash
Task: "T023 constraint/widget failure tests"
Task: "T024 auth_repository_avatar_test.dart"
# then
Task: "T025–T027 edit screen pick/upload/refresh"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 + Phase 2 (at least T005)
2. Phase 3 US1 — ship Enjoy ID on hero
3. **STOP and VALIDATE** per quickstart Phase A step 2

### Incremental Delivery (recommended)

1. Setup + Foundational (include full avatar API client — backend ready)
2. US1 → demo Enjoy ID
3. US2 → demo Edit profile + username move
4. US3 → demo avatar upload end-to-end
5. US4 → polish read-only/copy
6. Polish + CI gates

### Parallel Team Strategy

- Dev A: Foundational API (T008–T012) + US3
- Dev B: US1 + US2 UI/routing + US4 rows
- Sync on ARB keys (T013) early to avoid merge pain

---

## Notes

- Do **not** gate avatar on “API unavailable” UI — #227 is closed; implement the real flow
- Client max size **2 MiB** must match server
- Never invent `mixinId` from `hasMixin` alone
- Do not edit `enjoy_web` from this repo
- Commit after each logical group; keep `flutter analyze` / targeted tests green
- Suggested MVP: **US1 only**; full product value = US1–US3
