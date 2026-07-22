# Implementation Plan: App Auto-Renew Subscription & Credits Packages

**Branch**: `027-auto-renew-credit-packages` | **Date**: 2026-07-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/027-auto-renew-credit-packages/spec.md`

## Summary

Bring Enjoy Web billing parity into Enjoy Player: **monthly/yearly Stripe auto-renew** (catalog, start checkout, cancel-at-period-end, rich status) and **one-time credits packages** ($2 / $5 / $50 → permanent credits), while keeping existing prepaid Pro months. Purchase initiation stays **external checkout** on Windows, macOS, and **Linux** (see research); iOS/Android keep status + cancel + “coming soon” for purchase. Client calls existing Rails `/api/v1/subscriptions*` and `/api/v1/credits/packages*` plus Worker `GET /credits/summary` for permanent-balance refresh after package purchase. Extend `lib/features/subscription` and `lib/features/credits` (no new top-level feature module).

## Technical Context

**Language/Version**: Dart 3.x / Flutter (stable channel used by the repo)

**Primary Dependencies**: Flutter, Riverpod (`riverpod_annotation` + codegen), `url_launcher`, existing `ApiClient` (Rails snake↔camel), Worker AI client (`aiApiClientProvider`), go_router, ARB l10n

**Storage**: N/A for billing catalogs (server-sourced). Reuse existing profile/status cache + `TierReconcileCtrl`; add in-memory providers for plans, packages, and Worker credits summary. No Drift schema change.

**Testing**: `flutter test` (domain JSON, repository/API mocks, providers, widget tests for subscription screen / purchase sheets / cancel / packages / platform gates); `flutter analyze`; `dart run build_runner build` after new `@Riverpod` APIs; `bash .github/scripts/validate_ci_gates.sh` before push

**Target Platform**: Android, iOS, macOS, Windows, Linux (purchase: Win/macOS/Linux; mobile purchase deferred)

**Project Type**: Cross-platform Flutter desktop/mobile app (client of Enjoy Rails + Worker)

**Performance Goals**: Primary subscription/package offer content within ~2s on typical broadband; purchase/cancel in-progress feedback within 300ms of confirmation; post-checkout eager reconcile polling budget aligned with existing ~30s Pro verification (extend for permanent-credits delta after packages)

**Constraints**: Never open external `payUrl` for digital unlock on iOS/Android (ADR-0032, amended for Linux). Do not collect card credentials in-app. Single active auto-renew source enforced server-side (surface 409). No mid-cycle monthly↔yearly switch. No StoreKit/Play/RevenueCat in this milestone.

**Scale/Scope**: One subscription screen hub + sheets/dialogs; ~5 Rails endpoints + 1 Worker summary; domain models for auto-renew + packages; docs (`docs/features/subscription.md`, `credits-usage.md` or successor) + ADR amendment for Linux purchase

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Plan compliance |
|-----------|-----------------|
| I. Architecture | Extend `subscription` + `credits` feature folders; Rails clients under `lib/data/api/services/`; domain models UI-free; Riverpod orchestration; no feature↔feature shortcuts beyond shared `subscription_purchase_capability` and existing credits-failure CTA |
| II. Testing | Unit tests for JSON/models/repos; provider tests for purchase/cancel/reconcile extensions; widget tests for plan/package UI and mobile gate; document any manual Stripe checkout smoke in quickstart |
| III. UX consistency | Reuse Enjoy buttons/sheets/notices; all strings in ARB; haptics/tooltips per existing purchase sheet patterns |
| IV. Performance | Catalog/status are small fixed payloads; avoid work in list item builders; eager poll only after pending purchase (existing pattern) |
| V. Documentation | Update `docs/features/subscription.md` and credits docs; amend ADR-0032 (Linux external checkout) |
| Flutter Quality Gates | build_runner for new providers; format/codegen drift; analyze + test; no Flutter web |

**Post-design re-check**: Passes. Contracts document client-consumed Rails/Worker shapes only (no server changes). Complexity justified only for ADR amendment (Linux).

## Project Structure

### Documentation (this feature)

```text
specs/027-auto-renew-credit-packages/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── api-v1-subscriptions-auto-renew.md
│   ├── api-v1-credits-packages.md
│   └── worker-credits-summary.md
└── tasks.md                 # /speckit-tasks (not created here)
```

### Source Code (repository root)

```text
lib/
├── core/platform/
│   └── subscription_purchase_capability.dart   # + Linux purchase
├── data/api/services/
│   ├── subscription_api.dart                   # + plans, auto_renew, cancel
│   ├── api_providers.dart
│   └── ai/
│       └── credits_api.dart                    # + getSummary()
├── features/subscription/
│   ├── domain/                                 # + AutoRenewBilling, SubscriptionPlan, …
│   ├── data/subscription_repository.dart
│   ├── application/                            # purchase/cancel/plans providers
│   └── presentation/                           # status card, plan picker, cancel, sheets
└── features/credits/
    ├── domain/                                 # + CreditsPackage, CreditsSummary
    ├── data/                                   # Rails packages API wrapper (or under data/api)
    ├── application/                            # packages + summary providers
    └── presentation/                           # package offer UI (screen section or sheet)

test/features/subscription/…
test/features/credits/…
test/core/platform/subscription_purchase_capability_test.dart

docs/features/subscription.md
docs/features/credits-usage.md                  # or credits.md expanded
docs/decisions/0032-… (amend) or superseding ADR
```

**Structure Decision**: Stay inside existing `subscription` and `credits` feature modules. Rails package purchase client lives next to other Rails services (`lib/data/api/services/`); Worker summary extends the existing Worker `CreditsApi`. Presentation for packages may be composed into `/subscription` and/or `/credits` so discovery matches the spec without a third feature root.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Amend ADR-0032 to allow Linux external checkout | Spec + Linux as first-class desktop (ADR-0048); Linux currently silently no-ops purchase | Keep Linux blocked — leaves desktop Linux users unable to buy despite web parity goals |
