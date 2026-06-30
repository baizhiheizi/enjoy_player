/// Riverpod wiring for [SubscriptionApi].
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/data/api/services/subscription_api.dart';

part 'subscription_api_provider.g.dart';

@Riverpod(keepAlive: true)
SubscriptionApi subscriptionApi(Ref ref) {
  return SubscriptionApi(ref.watch(apiClientProvider));
}
