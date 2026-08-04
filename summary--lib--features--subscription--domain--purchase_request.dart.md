<hash>size:1172</hash>

# `lib/features/subscription/domain/purchase_request.dart`

- `PurchaseRequest` carries required `months`, `processor`, and `tier`; `toJson` serializes all three.
- `prepaidUnitPriceForTier` locates a tier's monthly plan in the server-provided catalog.
- Missing pricing returns `null` so callers show loading/disabled state instead of a hardcoded fallback.
