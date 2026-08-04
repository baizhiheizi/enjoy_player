<hash>size:8911</hash>

# `lib/features/subscription/application/tier_reconcile_provider.dart`

- Keep-alive Riverpod `TierReconcileCtrl` refreshes live status, cached profile, and credits summary.
- Normal reconciliation is debounced for 30 seconds.
- Pending subscription or credits-package purchases poll every 3 seconds for up to 30 seconds.
- Subscription confirmation accepts `status.isPaidTier`; package confirmation detects permanent-credit growth.
- Failures are logged through `logNamed('subscription.reconcile')` without crashing the shell.
