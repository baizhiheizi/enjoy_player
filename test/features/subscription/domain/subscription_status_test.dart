import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/domain/payment_session.dart';
import 'package:enjoy_player/features/subscription/domain/payment_processor.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionStatus.fromJson', () {
    test('parses pro active status', () {
      final status = SubscriptionStatus.fromJson({
        'subscriptionActive': true,
        'subscriptionTier': 'pro',
        'subscriptionExpireDate': '2026-12-31T00:00:00.000Z',
      });

      expect(status.subscriptionActive, isTrue);
      expect(status.subscriptionTier, SubscriptionTier.pro);
      expect(status.dailyCreditsLimit, 60_000);
      expect(status.isPro, isTrue);
    });

    test('defaults unknown tier to free', () {
      final status = SubscriptionStatus.fromJson({
        'subscriptionActive': false,
        'subscriptionTier': 'unknown',
      });

      expect(status.subscriptionTier, SubscriptionTier.free);
      expect(status.dailyCreditsLimit, 1_000);
    });

    test('expired pro uses free daily credits limit', () {
      final status = SubscriptionStatus.fromJson({
        'subscriptionActive': false,
        'subscriptionTier': 'pro',
        'subscriptionExpireDate': '2020-01-01T00:00:00.000Z',
      });

      expect(status.isPro, isFalse);
      expect(status.dailyCreditsLimit, 1_000);
    });

    test('parses nested autoRenew', () {
      final status = SubscriptionStatus.fromJson({
        'subscriptionActive': true,
        'subscriptionTier': 'pro',
        'autoRenew': {
          'active': true,
          'provider': 'stripe',
          'status': 'active',
          'autoRenew': true,
          'cancelAtPeriodEnd': false,
          'interval': 'year',
          'amount': 99.99,
          'tier': 'pro',
        },
      });
      expect(status.autoRenew?.interval, 'year');
      expect(status.autoRenew?.amount, 99.99);
    });

    test('null autoRenew for prepaid-only', () {
      final status = SubscriptionStatus.fromJson({
        'subscriptionActive': true,
        'subscriptionTier': 'pro',
        'autoRenew': null,
      });
      expect(status.autoRenew, isNull);
    });
  });

  group('PaymentSession.fromJson', () {
    test('parses checkout session', () {
      final session = PaymentSession.fromJson({
        'id': 'pay-1',
        'paymentType': 'subscription',
        'processor': 'stripe',
        'status': 'pending',
        'payUrl': 'https://checkout.example.com',
        'createdAt': '2026-06-30T00:00:00.000Z',
      });

      expect(session.processor, PaymentProcessor.stripe);
      expect(session.status, PaymentStatus.pending);
      expect(session.payUrl, 'https://checkout.example.com');
    });
  });
}
