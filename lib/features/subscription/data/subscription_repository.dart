/// Orchestrates subscription API calls and maps failures to [AppFailure].
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/services/subscription_api.dart';
import 'package:enjoy_player/data/api/services/api_providers.dart';
import 'package:enjoy_player/features/subscription/domain/payment_session.dart';
import 'package:enjoy_player/features/subscription/domain/purchase_request.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';

part 'subscription_repository.g.dart';

@Riverpod(keepAlive: true)
SubscriptionRepository subscriptionRepository(Ref ref) {
  return SubscriptionRepository(ref.watch(subscriptionApiProvider));
}

class SubscriptionRepository {
  SubscriptionRepository(this._api);

  final SubscriptionApi _api;

  Future<SubscriptionStatus> getStatus() async {
    try {
      final json = await _api.getStatus();
      return SubscriptionStatus.fromJson(json);
    } on ApiException catch (e) {
      throw _mapApiException(e);
    } on FormatException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  Future<PaymentSession> purchase(PurchaseRequest request) async {
    try {
      final json = await _api.purchase(
        months: request.months,
        processor: request.processor,
      );
      return PaymentSession.fromJson(json);
    } on ApiException catch (e) {
      throw _mapApiException(e);
    } on FormatException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  AppFailure _mapApiException(ApiException e) {
    if (e.statusCode == 402) {
      return CreditsFailure(e.message);
    }
    return NetworkFailure(e.message);
  }
}
