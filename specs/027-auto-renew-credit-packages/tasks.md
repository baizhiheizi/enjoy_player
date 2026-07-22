# Tasks: App Auto-Renew Subscription & Credits Packages

**Input**: Design documents from `/specs/027-auto-renew-credit-packages/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included — constitution II / plan QR-002 require automated coverage for changed billing contracts.

**Organization**: Phases by user story so each increment is independently testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (`[US1]`…`[US6]`)
- Paths are repo-relative from Enjoy Player root

## Path Conventions

- App code: `lib/features/subscription/`, `lib/features/credits/`, `lib/data/api/services/`
- Tests: `test/features/subscription/`, `test/features/credits/`, `test/core/platform/`
- L10n: `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`, `lib/l10n/app_zh_CN.arb`
- Docs: `docs/features/`, `docs/decisions/`

---

## Phase 1: Setup

**Purpose**: Align platform policy and shared scaffolding before story work

- [x] T001 Amend ADR-0032 in `docs/decisions/0032-platform-scoped-subscription-purchase.md` to allow external checkout on Linux (Win/macOS/Linux; iOS/Android still deferred)
- [x] T002 [P] Extend `supportsExternalSubscriptionPurchase` to include `TargetPlatform.linux` in `lib/core/platform/subscription_purchase_capability.dart`
- [x] T003 [P] Update Linux cases in `test/core/platform/subscription_purchase_capability_test.dart` (Linux true; iOS/Android still coming-soon)
- [x] T004 [P] Add shared ARB keys for auto-renew plans, cancel, packages, 409 conflict, and verifying notices in `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`, and `lib/l10n/app_zh_CN.arb` (run `flutter gen-l10n` as needed)

---

## Phase 2: Foundational (Blocking)

**Purpose**: Domain + Rails/Worker API surface all stories share — **no story UI until this phase completes**

**⚠️ CRITICAL**: Blocks US1–US6

- [x] T005 [P] Add `AutoRenewBilling` domain model (+ JSON) in `lib/features/subscription/domain/auto_renew_billing.dart`
- [x] T006 [P] Add `SubscriptionPlan` domain model (+ JSON) in `lib/features/subscription/domain/subscription_plan.dart`
- [x] T007 [P] Add `AutoRenewStartResult` domain model (+ JSON) in `lib/features/subscription/domain/auto_renew_start_result.dart`
- [x] T008 Extend `SubscriptionStatus` with optional `autoRenew` in `lib/features/subscription/domain/subscription_status.dart`
- [x] T009 Extend `SubscriptionApi` with `listPlans()`, `startAutoRenew({planId})`, and `cancelAutoRenew()` in `lib/data/api/services/subscription_api.dart` per `specs/027-auto-renew-credit-packages/contracts/api-v1-subscriptions-auto-renew.md`
- [x] T010 Extend `SubscriptionRepository` for plans / start auto-renew / cancel (+ map `409`/`404`/`400`) in `lib/features/subscription/data/subscription_repository.dart`
- [x] T011 [P] Add `CreditsPackage` and purchase-session domain models in `lib/features/credits/domain/credits_package.dart` (and purchase result type in same file or sibling)
- [x] T012 [P] Add `CreditsSummary` domain model (+ JSON) in `lib/features/credits/domain/credits_summary.dart`
- [x] T013 Add Rails `CreditsPackagesApi` (`listPackages`, `startPackagePurchase`) in `lib/data/api/services/credits_packages_api.dart` and wire provider in `lib/data/api/services/api_providers.dart`
- [x] T014 Extend Worker `CreditsApi` with `getSummary()` in `lib/data/api/services/ai/credits_api.dart` per `specs/027-auto-renew-credit-packages/contracts/worker-credits-summary.md`
- [x] T015 [P] Unit tests for auto-renew/status/plan JSON in `test/features/subscription/domain/subscription_status_test.dart` (extend) and/or new `test/features/subscription/domain/auto_renew_billing_test.dart`
- [x] T016 [P] Unit tests for packages + summary JSON in `test/features/credits/domain/credits_package_test.dart` and `test/features/credits/domain/credits_summary_test.dart`
- [x] T017 Repository tests for new subscription methods (incl. 409) in `test/features/subscription/data/subscription_repository_test.dart`
- [x] T018 Run `dart run build_runner build` and commit generated `*.g.dart` for any new `@Riverpod` providers introduced in this phase

**Checkpoint**: Domain + API clients ready; stories can proceed

---

## Phase 3: User Story 1 — Choose monthly or yearly auto-renew Pro (P1) 🎯 MVP

**Goal**: Catalog plans on all platforms; start external auto-renew checkout on Win/macOS/Linux; mobile coming soon; reuse Pro reconcile after checkout

**Independent Test**: Desktop free user opens `/subscription`, picks monthly (then yearly on another account), confirms price/interval, external checkout opens; after success/resume status shows Pro + interval + auto-renew on. Mobile tap → coming soon, no `payUrl`.

### Tests for User Story 1

- [x] T019 [P] [US1] Provider/widget tests for plans load + mobile block in `test/features/subscription/application/` and/or `test/features/subscription/presentation/subscription_screen_test.dart`

### Implementation for User Story 1

- [x] T020 [US1] Add `subscriptionPlansProvider` (and purchase notifier method for auto-renew) in `lib/features/subscription/application/` (e.g. extend `subscription_purchase_provider.dart` or add `auto_renew_purchase_provider.dart`)
- [x] T021 [US1] Build auto-renew plan picker UI (month/year, amount, confirm) in `lib/features/subscription/presentation/widgets/` (new widget, e.g. `auto_renew_plan_picker.dart` or sheet)
- [x] T022 [US1] Wire primary Upgrade CTA on `lib/features/subscription/presentation/widgets/tier_comparison.dart` / `subscription_screen.dart` to plan picker; gate with `supportsExternalSubscriptionPurchase` / `showMobilePurchaseUnavailableDialog`
- [x] T023 [US1] On start success: launch `payUrl` via `url_launcher`, call `TierReconcileCtrl.markPurchasePending()`, handle empty `payUrl` and `409` with ARB copy
- [x] T024 [US1] Show basic auto-renew interval / on-off on `lib/features/subscription/presentation/widgets/subscription_status_card.dart` when `autoRenew != null`
- [x] T025 [US1] Regenerate Riverpod code (`dart run build_runner build`) for US1 providers

**Checkpoint**: MVP — auto-renew subscribe path works on desktop/Linux; mobile blocked

---

## Phase 4: User Story 2 — Cancel auto-renew without losing paid time (P1)

**Goal**: Cancel-at-period-end from any platform with confirm + access-through messaging

**Independent Test**: Active auto-renew user cancels → auto-renew off, access-through date shown, Pro retained until that date; failure leaves prior state.

### Tests for User Story 2

- [x] T026 [P] [US2] Widget/provider tests for cancel confirm success and failure in `test/features/subscription/presentation/` (new or extend screen tests)

### Implementation for User Story 2

- [x] T027 [US2] Add cancel action + confirm dialog (access-through copy) on subscription UI in `lib/features/subscription/presentation/widgets/subscription_status_card.dart` and/or `subscription_screen.dart`
- [x] T028 [US2] Call `SubscriptionRepository.cancelAutoRenew()`, invalidate `subscriptionStatusProvider`, show success/error notices; only show CTA when cancelable per `data-model.md`
- [x] T029 [US2] Ensure canceled-but-paid status displays auto-renew off + access end (status card fields)

**Checkpoint**: Cancel works on desktop and mobile without opening checkout

---

## Phase 5: User Story 3 — Buy a credits package (P1)

**Goal**: List $2/$5/$50 packages; desktop/Linux external checkout; refresh Worker permanent credits; no tier change; mobile coming soon

**Independent Test**: Free desktop user buys each package size (or one in CI-mocked flow); `permanentAvailable` rises; subscription unchanged. Mobile buy → coming soon.

### Tests for User Story 3

- [x] T030 [P] [US3] Unit/repo tests for packages API mapping in `test/features/credits/` (new repository test file)
- [x] T031 [P] [US3] Provider tests for package-pending reconcile / summary poll in `test/features/credits/application/` or extend `test/features/subscription/application/tier_reconcile_provider_test.dart` if shared

### Implementation for User Story 3

- [x] T032 [US3] Add credits packages repository + `creditsPackagesProvider` / purchase notifier under `lib/features/credits/data/` and `lib/features/credits/application/`
- [x] T033 [US3] Add `creditsSummaryProvider` using Worker `CreditsApi.getSummary()` in `lib/features/credits/application/`
- [x] T034 [US3] Package offer UI (price + permanent credits, distinct from subscription) in `lib/features/credits/presentation/` and/or section on `lib/features/subscription/presentation/subscription_screen.dart`
- [x] T035 [US3] Desktop/Linux: confirm → `startPackagePurchase` → launch `payUrl`; mobile: coming soon (reuse capability helpers)
- [x] T036 [US3] Package-purchase pending reconcile: snapshot/poll `permanentAvailable` on resume with verifying/timeout notices (extend `lib/features/subscription/application/tier_reconcile_provider.dart` or add credits reconcile helper + host wiring in `tier_reconcile_host.dart`)
- [x] T037 [US3] Surface permanent credits standing (summary) enough to prove grant on subscription and/or credits screen
- [x] T038 [US3] Run `dart run build_runner build` for new credits providers

**Checkpoint**: Packages purchasable on desktop/Linux; permanent credits refresh

---

## Phase 6: User Story 4 — Rich subscription status after web/app changes (P2)

**Goal**: Full status fidelity (interval, price, provider, prepaid-only clarity) + resume reconcile without re-sign-in

**Independent Test**: Change billing on web → resume app → status matches; prepaid-only Pro shows no false auto-renew-on; error/retry without stale auto-renew data.

### Tests for User Story 4

- [x] T039 [P] [US4] Widget tests for prepaid-only vs auto-renew status presentation in `test/features/subscription/presentation/subscription_screen_test.dart` or status card test file

### Implementation for User Story 4

- [x] T040 [US4] Complete status card fields (provider/channel when present, catalog amount, prepaid-only copy) in `lib/features/subscription/presentation/widgets/subscription_status_card.dart`
- [x] T041 [US4] Verify pull-to-refresh / resume path on `subscription_screen.dart` + existing `TierReconcileHost` covers web-originated changes; fix gaps only if needed
- [x] T042 [US4] Harden loading/error/retry so failed fetches do not show stale misleading auto-renew/package blocks

**Checkpoint**: Status trustworthy across web↔app

---

## Phase 7: User Story 5 — Keep prepaid one-time Pro as alternative (P2)

**Goal**: Prepaid months remain secondary but clear; 409 conflict when second auto-renew attempted; prices aligned at $9.99/month

**Independent Test**: Prepaid N-month purchase still works; auto-renew and prepaid both discoverable; active auto-renew + second start → conflict message, no silent second checkout.

### Tests for User Story 5

- [x] T043 [P] [US5] Regression/widget test that prepaid sheet still opens on purchase-capable platforms in `test/features/subscription/presentation/` (extend existing screen/sheet coverage)

### Implementation for User Story 5

- [x] T044 [US5] Relabel/restructure upgrade entry points so auto-renew is primary and prepaid sheet (`lib/features/subscription/presentation/widgets/purchase_sheet.dart`) is secondary (“Pay for months once” or equivalent ARB)
- [x] T045 [US5] Ensure 409 from `startAutoRenew` surfaces dedicated conflict copy (no launch) in purchase notifier + UI
- [x] T046 [US5] Confirm prepaid monthly unit display stays $9.99-aligned with monthly auto-renew catalog in UI copy

**Checkpoint**: No prepaid regression; dual paths clear

---

## Phase 8: User Story 6 — Discover packages when credits exhausted (P3)

**Goal**: Credits/billing failure surfaces reach offers that include packages, not only Pro upgrade

**Independent Test**: Trigger credits-limit (402) surface → path to subscription/credits offers where packages and auto-renew are both visible and distinctly labeled on desktop.

### Tests for User Story 6

- [x] T047 [P] [US6] Update/extend `test/features/subscription/presentation/credits_failure_actions_test.dart` for package-aware CTA copy/navigation if behavior changes

### Implementation for User Story 6

- [x] T048 [US6] Update `lib/features/subscription/presentation/credits_failure_actions.dart` (and ARB) so credits-limit UX links to offers that include packages discovery
- [x] T049 [US6] Ensure landing `/subscription` (or `/credits`) shows package section without conflating with auto-renew plans

**Checkpoint**: Daily-limit “stuck” journey unblocked

---

## Phase 9: Polish & Cross-Cutting

**Purpose**: Docs, quality gates, quickstart validation

- [x] T050 [P] Update `docs/features/subscription.md` for auto-renew plans, cancel, Linux purchase, packages entry points
- [x] T051 [P] Update `docs/features/credits-usage.md` (or expand credits feature doc) for packages + Worker summary standing
- [x] T052 Run `flutter analyze` and `flutter test` for subscription/credits/platform suites; fix until green
- [x] T053 Run `bash .github/scripts/validate_ci_gates.sh` (or `--fix`) and resolve format/codegen drift
- [x] T054 Walk manual smoke rows in `specs/027-auto-renew-credit-packages/quickstart.md` on at least one desktop/Linux build and note any gaps

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Start immediately
- **Phase 2 (Foundational)**: After Setup — **blocks all stories**
- **Phase 3 (US1)**: After Foundational — **MVP**
- **Phase 4 (US2)**: After Foundational; ideally after US1 status card basics (T024) for cancelable UI
- **Phase 5 (US3)**: After Foundational; can parallel US1/US2 if staffed (different files under `credits/`)
- **Phase 6 (US4)**: After US1 status basics; refines US1/US2 display
- **Phase 7 (US5)**: After US1 purchase path (needs primary CTA + 409)
- **Phase 8 (US6)**: After US3 package UI exists on subscription/credits
- **Phase 9 (Polish)**: After desired stories complete

### User Story Dependencies

| Story | Depends on | Independently testable? |
|-------|------------|-------------------------|
| US1 Auto-renew subscribe | Phase 2 | Yes (MVP) |
| US2 Cancel | Phase 2 (+ status with `autoRenew`) | Yes with seeded auto-renew user |
| US3 Packages | Phase 2 | Yes (can ship without cancel) |
| US4 Rich status | US1 display foundation | Yes via web-originated status |
| US5 Prepaid keep | US1 primary CTA | Yes prepaid regression |
| US6 Discovery | US3 package section | Yes via 402 CTA |

### Parallel Opportunities

- T002–T004; T005–T007; T011–T012; T015–T017 in parallel within their phases
- After Phase 2: US1 and US3 can proceed in parallel (subscription vs credits trees)
- US2 can start once status parsing lands (T008–T010)
- Polish doc tasks T050–T051 in parallel

---

## Parallel Example: User Story 1

```bash
# After Phase 2:
# Parallelizable tests/models already done in foundation.

# Sequential US1 implementation:
Task: T020 plans provider + purchase method
Task: T021 plan picker widget
Task: T022 wire tier_comparison / subscription_screen
Task: T023 launch payUrl + markPurchasePending
Task: T024 status card auto-renew basics
Task: T025 build_runner
```

## Parallel Example: User Story 3

```bash
Task: T032 packages repository/providers
Task: T033 creditsSummaryProvider
# then UI + checkout + reconcile:
Task: T034–T037
Task: T038 build_runner
```

---

## Implementation Strategy

### MVP First (US1 only)

1. Phase 1 Setup  
2. Phase 2 Foundational  
3. Phase 3 US1  
4. **STOP** — validate quickstart scenarios A + D (auto-renew + mobile gate)  
5. Then US2 (cancel) and US3 (packages) as next revenue/trust increments

### Incremental Delivery

1. Setup + Foundational  
2. US1 → demo auto-renew  
3. US2 → cancel trust  
4. US3 → packages  
5. US4 → status polish  
6. US5 → prepaid coexistence  
7. US6 → 402 discovery  
8. Polish → docs + CI gates  

### Suggested MVP scope

**US1 only** (monthly/yearly auto-renew catalog + desktop/Linux checkout + mobile block + basic status). Cancel (US2) and packages (US3) are the next P1 increments.

---

## Notes

- Do not implement StoreKit/Play/RevenueCat  
- Checkout URL field is always `payUrl` (from `pay_url`)  
- Never open external digital-unlock checkout on iOS/Android  
- Commit generated `*.g.dart` after `build_runner`  
- Prefer ARB keys over hardcoded user-visible strings  
