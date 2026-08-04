<hash>size:5133</hash>

# `lib/features/subscription/presentation/tier_reconcile_host.dart`

- `TierReconcileHost` is a global authenticated-shell lifecycle observer.
- Reconciles on first frame, sign-in, and app resume; pending purchases use eager polling.
- Tracks the last emitted tier to detect genuine Free-to-paid changes without duplicate celebration.
- Lite and Pro upgrades receive tier-specific success notices.
