# ADR-0041: Unified tier reconciliation

## Status

Accepted — 2026-07-11

## Context

Pro upgrades completed outside the app (desktop external checkout in a browser, or directly on the Enjoy web app) were not reflected until the user manually tapped the **Refresh** button on the profile page. Three independent failure modes caused this:

1. **Two competing sources of truth.** The sidebar chip and profile hero read `UserProfile.subscriptionTier` from the *cached* auth profile (`authCtrlProvider`), while the subscription screen read `subscriptionStatusProvider` (`GET /api/v1/subscriptions`). The two could diverge, and the cached one drove the most visible UI.
2. **No global resume hook.** The only `WidgetsBindingObserver` lived inside `SubscriptionScreen`, so a tier change was only reconciled while that single screen was mounted — and even then it refreshed only `subscriptionStatusProvider`, never the auth profile. From any other screen, returning from the browser did nothing.
3. **Stale cold-start cache.** `AuthRepository.loadInitialAuthState` returned the secure-storage-cached profile with no network call, so a restart kept showing the pre-upgrade `free` tier until something forced a live `GET /api/v1/profile`.

A secondary bug: `SubscriptionPurchaseCtrl.purchaseExternal` called `ref.invalidate(subscriptionStatusProvider)` *before* launching the browser — i.e. before payment completed — so it re-fetched the old free status.

Product requirement: the app must surface a tier change made **anywhere** (app-initiated checkout, or purely on the web) on the next resume or cold start, without relying on the app having launched the checkout.

## Decision

1. **Single source of truth — `currentTierProvider`.** A synchronous, `keepAlive` provider that all tier indicators read from. It prefers the live `subscriptionStatusProvider`; while that is loading (cold start) it falls back to the cached `UserProfile.subscriptionTier`; when signed out it resolves to `free`. Because it watches `subscriptionStatusProvider`, merely mounting the host forces the live status fetch on cold start.

2. **`TierReconcileCtrl` — one reconciliation entry point.** `reconcile({bool eager})` fans out to **both** sources: invalidates + awaits `subscriptionStatusProvider`, and calls `AuthCtrl.refreshProfile()` (which rewrites the secure-storage cache). It is auth-gated, debounced (30 s between non-eager runs), and has an in-flight guard. Transient network errors are swallowed and logged — never sign the user out.

3. **Global lifecycle reconciliation — `TierReconcileHost`.** A `WidgetsBindingObserver` hosted inside `RootShell` (always mounted while authenticated), replacing the screen-scoped observer removed from `SubscriptionScreen`. On `AppLifecycleState.resumed` it runs `reconcile()`; on (re)sign-in it captures the cached profile tier as the baseline and kicks a background reconcile. This covers every authenticated screen and the cold-start case.

4. **Eager polling for app-initiated purchases.** `purchaseExternal` no longer pre-invalidates status; instead it calls `markPurchasePending()` after a successful browser launch. The next resume runs `reconcile(eager: true)`, which polls `GET /api/v1/subscriptions` every 3 s for up to 30 s for fast confirmation, then clears the flag. A purchase initiated purely on the web is handled by the normal debounced resume/cold-start reconcile.

5. **Tier-change celebration.** `TierReconcileHost` listens to `currentTierProvider` and shows an `AppNotice.success` snackbar on a genuine `free → pro` transition. The baseline is captured from the cached profile at (re)sign-in, so an already-Pro user is never re-celebrated and the spurious "free" emitted during auth loading does not trigger a false celebration. During eager polling a "Verifying your upgrade…" notice is shown, resolving to the celebration or a soft "we'll keep checking" timeout message.

## Consequences

- Positive: Tier changes made anywhere surface within seconds of resume/cold start; one source of truth for all UI.
- Positive: Robust to web-only upgrades — no dependency on the app having launched checkout.
- Positive: `pro → free` expiry is also reflected automatically (no celebration); the unified provider handles it naturally.
- Negative: One extra `GET /api/v1/subscriptions` fetch on cold start and on each (debounced) resume. Mitigated by the 30 s debounce + in-flight guard.
- Negative: The eager poll is bounded to 30 s; a payment that takes longer to confirm falls back to the next debounced reconcile / cold start (with a soft "we'll keep checking" notice).
- Follow-up: when StoreKit / Play Billing lands (ADR-0032 follow-up), the same `reconcile` entry point should be invoked after a successful native purchase.

## Alternatives considered

| Alternative | Rejected because |
|-------------|------------------|
| Keep two providers, refresh both from each screen | Scattered, easy to miss a screen; the bug itself came from exactly this split |
| Deep-link / app-link callback from the browser checkout | Web-only upgrades (no app-launched session) would still be missed; also requires backend URL changes |
| Per-session status polling endpoint (`GET /subscriptions/:id`) | No such endpoint exists; polling the status endpoint is sufficient |

## Related

- [ADR-0032](0032-platform-scoped-subscription-purchase.md) — platform-scoped purchase policy
- `docs/features/subscription.md`
- `lib/features/subscription/application/current_tier_provider.dart`
- `lib/features/subscription/application/tier_reconcile_provider.dart`
- `lib/features/subscription/presentation/tier_reconcile_host.dart`
