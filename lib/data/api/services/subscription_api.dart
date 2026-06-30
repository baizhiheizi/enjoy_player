/// REST client for Enjoy subscription endpoints.
library;

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/features/subscription/domain/payment_processor.dart';

class SubscriptionApi {
  SubscriptionApi(this._client);

  final ApiClient _client;

  static const _path = '/api/v1/subscriptions';

  Future<Map<String, dynamic>> getStatus() => _client.getJson(_path);

  Future<Map<String, dynamic>> purchase({
    required int months,
    PaymentProcessor processor = PaymentProcessor.stripe,
  }) => _client.postJson(
    _path,
    body: {'months': months, 'processor': processor.apiValue},
  );

  Future<Map<String, dynamic>> purchaseWithBalance() =>
      _client.postJson('$_path/balance', body: const {});
}
