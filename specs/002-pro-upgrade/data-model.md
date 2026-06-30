# Data Model: Pro Upgrade & Subscription Management

**Feature**: `002-pro-upgrade` | **Date**: 2026-06-30

No new Drift tables. Entities are API-backed domain models and ephemeral UI state.

## Entities

### SubscriptionStatus

Authoritative subscription snapshot from `GET /api/v1/subscriptions`.

| Field | Type | Description |
|-------|------|-------------|
| `subscriptionActive` | `bool` | Whether subscription is currently active |
| `subscriptionTier` | `SubscriptionTier` | `free` or `pro` |
| `subscriptionExpireDate` | `String?` | ISO 8601 expiration; null if none |

**Derived (presentation)**:

| Derived | Rule |
|---------|------|
| `dailyCreditsLimit` | `free` → 1_000; `pro` → 60_000 |
| `isPro` | `tier == pro && subscriptionActive` |

**Validation**:

- Parse tier case-insensitively; unknown → `free`.
- Expiration displayed with locale-aware date formatting; null → “Never expires” copy.

**Note**: Overlaps `UserProfile.subscriptionTier` / `subscriptionExpireDate` — profile is a cache; this entity is live server state for the subscription screen.

### SubscriptionTier (enum)

Reuse existing `SubscriptionTier { free, pro }` from `lib/features/auth/domain/user_profile.dart`.

### PaymentProcessor (enum)

| Value | Description |
|-------|-------------|
| `stripe` | Card, WeChat Pay, Google Pay via Stripe checkout |
| `mixin` | Crypto (USDT, BTC, ETH, DOGE) via Mixin |

### PurchaseRequest (desktop only)

| Field | Type | Validation |
|-------|------|------------|
| `months` | `int` | 1–12 inclusive |
| `processor` | `PaymentProcessor` | Required for external checkout |

Sent as JSON body to `POST /api/v1/subscriptions` (camelCase on wire).

### PaymentSession

Response from purchase POST.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Payment UUID |
| `paymentType` | `String` | e.g. `subscription` |
| `processor` | `PaymentProcessor` | |
| `status` | `PaymentStatus` | `pending`, `succeeded`, `expired` |
| `payUrl` | `String?` | External checkout URL |
| `createdAt` | `String` | ISO timestamp |

**State transition (client view)**:

```text
[user confirms] → POST purchase → pending + payUrl
[user completes in browser] → (server webhook) → succeeded
[timeout] → expired
```

Client refreshes `SubscriptionStatus` after resume; does not poll payment status in v1.

### BalancePurchaseResult

Same shape as `SubscriptionStatus` (response from `POST /api/v1/subscriptions/balance`).

### PlanComparisonTier (presentation)

Static marketing definition — not persisted.

| Tier | Price display | Daily credits | Feature bullet keys |
|------|---------------|---------------|---------------------|
| Free | Localized “Free” | 1,000 | translation, smartTranslation, dictionary, asr, tts, assessment (limited copy) |
| Pro | $9.99/month (localized) | 60,000 | same features (extensive/unlimited copy) |

### PlatformPurchaseCapability

Runtime capability — not persisted.

| Attribute | Value |
|-----------|-------|
| `supportsExternalCheckout` | `true` on Windows, macOS |
| `supportsBalancePurchase` | same as external checkout |
| `showsMobilePurchaseUnavailable` | `true` on iOS, Android |

## Relationships

```text
UserProfile (cache) ──may lag──► SubscriptionStatus (live)
PurchaseRequest ──creates──► PaymentSession ──user completes──► SubscriptionStatus (refreshed)
Account balance (UserProfile.balance) ──desktop POST balance──► SubscriptionStatus (refreshed)
CreditsFailure (402) ──navigates──► SubscriptionScreen
```

## Unchanged persistence

| Store | Role |
|-------|------|
| Secure storage | Profile snapshot may update after purchase refresh |
| Drift | No schema change |
| No local subscription cache | Refetch on screen open; optional 30s Riverpod cache |

## Out of scope (follow-up data)

| Entity | Future spec |
|--------|-------------|
| `StoreKitTransaction` | iOS IAP receipt |
| `PlayPurchaseToken` | Android Play Billing |
| Payment history list | Web has `GET /api/v1/mine/payments` — not required for v1 |
