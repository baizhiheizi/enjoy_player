/// REST client for Enjoy subscription endpoints.
library;

import 'package:enjoy_player/data/api/rest_api.dart';
import 'package:enjoy_player/features/subscription/domain/payment_processor.dart';

class SubscriptionApi extends RestApi {
  SubscriptionApi(super.client);

  static const _path = '/api/v1/subscriptions';

  Future<Map<String, dynamic>> getStatus() => client.getJson(_path);

  Future<Map<String, dynamic>> purchase({
    required int months,
    PaymentProcessor processor = PaymentProcessor.stripe,
  }) => client.postJson(
    _path,
    body: {'months': months, 'processor': processor.apiValue},
  );
}
