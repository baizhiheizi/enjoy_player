---
description: "Task list for Pro upgrade and subscription management"
---

# Tasks: Pro Upgrade & Subscription Management

**Input**: Design documents from `/specs/002-pro-upgrade/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Required per plan Constitution Check — unit tests for domain/repository/platform helper; widget tests for subscription screen (loading/error/desktop/mobile guardrails); extend auth redirect tests for `/subscription`.

**Organization**: Tasks grouped by user story (US1–US5) plus setup, foundation, and polish.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Maps to user stories in spec.md (US1–US5)

## Path Conventions

- **Feature code**: `lib/features/subscription/{application,data,domain,presentation}/`
- **API**: `lib/data/api/services/subscription_api.dart`
- **Platform helper**: `lib/core/platform/subscription_purchase_capability.dart`
- **Routing**: `lib/core/routing/app_router.dart`, `lib/core/routing/auth_redirect.dart`
- **Tests**: `test/features/subscription/`, `test/core/platform/`, `test/core/routing/`
- **Docs**: `docs/features/subscription.md`, `docs/decisions/0032-platform-scoped-subscription-purchase.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm design artifacts and scaffold feature module before coding.

- [x] T001 Review spec, plan, contracts, and quickstart in `specs/002-pro-upgrade/`
- [x] T002 Create feature directory scaffold `lib/features/subscription/{domain,data,application,presentation/widgets}/`
- [x] T003 [P] Confirm `url_launcher` dependency in `pubspec.yaml` (already present — no change expected)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain models, API layer, repository, platform capability, and shared localization — MUST complete before user story phases.

**⚠️ CRITICAL**: No user story work until this phase is complete.

### Tests for Foundation

- [x] T004 [P] Create JSON parsing unit tests in `test/features/subscription/domain/subscription_status_test.dart`
- [x] T005 [P] Create platform capability unit tests in `test/core/platform/subscription_purchase_capability_test.dart`
- [x] T006 [P] Create repository unit test scaffold in `test/features/subscription/data/subscription_repository_test.dart`

### Implementation for Foundation

- [x] T007 [P] Add `PaymentProcessor` enum in `lib/features/subscription/domain/payment_processor.dart`
- [x] T008 [P] Add `SubscriptionStatus` model with `fromJson` in `lib/features/subscription/domain/subscription_status.dart` per `specs/002-pro-upgrade/contracts/subscription-api.md`
- [x] T009 [P] Add `PurchaseRequest` model in `lib/features/subscription/domain/purchase_request.dart`
- [x] T010 [P] Add `PaymentSession` model with `fromJson` in `lib/features/subscription/domain/payment_session.dart`
- [x] T011 [P] Implement `SubscriptionApi` (GET/POST `/api/v1/subscriptions`, POST balance) in `lib/data/api/services/subscription_api.dart`
- [x] T012 [P] Add `@Riverpod` `subscriptionApiProvider` in `lib/data/api/services/subscription_api_provider.dart`
- [x] T013 Implement `SubscriptionRepository` (getStatus, purchase, purchaseWithBalance, error mapping) in `lib/features/subscription/data/subscription_repository.dart` (depends on T011)
- [x] T014 [P] Implement `supportsExternalSubscriptionPurchase` and `showsMobilePurchaseUnavailable` in `lib/core/platform/subscription_purchase_capability.dart` per `specs/002-pro-upgrade/contracts/platform-purchase-capability.md`
- [x] T015 [P] Add core subscription ARB keys (title, tier labels, error/retry) in `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`
- [x] T016 Run `dart run build_runner build` after adding `@Riverpod` providers

**Checkpoint**: Domain parses web API JSON; repository mocks pass; platform helper returns correct values for Windows/macOS vs iOS/Android.

---

## Phase 3: User Story 1 — View subscription status and compare plans (Priority: P1) 🎯 MVP

**Goal**: Signed-in users on all platforms see tier, status, expiration, daily credits limit, and Free vs Pro comparison on `/subscription`.

**Independent Test**: Sign in as Free user, open `/subscription`, verify status card + tier comparison with Free marked as current (QS-1 in `specs/002-pro-upgrade/quickstart.md`).

### Tests for User Story 1

- [x] T017 [P] [US1] Add widget test for loading skeleton state in `test/features/subscription/presentation/subscription_screen_test.dart`
- [x] T018 [P] [US1] Add widget test for error + retry state in `test/features/subscription/presentation/subscription_screen_test.dart`
- [x] T019 [P] [US1] Add widget test for Free user status + comparison content in `test/features/subscription/presentation/subscription_screen_test.dart`

### Implementation for User Story 1

- [x] T020 [P] [US1] Add `@Riverpod` `subscriptionStatusProvider` in `lib/features/subscription/application/subscription_status_provider.dart`
- [x] T021 [P] [US1] Build `SubscriptionStatusCard` widget in `lib/features/subscription/presentation/widgets/subscription_status_card.dart`
- [x] T022 [P] [US1] Build `TierComparison` widget in `lib/features/subscription/presentation/widgets/tier_comparison.dart`
- [x] T023 [US1] Implement `SubscriptionScreen` (loading/error/refresh/content) in `lib/features/subscription/presentation/subscription_screen.dart` (depends on T020–T022)
- [x] T024 [US1] Register `/subscription` route in `lib/core/routing/app_router.dart` inside `ShellRoute`
- [x] T025 [US1] Add `subscription` from-shorthand in `lib/core/routing/auth_redirect.dart` per `specs/002-pro-upgrade/contracts/subscription-routing.md`
- [x] T026 [P] [US1] Extend auth redirect unit tests for `/subscription` gate in `test/core/routing/auth_redirect_test.dart`
- [x] T027 [P] [US1] Add tier comparison and status ARB strings in `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`
- [x] T028 [US1] Run `flutter gen-l10n` after US1 ARB updates

**Checkpoint**: `/subscription` renders on all platforms; signed-out users redirect to sign-in with `from=subscription`.

---

## Phase 4: User Story 2 — Upgrade or extend Pro via external checkout (Priority: P1)

**Goal**: Desktop users (Windows + macOS) purchase or extend Pro via Stripe/Mixin external checkout.

**Independent Test**: On Windows or macOS, tap Upgrade → select duration/processor → external browser opens with checkout URL (QS-3).

### Tests for User Story 2

- [x] T029 [P] [US2] Add repository test for successful purchase with `payUrl` in `test/features/subscription/data/subscription_repository_test.dart`
- [x] T030 [P] [US2] Add widget test for desktop Upgrade opening purchase sheet in `test/features/subscription/presentation/subscription_screen_test.dart` (platform override: Windows)

### Implementation for User Story 2

- [x] T031 [P] [US2] Add `@Riverpod` `subscriptionPurchaseProvider` mutation in `lib/features/subscription/application/subscription_purchase_provider.dart`
- [x] T032 [US2] Build `PurchaseSheet` (duration 1–12, Stripe/Mixin, total price, continue) in `lib/features/subscription/presentation/widgets/purchase_sheet.dart`
- [x] T033 [US2] Wire Upgrade/Extend buttons on desktop to open `PurchaseSheet` from `lib/features/subscription/presentation/widgets/tier_comparison.dart`
- [x] T034 [US2] Launch checkout via `url_launcher` `LaunchMode.externalApplication` in `lib/features/subscription/application/subscription_purchase_provider.dart`
- [x] T035 [US2] Add purchase-flow ARB strings in `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`
- [x] T036 [US2] Refresh `subscriptionStatusProvider` after purchase initiation in `lib/features/subscription/application/subscription_purchase_provider.dart`
- [x] T037 [US2] Add `WidgetsBindingObserver` or lifecycle listener on `SubscriptionScreen` to refresh status on app resume in `lib/features/subscription/presentation/subscription_screen.dart`
- [x] T038 [US2] Run `dart run build_runner build` if purchase provider added

**Checkpoint**: Desktop checkout opens browser; returning to app allows refresh to pick up Pro status.

---

## Phase 5: User Story 3 — Upgrade using account balance (Priority: P2)

**Goal**: Desktop users convert positive account balance to Pro subscription time with confirmation.

**Independent Test**: Desktop user with balance > 0 → Use Balance tab → confirm → status updates (QS-4).

### Tests for User Story 3

- [x] T039 [P] [US3] Add repository test for balance purchase success in `test/features/subscription/data/subscription_repository_test.dart`

### Implementation for User Story 3

- [x] T040 [US3] Add balance tab to `PurchaseSheet` in `lib/features/subscription/presentation/widgets/purchase_sheet.dart` (desktop only; hidden when `!supportsExternalSubscriptionPurchase`)
- [x] T041 [US3] Add balance confirmation dialog using `EnjoyModal` in `lib/features/subscription/presentation/widgets/purchase_sheet.dart`
- [x] T042 [US3] Implement balance purchase mutation path in `lib/features/subscription/application/subscription_purchase_provider.dart`
- [x] T043 [US3] Invalidate `subscriptionStatusProvider` and refresh profile via `AuthRepository.fetchProfile()` after balance success in `lib/features/subscription/application/subscription_purchase_provider.dart`
- [x] T044 [P] [US3] Add balance purchase ARB strings in `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`

**Checkpoint**: Balance purchase works on desktop; zero balance shows disabled state with explanation.

---

## Phase 6: User Story 4 — Discover upgrade when Pro is needed (Priority: P2)

**Goal**: AI credits/billing failures (HTTP 402) surface an action to open subscription management on all platforms.

**Independent Test**: Trigger 402 error → tap upgrade action → lands on `/subscription` (QS-6).

### Tests for User Story 4

- [x] T045 [P] [US4] Add unit/widget test for credits failure helper navigation in `test/features/subscription/presentation/credits_failure_actions_test.dart`

### Implementation for User Story 4

- [x] T046 [US4] Create `showCreditsFailureWithUpgradeAction` helper in `lib/features/subscription/presentation/credits_failure_actions.dart` per `specs/002-pro-upgrade/contracts/credits-upgrade-cta.md`
- [x] T047 [US4] Wire helper into at least one high-traffic AI error surface (e.g. `lib/features/lookup/presentation/widgets/lookup_error_row.dart` or transcript AI error path)
- [x] T048 [P] [US4] Add credits-limit CTA ARB strings in `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`

**Checkpoint**: 402 errors include visible path to `/subscription` on desktop and mobile.

---

## Phase 7: User Story 5 — Access subscription from account navigation (Priority: P3)

**Goal**: Users reach subscription from profile/account; Pro tier visible in account chrome.

**Independent Test**: Profile → Subscription tile → `/subscription`; Pro user sees tier badge (QS-1 via profile entry).

### Implementation for User Story 5

- [x] T049 [US5] Add subscription nav tile to `_ProfileAccountCard` in `lib/features/auth/presentation/profile_screen.dart`
- [x] T050 [P] [US5] Add profile subscription tile ARB strings in `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`
- [x] T051 [P] [US5] Optional: add subscription link or Pro indicator in `lib/features/auth/presentation/widgets/sidebar_account_chip.dart`

**Checkpoint**: Subscription discoverable from profile without typing URL.

---

## Phase 8: Mobile guardrails (cross-cutting — FR-016/FR-017, SC-006)

**Purpose**: Ensure iOS/Android never launch external checkout; show coming-soon dialog instead.

**Note**: Can start after US2 tier comparison buttons exist; blocks release if skipped.

### Tests

- [x] T052 [P] Add widget test: iOS platform override → Upgrade shows coming-soon, no purchase sheet in `test/features/subscription/presentation/subscription_screen_test.dart`

### Implementation

- [x] T053 Build `MobilePurchaseUnavailable` dialog in `lib/features/subscription/presentation/widgets/mobile_purchase_unavailable.dart`
- [x] T054 Wire mobile Upgrade/Extend taps to dialog (not `PurchaseSheet`) in `lib/features/subscription/presentation/widgets/tier_comparison.dart`
- [x] T055 [P] Add mobile coming-soon ARB strings in `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`

**Checkpoint**: iOS Simulator QS-5 passes — no external browser on upgrade tap.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, verification, and final quality gates.

- [x] T056 [P] Write `docs/features/subscription.md` covering status, desktop purchase, mobile deferral, and entry points
- [x] T057 [P] Write ADR `docs/decisions/0032-platform-scoped-subscription-purchase.md` and link in `docs/decisions/README.md`
- [x] T058 [P] Add subscription link to `docs/README.md` feature index
- [x] T059 Run `flutter gen-l10n` for any remaining ARB changes
- [x] T060 Run `dart run build_runner build`
- [x] T061 Run `flutter analyze`
- [x] T062 Run `flutter test`
- [ ] T063 Execute manual quickstart scenarios QS-1, QS-5, QS-7 in `specs/002-pro-upgrade/quickstart.md`
- [ ] T064 [P] Optional: manual QS-3 desktop Stripe checkout on Windows or macOS with test account

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**
- **US1 (Phase 3)**: Depends on Foundational — **MVP**
- **US2 (Phase 4)**: Depends on US1 (tier comparison buttons + screen)
- **US3 (Phase 5)**: Depends on US2 (`PurchaseSheet` shell)
- **US4 (Phase 6)**: Depends on US1 (`/subscription` route exists)
- **US5 (Phase 7)**: Depends on US1 — can parallel with US2–US4 after US1
- **Mobile guardrails (Phase 8)**: Depends on US2 tier button wiring
- **Polish (Phase 9)**: Depends on all desired story phases

### User Story Dependencies

| Story | Depends on | Independent test |
|-------|------------|------------------|
| US1 | Foundational | `/subscription` status + comparison |
| US2 | US1 | Desktop checkout opens browser |
| US3 | US2 | Desktop balance purchase |
| US4 | US1 | 402 → `/subscription` navigation |
| US5 | US1 | Profile tile → subscription screen |

### Parallel Opportunities

- **Phase 2**: T004–T012, T014–T015 can run in parallel after T001–T003
- **Phase 3**: T017–T019, T021–T022, T026–T027 parallel; T023 waits on providers + widgets
- **Phase 4–5**: T029–T030 parallel; T044 parallel with T041–T043
- **After US1 ships**: US4 and US5 can proceed in parallel with US2

### Parallel Example: User Story 1

```bash
# Widget tests in parallel:
T017 loading skeleton test
T018 error/retry test
T019 Free user content test

# Widgets in parallel:
T021 SubscriptionStatusCard
T022 TierComparison
```

### Parallel Example: Foundation

```bash
# Domain models in parallel:
T007 PaymentProcessor
T008 SubscriptionStatus
T009 PurchaseRequest
T010 PaymentSession

# Tests in parallel:
T004 domain parsing tests
T005 platform capability tests
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: QS-1 on iOS + desktop via `/subscription`
5. Demo status/comparison without purchase

### Incremental Delivery

1. Setup + Foundational → API layer ready
2. US1 → status screen on all platforms (**MVP**)
3. US5 → profile navigation (quick win)
4. US2 + US3 → desktop revenue path
5. Phase 8 → mobile guardrails before mobile release
6. US4 → credits discovery
7. Polish → docs + CI green

### Suggested MVP Scope

**User Story 1 only** (Phases 1–3): subscription status and plan comparison on all platforms, reachable via `/subscription` and auth gate. No purchase yet — sufficient for internal preview and Pro status verification for cross-device users.

---

## Notes

- Purchase is **Windows + macOS only**; use `subscription_purchase_capability.dart`, not `isDesktop` alone
- iOS/Android: Phase 8 is **required before App Store / Play release**
- StoreKit / Play Billing deferred to follow-up spec `003-*`
- Total tasks: **64** (T001–T064)
- Task count by story: Setup 3, Foundation 13, US1 12, US2 10, US3 6, US4 4, US5 3, Mobile guardrails 4, Polish 9
