# Research: App Auto-Renew Subscription & Credits Packages

**Feature**: `027-auto-renew-credit-packages`  
**Date**: 2026-07-22

## R1 — Client scope vs backend ownership

**Decision**: App-only consumption of already-shipped Enjoy Web Rails + Worker APIs. No Rails/Worker schema or webhook changes in this feature.

**Rationale**: Web specs `001` / `002` / `004` already define auto-renew plans, cancel, and credits packages. Player gap is purely client (API methods, models, UI, reconcile).

**Alternatives considered**:
- Reimplement billing in-app → rejected (duplicates server of record).
- Wait for RevenueCat → rejected (spec defers store IAP; desktop needs parity now).

---

## R2 — Platform purchase gate (Linux)

**Decision**: Extend `supportsExternalSubscriptionPurchase` to `windows || macOS || linux`. Amend ADR-0032 accordingly. Keep iOS/Android on “coming soon” (no external `payUrl`).

**Rationale**: Spec 027 lists Linux purchase Yes; ADR-0048 treats Linux as first-class desktop; today’s helper excludes Linux so upgrade taps silently no-op. External Stripe/Mixin checkout is appropriate for direct-download Linux builds the same as Windows/macOS.

**Alternatives considered**:
- Keep ADR-0032 Win/mac only → contradicts 027 and leaves Linux users stuck.
- Use `!kIsWeb && (desktop)` via a broader helper → risk of accidental future platform; prefer explicit enum list.

---

## R3 — Module placement

**Decision**:
- Auto-renew catalog/status/cancel/start → extend `lib/features/subscription` + `SubscriptionApi`.
- Credits packages catalog/purchase → extend `lib/features/credits` with a Rails packages client under `lib/data/api/services/` (new thin service or co-located `credits_packages_api.dart`).
- Permanent balance → extend Worker `CreditsApi` with `getSummary()` (`GET /credits/summary`).

**Rationale**: Matches existing boundaries (subscription already owns Pro purchase; credits owns usage UI). Avoids a third billing feature root.

**Alternatives considered**:
- Put packages only under subscription → conflates permanent top-ups with Pro entitlement UX.
- Duplicate `@enjoy/api` TS client → Flutter already has its own `ApiClient`; port shapes, don’t share TS.

---

## R4 — Status model extension

**Decision**: Extend `SubscriptionStatus` with optional nested `AutoRenewBilling? autoRenew` mirroring Rails `auto_renew` (camelCase via `ApiClient`). Keep top-level entitlement fields as source for `currentTierProvider` / Pro gates.

**Rationale**: Web GET status is additive; prepaid-only users send `autoRenew: null`. Existing `isPro` / daily limit math stays on top-level fields.

**Alternatives considered**:
- Parallel provider only for auto-renew → extra fetch; nested object is already on the same GET.

---

## R5 — Checkout UX (auto-renew vs prepaid)

**Decision**: Make **auto-renew plan selection** (monthly / yearly from `GET …/plans`) the primary upgrade path on purchase-capable platforms. Keep prepaid months (+ optional balance later) as a clearly labeled secondary path (“Pay for months once” / existing sheet), not removed.

**Rationale**: Spec FR-015 requires prepaid remain; web leads with auto-renew. Primary CTA should match product direction without regressing prepaid.

**Alternatives considered**:
- Replace prepaid entirely → violates keep-prepaid requirement.
- Two equal primary CTAs without hierarchy → clutter; prefer primary auto-renew + secondary prepaid.

---

## R6 — Cancel UX

**Decision**: Show cancel auto-renew on **all platforms** when `autoRenew` is non-null and cancelable (`autoRenew == true` / not already `cancelAtPeriodEnd` / status allows). Confirm dialog → `POST …/cancel` → refresh status + notice with access-through date.

**Rationale**: Spec allows cancel on mobile for users who subscribed on web/desktop; cancel does not open external payment.

**Alternatives considered**:
- Desktop-only cancel → worse for mobile users who only use the app.

---

## R7 — Post-purchase reconciliation

**Decision**:
- Auto-renew / prepaid Pro: reuse `TierReconcileCtrl.markPurchasePending()` + eager Pro poll.
- Credits packages: introduce a parallel “package purchase pending” arm that invalidates/polls Worker `creditsSummary` until `permanentAvailable` increases (or soft timeout), without requiring a free→Pro transition.

**Rationale**: Spec SC-004 needs visible permanent credits after package pay; today’s eager path only watches Pro tier.

**Alternatives considered**:
- Manual pull-to-refresh only → fails SC and supportability.
- Poll Rails payments history → heavier; Worker summary is the product balance.

---

## R8 — Credits summary dependency

**Decision**: Add Worker `GET /credits/summary` to the Flutter Worker credits client and surface permanent/daily remaining on subscription and/or credits UI enough to prove package grant (profile chip or package section standing).

**Rationale**: App currently only has usage logs (`/credits/usages`) and “used today” derived from logs — no permanent wallet view. Package parity requires summary.

**Alternatives considered**:
- Infer grant from usages only → no permanent balance field.
- Rails-only balance → permanent credits live on Worker wallet.

---

## R9 — JSON / error handling

**Decision**: Continue relying on `ApiClient` snake↔camel conversion. Map `400`/`422` → user-facing validation/network failure; `409` → distinct conflict message for second auto-renew; `404` on cancel → “nothing to cancel”; `503` on package checkout → retryable error. Error bodies remain string messages as today.

**Rationale**: Matches existing repository mapping style and web contracts.

---

## R10 — Localization & docs

**Decision**: New ARB keys for plan interval, auto-renew on/off, cancel confirm, package prices/credits, mobile coming soon reuse, conflict/409 copy. Update `docs/features/subscription.md` and expand credits feature docs for packages + summary. Amend ADR-0032 for Linux.

**Rationale**: Constitution III/V.

---

## Resolved unknowns

| Topic | Resolution |
|-------|------------|
| Backend ready? | Yes — consume Rails v1 + Worker summary |
| Linux purchase? | Yes — amend ADR-0032 |
| Primary UI home for packages? | Offer on `/subscription` (alongside plans) and discoverable from credits/402 path; detailed standing via summary |
| Mid-cycle plan switch? | Out of scope (server + product) |
| Store IAP? | Out of scope |
