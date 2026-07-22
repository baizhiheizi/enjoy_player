# Data Model: App Auto-Renew Subscription & Credits Packages

**Feature**: `027-auto-renew-credit-packages`  
**Date**: 2026-07-22  
**Storage**: Server-sourced; client domain models only (no Drift tables)

## Entities

### SubscriptionStatus (extended)

Live snapshot from `GET /api/v1/subscriptions`.

| Field | Type | Notes |
|-------|------|--------|
| `subscriptionActive` | bool | Entitlement active |
| `subscriptionTier` | `SubscriptionTier` | `free` \| `pro` (existing) |
| `subscriptionExpireDate` | `String?` | ISO access/expiry |
| `autoRenew` | `AutoRenewBilling?` | **New**; null if no non-terminal billing subscription |

Derived (unchanged): `isPro`, `dailyCreditsLimit`.

---

### AutoRenewBilling (new)

Nested under status; also returned (partially) from start/cancel responses.

| Field | Type | Notes |
|-------|------|--------|
| `active` | bool | Billing relationship considered active for display |
| `provider` | String | e.g. `stripe` |
| `status` | String | `incomplete` \| `active` \| `past_due` \| `canceled` \| `ended` |
| `autoRenew` | bool | Will renew if true |
| `currentPeriodEnd` | `String?` | ISO |
| `cancelAtPeriodEnd` | bool | Cancel scheduled |
| `payUrl` | `String?` | Incomplete checkout only |
| `planId` | `String?` | e.g. `pro_month` |
| `tier` | String | Snapshot, usually `pro` |
| `interval` | String | `month` \| `year` |
| `amount` | num? | List-price snapshot |

**Validation / UI rules**:
- Cancel CTA when cancelable (e.g. `autoRenew == true` && `!cancelAtPeriodEnd` && status not terminal).
- Incomplete + non-null `payUrl` may offer “Continue checkout” on purchase-capable platforms.

---

### SubscriptionPlan (new)

Catalog row from `GET /api/v1/subscriptions/plans`.

| Field | Type | Notes |
|-------|------|--------|
| `id` | String | Pass to auto-renew (`pro_month`, `pro_year`) |
| `tier` | String | `pro` |
| `interval` | String | `month` \| `year` |
| `amount` | num | List price 9.99 / 99.99 |
| `currencyNote` | `String?` | Optional display hint |

**Validation**: Empty list → hide auto-renew purchase CTAs; still show status/prepaid if available.

---

### AutoRenewStartResult (new)

From `POST /api/v1/subscriptions/auto_renew`.

| Field | Type | Notes |
|-------|------|--------|
| `id` | String | Billing subscription id |
| `provider` | String | |
| `status` | String | Usually `incomplete` |
| `autoRenew` | bool | |
| `payUrl` | `String?` | Launch when non-empty |
| `planId` / `tier` / `interval` | String | Echo of plan |
| `price` | `{ interval, amount, currencyNote? }` | Confirm before/after launch |

---

### CreditsPackage (new)

From `GET /api/v1/credits/packages`.

| Field | Type | Notes |
|-------|------|--------|
| `id` | String | `credits_2` / `credits_5` / `credits_50` |
| `amount` | String | Decimal USD string (`"2.00"`) |
| `currency` | String | `USD` |
| `credits` | int | Permanent credits granted |
| `rate` | `{ usd: num, credits: int }` | Published conversion |

---

### CreditsPackagePurchaseSession (new)

From `POST /api/v1/credits/packages/purchases`.

| Field | Type | Notes |
|-------|------|--------|
| `id` | String | Payment id |
| `status` | String | `pending` |
| `paymentType` | String | `credits_package` |
| `amount` | String | |
| `payUrl` | `String?` | External checkout |
| `package` | subset of `CreditsPackage` | Confirm copy before launch |

---

### CreditsSummary (new, Worker)

From Worker `GET /credits/summary`.

| Field | Type | Notes |
|-------|------|--------|
| `tier` | String | |
| `dailyUsed` | int | |
| `dailyLimit` | int | |
| `dailyRemaining` | int | |
| `permanentAvailable` | int | **Package grant target** |
| `resetAt` | int | Epoch ms (or as API returns) |

---

### Existing (unchanged contracts)

| Entity | Role |
|--------|------|
| `PurchaseRequest` | Prepaid months + processor |
| `PaymentSession` | Prepaid Stripe/Mixin checkout |
| `PaymentProcessor` | `stripe` \| `mixin` |
| `UserProfile.subscriptionTier` | Cache only; UI reads `currentTierProvider` |

## Relationships

```text
User ──< SubscriptionStatus
            ├── entitlement (tier, active, expire)
            └── AutoRenewBilling? ──> SubscriptionPlan (by planId)

User ──< CreditsSummary (Worker wallet)
User ── purchases ──> CreditsPackage ──> CreditsPackagePurchaseSession
```

## State transitions (client-visible)

### Auto-renew

```text
[none] --start--> incomplete (+ payUrl)
incomplete --paid (webhook)--> active (autoRenew true)
active --cancel--> active/canceled (cancelAtPeriodEnd true, autoRenew false)
* --period end / ended--> autoRenew null or status ended; entitlement may drop to free
```

Client does not drive webhooks; it refreshes GET status after resume/cancel/pending poll.

### Credits package

```text
[idle] --start purchase--> pending (+ payUrl)
pending --paid--> permanentAvailable += package.credits (via summary refresh)
pending --abandon--> no credit change
```

## Validation rules (client)

1. Never launch `payUrl` when `showsMobilePurchaseUnavailable()`.
2. Auto-renew start requires a selected `plan.id` from catalog.
3. Package purchase requires a selected `package.id`.
4. Treat `409` on auto-renew as conflict (existing subscription), not a generic network blip.
5. Cancel requires confirm; on failure leave prior `autoRenew` UI state.
