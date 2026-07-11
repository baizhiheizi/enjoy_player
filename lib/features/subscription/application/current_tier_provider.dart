/// Single source of truth for the subscription tier shown in UI.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';

part 'current_tier_provider.g.dart';

/// The current subscription tier, as a single synchronous source of truth.
///
/// Prefers the live [subscriptionStatusProvider] (authoritative server status);
/// falls back to the cached [UserProfile.subscriptionTier] carried by
/// [authCtrlProvider] so UI can render instantly on cold start before the
/// status fetch resolves. When signed out, resolves to [SubscriptionTier.free].
///
/// All tier indicators (sidebar chip, profile hero card) must read this
/// provider rather than [UserProfile.subscriptionTier] directly — see ADR-0041.
@Riverpod(keepAlive: true)
SubscriptionTier currentTier(Ref ref) {
  final auth = ref.watch(authCtrlProvider).valueOrNull;
  if (auth is! AuthSignedIn) {
    return SubscriptionTier.free;
  }
  final status = ref.watch(subscriptionStatusProvider).valueOrNull;
  if (status != null) {
    return status.subscriptionTier;
  }
  return auth.profile.subscriptionTier ?? SubscriptionTier.free;
}
