/// Fetches live subscription status from Enjoy API.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/features/subscription/data/subscription_repository.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';

part 'subscription_status_provider.g.dart';

@Riverpod(keepAlive: true)
Future<SubscriptionStatus> subscriptionStatus(Ref ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getStatus();
}
