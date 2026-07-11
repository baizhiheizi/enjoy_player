/// External checkout mutations for Pro subscription.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:enjoy_player/features/subscription/application/tier_reconcile_provider.dart';
import 'package:enjoy_player/features/subscription/data/subscription_repository.dart';
import 'package:enjoy_player/features/subscription/domain/payment_processor.dart';
import 'package:enjoy_player/features/subscription/domain/payment_session.dart';
import 'package:enjoy_player/features/subscription/domain/purchase_request.dart';

part 'subscription_purchase_provider.g.dart';

@Riverpod(keepAlive: true)
class SubscriptionPurchaseCtrl extends _$SubscriptionPurchaseCtrl {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<PaymentSession?> purchaseExternal({
    required int months,
    required PaymentProcessor processor,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      final session = await repo.purchase(
        PurchaseRequest(months: months, processor: processor),
      );
      state = const AsyncData(null);

      final url = session.payUrl;
      if (url == null || url.isEmpty) {
        throw StateError('missing_pay_url');
      }
      final uri = Uri.tryParse(url);
      if (uri == null) {
        throw StateError('invalid_pay_url');
      }
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('launch_failed');
      }
      // Mark a purchase as pending so the next app resume reconciles eagerly
      // (polls the status endpoint for fast confirmation). See ADR-0041.
      ref.read(tierReconcileCtrlProvider.notifier).markPurchasePending();
      return session;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
