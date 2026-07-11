// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_tier_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The current subscription tier, as a single synchronous source of truth.
///
/// Prefers the live [subscriptionStatusProvider] (authoritative server status);
/// falls back to the cached [UserProfile.subscriptionTier] carried by
/// [authCtrlProvider] so UI can render instantly on cold start before the
/// status fetch resolves. When signed out, resolves to [SubscriptionTier.free].
///
/// All tier indicators (sidebar chip, profile hero card) must read this
/// provider rather than [UserProfile.subscriptionTier] directly — see ADR-0041.

@ProviderFor(currentTier)
final currentTierProvider = CurrentTierProvider._();

/// The current subscription tier, as a single synchronous source of truth.
///
/// Prefers the live [subscriptionStatusProvider] (authoritative server status);
/// falls back to the cached [UserProfile.subscriptionTier] carried by
/// [authCtrlProvider] so UI can render instantly on cold start before the
/// status fetch resolves. When signed out, resolves to [SubscriptionTier.free].
///
/// All tier indicators (sidebar chip, profile hero card) must read this
/// provider rather than [UserProfile.subscriptionTier] directly — see ADR-0041.

final class CurrentTierProvider
    extends
        $FunctionalProvider<
          SubscriptionTier,
          SubscriptionTier,
          SubscriptionTier
        >
    with $Provider<SubscriptionTier> {
  /// The current subscription tier, as a single synchronous source of truth.
  ///
  /// Prefers the live [subscriptionStatusProvider] (authoritative server status);
  /// falls back to the cached [UserProfile.subscriptionTier] carried by
  /// [authCtrlProvider] so UI can render instantly on cold start before the
  /// status fetch resolves. When signed out, resolves to [SubscriptionTier.free].
  ///
  /// All tier indicators (sidebar chip, profile hero card) must read this
  /// provider rather than [UserProfile.subscriptionTier] directly — see ADR-0041.
  CurrentTierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentTierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentTierHash();

  @$internal
  @override
  $ProviderElement<SubscriptionTier> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SubscriptionTier create(Ref ref) {
    return currentTier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubscriptionTier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubscriptionTier>(value),
    );
  }
}

String _$currentTierHash() => r'05ccc53234155b3301ec4ae0a6133e7781d5d1b2';
