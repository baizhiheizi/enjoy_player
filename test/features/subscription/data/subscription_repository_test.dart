import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/services/subscription_api.dart';
import 'package:enjoy_player/features/subscription/data/subscription_repository.dart';
import 'package:enjoy_player/features/subscription/domain/payment_processor.dart';
import 'package:enjoy_player/features/subscription/domain/purchase_request.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSubscriptionApi implements SubscriptionApi {
  _FakeSubscriptionApi(this._handler);

  final Future<Map<String, dynamic>> Function(String method) _handler;

  @override
  ApiClient get client => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getStatus() => _handler('getStatus');

  @override
  Future<Map<String, dynamic>> purchase({
    required int months,
    PaymentProcessor processor = PaymentProcessor.stripe,
  }) => _handler('purchase');
}

void main() {
  group('SubscriptionRepository', () {
    test('getStatus returns parsed model', () async {
      final repo = SubscriptionRepository(
        _FakeSubscriptionApi((_) async {
          return {
            'subscriptionActive': true,
            'subscriptionTier': 'pro',
            'subscriptionExpireDate': null,
          };
        }),
      );

      final status = await repo.getStatus();
      expect(status.isPro, isTrue);
    });

    test('purchase returns payment session with payUrl', () async {
      final repo = SubscriptionRepository(
        _FakeSubscriptionApi((method) async {
          expect(method, 'purchase');
          return {
            'id': 'p1',
            'paymentType': 'subscription',
            'processor': 'stripe',
            'status': 'pending',
            'payUrl': 'https://pay.example.com',
            'createdAt': '2026-06-30T00:00:00.000Z',
          };
        }),
      );

      final session = await repo.purchase(
        const PurchaseRequest(months: 1, processor: PaymentProcessor.stripe),
      );
      expect(session.payUrl, 'https://pay.example.com');
    });

    test('maps 402 to CreditsFailure', () async {
      final repo = SubscriptionRepository(
        _ThrowingApi(const ApiException(message: 'limit', statusCode: 402)),
      );

      expect(() => repo.getStatus(), throwsA(isA<CreditsFailure>()));
    });
  });
}

class _ThrowingApi implements SubscriptionApi {
  _ThrowingApi(this.error);

  final ApiException error;

  @override
  ApiClient get client => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getStatus() => throw error;

  @override
  Future<Map<String, dynamic>> purchase({
    required int months,
    PaymentProcessor processor = PaymentProcessor.stripe,
  }) => throw error;
}
