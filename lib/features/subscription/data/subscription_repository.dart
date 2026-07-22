/// Orchestrates subscription API calls and maps failures to [AppFailure].
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/services/subscription_api.dart';
import 'package:enjoy_player/data/api/services/api_providers.dart';
import 'package:enjoy_player/features/subscription/domain/auto_renew_billing.dart';
import 'package:enjoy_player/features/subscription/domain/auto_renew_start_result.dart';
import 'package:enjoy_player/features/subscription/domain/payment_session.dart';
import 'package:enjoy_player/features/subscription/domain/purchase_request.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_plan.dart';
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

  Future<List<SubscriptionPlan>> listPlans() async {
    try {
      final json = await _api.listPlans();
      final raw = json['plans'];
      if (raw is! List) return const [];
      final plans = <SubscriptionPlan>[];
      for (final e in raw) {
        final map = castJsonObjectOrNull(e);
        if (map != null) plans.add(SubscriptionPlan.fromJson(map));
      }
      return plans;
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

  Future<AutoRenewStartResult> startAutoRenew({required String planId}) async {
    try {
      final json = await _api.startAutoRenew(planId: planId);
      return AutoRenewStartResult.fromJson(json);
    } on ApiException catch (e) {
      throw _mapApiException(e);
    } on FormatException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  Future<AutoRenewBilling> cancelAutoRenew() async {
    try {
      final json = await _api.cancelAutoRenew();
      // Cancel may return billing fields at top level or nested.
      final nested = json['autoRenew'];
      if (nested is Map) {
        return AutoRenewBilling.fromJson(Map<String, dynamic>.from(nested));
      }
      return AutoRenewBilling.fromJson(json);
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
    if (e.statusCode == 409) {
      return SubscriptionConflictFailure(e.message);
    }
    return NetworkFailure(e.message, statusCode: e.statusCode);
  }
}
