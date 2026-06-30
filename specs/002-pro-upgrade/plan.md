# Implementation Plan: Pro Upgrade & Subscription Management

**Branch**: `002-pro-upgrade` | **Date**: 2026-06-30 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-pro-upgrade/spec.md`

## Summary

Port Enjoy web subscription management into Enjoy Player as a new `subscription` feature module. All platforms get a `/subscription` screen (status card, Free vs Pro comparison, profile/sidebar entry points, credits-limit upgrade CTAs). **Purchase is desktop-only (Windows + macOS)**: Stripe/Mixin external checkout via `url_launcher` and balance conversion, mirroring the web `PurchaseModal`. **iOS and Android show informational “mobile purchase coming soon”** instead of external checkout (App Store policy; StoreKit deferred to follow-up spec `003-*`).

Reuse existing `ApiClient` + Rails API base URL, `UserProfile.subscriptionTier` for profile chip parity, and `CreditsFailure` (HTTP 402) for upgrade discovery.

## Technical Context

**Language/Version**: Dart ^3.12, Flutter stable (SDK constraint in `pubspec.yaml`)

**Primary Dependencies**: Riverpod 3 (`@riverpod`), go_router, existing `ApiClient` / `AuthRepository`, `url_launcher` (already in pubspec), shared UI primitives (`EnjoyCard`, `EnjoyButton`, `EnjoyModal`, `Skeleton`)

**Storage**: No new Drift tables. Subscription status fetched from Enjoy API; profile snapshot refreshed via existing `AuthRepository.fetchProfile()` after purchase. No local persistence of payment sessions.

**Testing**: `flutter test` — unit tests for domain parsers, `SubscriptionRepository`, platform capability helper; widget tests for subscription screen (loading/error/desktop purchase/mobile stub); extend auth redirect tests for `/subscription` `from` shorthand

**Target Platform**: Android, iOS, macOS, Windows (no Flutter web). Purchase: **Windows + macOS only**.

**Project Type**: Flutter native mobile/desktop app

**Performance Goals**: Subscription status screen primary content within 2s on broadband (SC-001); purchase confirm → external browser launch within 300ms feedback (QR-004); status refresh on app resume without blocking UI

**Constraints**: No external payment URLs on iOS/Android (FR-016/FR-017); no StoreKit/Play Billing in this milestone; no Drift schema changes; single Enjoy API auth via bearer token; camelCase JSON via existing `ApiClient` interceptors

**Scale/Scope**: New feature module (~12–15 Dart files), 1 route, ARB strings (~40 keys), 1 API service, docs + ADR, ~6–8 test files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- **Pass**: New code under `lib/features/subscription/{application,data,domain,presentation}`; API service in `lib/data/api/services/subscription_api.dart` (matches existing `auth_api.dart` pattern).
- **Pass**: Domain models (`SubscriptionStatus`, `PurchaseRequest`, `PaymentSession`) are UI-free.
- **Pass**: No Drift changes; no new global singletons.
- **Pass**: Riverpod notifiers for status fetch and purchase mutations; `ref.invalidate` + profile refresh after success.
- **Pass**: No `print()`; no `media_kit` involvement.

### II. Testing Defines the Contract

- **Required**: Unit tests — JSON parsing for subscription status and payment response; `supportsExternalSubscriptionPurchase` platform matrix.
- **Required**: Repository tests — mock `ApiClient` success/failure for getStatus, purchase, purchaseWithBalance.
- **Required**: Widget tests — subscription screen loading/error; desktop shows purchase sheet trigger; iOS/Android shows coming-soon dialog (platform override in test).
- **Manual**: End-to-end Stripe checkout on Windows or macOS with test account; iOS simulator confirms no external URL launch.
- **Codegen**: Run `dart run build_runner build` after adding `@Riverpod` providers.

### III. User Experience Consistency

- **Pass**: All strings in `lib/l10n/app_en.arb` + `app_zh.arb`; run `flutter gen-l10n`.
- **Pass**: Tappable surfaces via `EnjoyTappableSurface` / `EnjoyButton`; purchase sheet via `EnjoyModal` or bottom sheet pattern used elsewhere.
- **Pass**: Icon-only actions get tooltips where applicable.
- **Docs**: New `docs/features/subscription.md`; update `docs/features/auth.md` (navigation) if needed.

### IV. Performance Is a Requirement

- **Pass**: Single GET on screen open; 30s stale cache via Riverpod `keepAlive` + manual refresh; purchase mutation shows inline loading on button.
- **Pass**: No heavy work in `build`; tier comparison is static localized strings.
- **Evidence**: Manual timing on Windows — status card visible <2s; purchase button shows spinner immediately.

### V. Documentation and Traceability

- **Required**: ADR `docs/decisions/0032-platform-scoped-subscription-purchase.md` — desktop external checkout vs deferred mobile IAP.
- **Required**: `docs/features/subscription.md` + index link in `docs/README.md`.
- **No exception** needed.

**Post-design re-check**: All gates pass. Platform split is documented in ADR, not a constitution violation.

## Project Structure

### Documentation (this feature)

```text
specs/002-pro-upgrade/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1 validation guide
├── contracts/           # Phase 1
│   ├── subscription-api.md
│   ├── subscription-routing.md
│   ├── platform-purchase-capability.md
│   └── credits-upgrade-cta.md
└── tasks.md             # Phase 2 (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── routing/
│   │   ├── app_router.dart              # Add /subscription route
│   │   └── auth_redirect.dart           # Add subscription from-shorthand
│   └── platform/
│       └── subscription_purchase_capability.dart  # NEW — desktop vs mobile
├── data/api/services/
│   ├── subscription_api.dart            # NEW
│   └── subscription_api_provider.dart   # NEW @Riverpod
├── features/subscription/
│   ├── domain/
│   │   ├── subscription_status.dart
│   │   ├── payment_processor.dart
│   │   ├── purchase_request.dart
│   │   └── payment_session.dart
│   ├── data/
│   │   └── subscription_repository.dart
│   ├── application/
│   │   ├── subscription_status_provider.dart
│   │   └── subscription_purchase_provider.dart
│   └── presentation/
│       ├── subscription_screen.dart
│       └── widgets/
│           ├── subscription_status_card.dart
│           ├── tier_comparison.dart
│           ├── purchase_sheet.dart          # Desktop only
│           └── mobile_purchase_unavailable.dart
├── features/auth/presentation/
│   └── profile_screen.dart                # Add subscription nav tile
├── features/auth/presentation/widgets/
│   └── sidebar_account_chip.dart          # Optional Pro badge / subscription link
├── features/credits/ or core/notices/
│   └── credits_failure_actions.dart       # NEW — 402 → /subscription CTA
└── l10n/
    ├── app_en.arb
    └── app_zh.arb

test/
├── features/subscription/
│   ├── domain/subscription_status_test.dart
│   ├── data/subscription_repository_test.dart
│   └── presentation/subscription_screen_test.dart
└── core/platform/
    └── subscription_purchase_capability_test.dart

docs/
├── features/subscription.md
└── decisions/0032-platform-scoped-subscription-purchase.md
```

**Structure Decision**: Dedicated `subscription` feature module keeps auth/profile thin. API service lives in `lib/data/api/services/` consistent with `auth_api.dart`. Platform capability is a tiny pure helper in `lib/core/platform/` testable without `dart:io` in widgets (use `defaultTargetPlatform` + optional injectable override for tests).

## Complexity Tracking

> No constitution violations.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

## Implementation Phases (for `/speckit-tasks`)

### Phase A — Domain + API + repository (foundation)

1. Add domain models parsing Enjoy API camelCase JSON (mirror web `SubscriptionStatus`, `PaymentResponse`).
2. Add `SubscriptionApi` — `GET/POST /api/v1/subscriptions`, `POST /api/v1/subscriptions/balance`.
3. Add `SubscriptionRepository` orchestrating API + error mapping to `AppFailure`.
4. Unit tests for parsers and repository.

### Phase B — Subscription screen — cross-platform (P1 story 1, P3 story 5)

1. Add `@Riverpod` `subscriptionStatusProvider` (async, refreshable).
2. Build `SubscriptionScreen` with status card + tier comparison (port web copy/structure).
3. Register `/subscription` in `app_router.dart` inside `ShellRoute`.
4. Add profile nav tile + optional sidebar link.
5. Extend `auth_redirect.dart` `from` shorthand: `subscription` → `/subscription`.
6. Widget tests for loading/error/content states.

### Phase C — Desktop purchase flow (P1 story 2, P2 story 3)

1. Add `supportsExternalSubscriptionPurchase` (Windows || macOS).
2. Build `PurchaseSheet` — duration 1–12, Stripe/Mixin radio, total price, continue button.
3. Add `subscriptionPurchaseProvider` mutation — POST purchase → `launchUrl(payUrl, externalApplication)`.
4. Balance tab + confirmation dialog; POST balance → refresh status + `authCtrlProvider` profile.
5. Refresh status on `AppLifecycleState.resumed` when returning from browser.
6. Repository/widget tests for desktop path.

### Phase D — Mobile guardrails + credits CTA (P2 stories 3–4)

1. On iOS/Android, upgrade/extend opens `MobilePurchaseUnavailable` dialog (localized, no URL).
2. Add shared helper for `CreditsFailure` surfaces — primary action navigates to `/subscription`.
3. Wire into AI error presentation paths (lookup, transcript AI, playground if applicable).
4. Widget test: mobile platform override shows coming-soon, never calls launchUrl.

### Phase E — Docs & validation

1. `docs/features/subscription.md`, ADR-0032, `docs/decisions/README.md` index.
2. `flutter gen-l10n`, `dart run build_runner build`, `flutter analyze`, `flutter test`.
3. Manual quickstart (desktop checkout + iOS coming-soon).

## Risk Notes

| Risk | Mitigation |
|------|------------|
| App Review if external URL leaks on iOS | Centralize capability check; widget test asserts no `launchUrl` on iOS |
| Stale Pro status after desktop payment | Refresh on lifecycle resume + manual retry; invalidate profile provider |
| Android Play policy same as iOS | Treat Android same as iOS for purchase (no external checkout) until Play Billing spec |
| Pricing drift vs web | Document $9.99/mo in ARB; server is source of truth for checkout amount |
| `isDesktop` includes Linux | Purchase capability uses explicit Windows \|\| macOS check, not `isDesktop` |
