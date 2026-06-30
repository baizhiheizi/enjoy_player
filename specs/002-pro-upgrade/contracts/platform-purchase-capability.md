# Contract: Platform Purchase Capability

**Feature**: `002-pro-upgrade` | **Consumer**: subscription presentation layer | **Version**: 1.0

## Purpose

Centralize platform rules so iOS/Android never launch external payment URLs for Pro subscription (FR-016, FR-017, SC-006).

## API

Pure function (testable):

```dart
bool supportsExternalSubscriptionPurchase({TargetPlatform? platform});
bool showsMobilePurchaseUnavailable({TargetPlatform? platform});
```

## Rules

| Platform | `supportsExternalSubscriptionPurchase` | Upgrade tap behavior |
|----------|----------------------------------------|----------------------|
| Windows | `true` | Open `PurchaseSheet` |
| macOS | `true` | Open `PurchaseSheet` |
| iOS | `false` | Show `MobilePurchaseUnavailable` dialog |
| Android | `false` | Show `MobilePurchaseUnavailable` dialog |
| Linux | `false` | Same as mobile (not a purchase target in v1) |

**Note**: Do not use `isDesktop` from `desktop_window.dart` alone — it includes Linux. Purchase requires explicit Windows || macOS check.

## PurchaseSheet visibility

| UI element | Desktop | iOS / Android |
|------------|---------|---------------|
| Tier comparison Upgrade / Extend button | Opens purchase flow | Opens coming-soon dialog |
| PurchaseSheet (duration, Stripe/Mixin) | Shown | Never mounted |
| Balance tab | Shown when capability true | Hidden |
| `launchUrl(payUrl)` | Allowed | **Must never be called** |

## MobilePurchaseUnavailable dialog

**Content** (localized):

- Title: subscription mobile purchase unavailable
- Body: explains iOS/Android in-app purchase coming soon; Pro purchased elsewhere still works
- Actions: OK (dismiss only) — **no** link to external checkout or enjoy.bot payment

## Test requirements

Widget test with `debugDefaultTargetPlatformOverride = TargetPlatform.iOS`:

- Tap Upgrade → dialog visible
- Verify `launchUrl` mock not invoked

Widget test with `TargetPlatform.windows`:

- Tap Upgrade → purchase sheet visible

## Future extension

Follow-up spec `003-ios-storekit-upgrade` will add:

```dart
bool supportsStoreKitPurchase({TargetPlatform? platform}); // iOS only
```

This contract remains; StoreKit path replaces `MobilePurchaseUnavailable` on iOS when implemented.
