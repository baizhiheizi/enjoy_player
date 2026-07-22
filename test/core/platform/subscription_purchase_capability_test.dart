import 'package:enjoy_player/core/platform/subscription_purchase_capability.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('supportsExternalSubscriptionPurchase', () {
    test('windows, macOS, and linux true', () {
      expect(
        supportsExternalSubscriptionPurchase(platform: TargetPlatform.windows),
        isTrue,
      );
      expect(
        supportsExternalSubscriptionPurchase(platform: TargetPlatform.macOS),
        isTrue,
      );
      expect(
        supportsExternalSubscriptionPurchase(platform: TargetPlatform.linux),
        isTrue,
      );
    });

    test('ios and android false', () {
      expect(
        supportsExternalSubscriptionPurchase(platform: TargetPlatform.iOS),
        isFalse,
      );
      expect(
        supportsExternalSubscriptionPurchase(platform: TargetPlatform.android),
        isFalse,
      );
    });
  });

  group('showsMobilePurchaseUnavailable', () {
    test('ios and android true', () {
      expect(
        showsMobilePurchaseUnavailable(platform: TargetPlatform.iOS),
        isTrue,
      );
      expect(
        showsMobilePurchaseUnavailable(platform: TargetPlatform.android),
        isTrue,
      );
    });

    test('windows false', () {
      expect(
        showsMobilePurchaseUnavailable(platform: TargetPlatform.windows),
        isFalse,
      );
    });
  });
}
