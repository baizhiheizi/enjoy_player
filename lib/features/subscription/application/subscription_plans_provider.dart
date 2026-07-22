/// Catalog of sellable auto-renew plans.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/features/subscription/data/subscription_repository.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_plan.dart';

part 'subscription_plans_provider.g.dart';

@Riverpod(keepAlive: false)
Future<List<SubscriptionPlan>> subscriptionPlans(Ref ref) {
  return ref.watch(subscriptionRepositoryProvider).listPlans();
}
