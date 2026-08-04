<hash>size:4690</hash>

# `docs/features/subscription.md`

- Documents subscription entry points, live status, plan catalog, cancellation, credits packages, tier reconciliation, and platform purchase gates.
- The checked-in document still describes the previous Free/Pro comparison and should be aligned with the current Free/Lite/Pro implementation.
- Desktop purchase uses external checkout; mobile purchase remains deferred.
- `currentTierProvider` is the synchronous UI source of truth, preferring live status over cached profile data.
