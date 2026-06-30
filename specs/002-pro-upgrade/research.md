# Research: Pro Upgrade & Subscription Management

**Feature**: `002-pro-upgrade` | **Date**: 2026-06-30

## 1. Web reference implementation

**Decision**: Port behavioral parity from Enjoy web `apps/web/src/routes/subscription.tsx` and `components/subscription/*`, backed by `packages/api/src/services/subscription.ts`.

**Rationale**: Web is the canonical product definition for tier comparison, API paths, and checkout flow. Flutter UI adapts layout to mobile/desktop but keeps the same user journeys on desktop.

**Alternatives considered**:

| Alternative | Rejected because |
|-------------|------------------|
| Embed web subscription page in WebView | Violates native UX guidelines; App Store still treats as external purchase; poor desktop integration |
| Reimplement pricing/tiers client-side only | Server owns checkout amounts and subscription state |

## 2. Platform-scoped purchase (product decision B)

**Decision**: `supportsExternalSubscriptionPurchase` = `TargetPlatform.windows || TargetPlatform.macOS`. iOS and Android: status + comparison only; upgrade shows “coming soon” dialog without external URLs.

**Rationale**: Apple Guideline 3.1.1 requires IAP for digital Pro unlocks in App Store apps. External Stripe/Mixin checkout is appropriate for direct-download desktop builds. User chose to defer StoreKit to follow-up spec.

**Alternatives considered**:

| Alternative | Rejected because |
|-------------|------------------|
| Same checkout on all platforms | iOS App Review rejection risk |
| iOS links to enjoy.bot checkout | Still external digital purchase; high rejection risk |
| Hide subscription screen on mobile | Violates cross-platform status/comparison requirement |

## 3. API integration layer

**Decision**: Add `SubscriptionApi` using existing `ApiClient` against Rails API base URL (`apiClientProvider`), same as `AuthApi`.

**Rationale**: Subscription endpoints live on Enjoy Rails API (`/api/v1/subscriptions`), not the AI Worker. `ApiClient` already handles bearer auth, 401 refresh, camelCase conversion.

**Endpoints** (from web `subscription.ts`):

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/subscriptions` | Current status |
| POST | `/api/v1/subscriptions` | Body: `{ months, processor? }` → payment with `payUrl` |
| POST | `/api/v1/subscriptions/balance` | Convert balance → subscription |

**Alternatives considered**:

| Alternative | Rejected because |
|-------------|------------------|
| Derive status only from cached `UserProfile` | Missing `subscriptionActive` flag; dedicated endpoint is authoritative on web |
| New HTTP client | Duplicates auth/refresh logic |

## 4. External checkout launch

**Decision**: Use existing `url_launcher` with `LaunchMode.externalApplication` (pattern in `about_section_card.dart`, PKCE in `auth_controller.dart`).

**Rationale**: Already a dependency; opens system browser for Stripe/Mixin hosted checkout; no card data in app (FR-007).

**Alternatives considered**:

| Alternative | Rejected because |
|-------------|------------------|
| InAppWebView for checkout | PCI/policy concerns; not web pattern |
| `LaunchMode.inAppBrowserView` on iOS | Still external payment for digital goods on iOS |

## 5. State management

**Decision**: `@Riverpod` async `subscriptionStatusProvider` + mutation notifier `SubscriptionPurchaseCtrl` for purchase/balance actions.

**Rationale**: Matches `credits_usage_provider.dart` and auth patterns; easy invalidate-on-success; testable with overrides.

**Alternatives considered**:

| Alternative | Rejected because |
|-------------|------------------|
| Extend `authCtrlProvider` with subscription fields | Mixes concerns; status endpoint richer than profile snapshot |
| StatefulWidget-only | Harder to test; inconsistent with project |

## 6. Profile vs subscription status

**Decision**: Subscription screen uses dedicated `GET /api/v1/subscriptions`; after purchase or resume, also call `AuthRepository.fetchProfile()` to sync profile chip / sidebar tier.

**Rationale**: Web uses dedicated status query with 30s stale time. Profile already has `subscriptionTier` and `subscriptionExpireDate` for hero chip — keep both in sync after mutations.

## 7. Daily credits limits in UI

**Decision**: Hardcode display limits in presentation layer: Free = 1,000 / day, Pro = 60,000 / day (same constants as web `subscription-status-card.tsx`).

**Rationale**: Marketing copy aligned with web; server enforces actual quotas. Not worth an API field for v1.

## 8. Purchase sheet UX on desktop

**Decision**: Modal bottom sheet or `EnjoyModal` dialog with tabs: “Payment processor” | “Use balance” (mirror web `PurchaseModal`).

**Rationale**: Familiar web UX; `EnjoyModal` used in profile sign-out confirm. Desktop has room for two-column tier comparison + modal purchase.

**Mobile**: No purchase sheet; inline dialog on upgrade tap only.

## 9. Credits-limit upgrade discovery

**Decision**: Extend `CreditsFailure` handling with optional action callback → `context.push('/subscription')`. Add localized message + button in shared notice/snackbar pattern.

**Rationale**: Web `__root.tsx` navigates to `/subscription` on billing errors. `CreditsFailure` already exists from HTTP 402 in `ai_api_failures.dart` but is not wired to upgrade navigation everywhere.

**Scope**: Wire at least one high-traffic AI surface (e.g. lookup or transcript smart translation) plus a shared `showCreditsFailureNotice` helper for reuse.

## 10. Routing and auth

**Decision**: `/subscription` inside existing `ShellRoute` (like `/profile`, `/credits`); protected by existing auth redirect; add `from=subscription` shorthand.

**Rationale**: Signed-in account feature; shell chrome acceptable. Consistent with profile/credits placement.

## 11. Localization

**Decision**: Port string keys from web `locales/en/subscription.json` into ARB (`subscriptionTitle`, `subscriptionUpgrade`, etc.).

**Rationale**: Constitution III; bilingual en/zh minimum per project.

## 12. ADR

**Decision**: ADR-0032 documents platform-scoped purchase and deferred mobile IAP.

**Rationale**: Product-scope decision costly to reverse; explains why iOS differs from desktop.

## 13. Android purchase scope

**Decision**: Treat Android identical to iOS for v1 (no external checkout). Play Billing deferred with StoreKit.

**Rationale**: Play Store policy mirrors App Store for digital subscriptions. Safer default until dedicated Android billing spec.
