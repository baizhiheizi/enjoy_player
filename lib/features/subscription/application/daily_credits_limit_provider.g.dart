// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_credits_limit_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The active daily credits limit: the live [SubscriptionStatus] value when
/// resolved, otherwise the tier table for the [currentTierProvider] tier.
///
/// Every meter / chip / usage surface reads this provider rather than
/// re-deriving `status?.dailyCreditsLimit ?? dailyCreditsLimitForTier(tier)`.

@ProviderFor(dailyCreditsLimit)
final dailyCreditsLimitProvider = DailyCreditsLimitProvider._();

/// The active daily credits limit: the live [SubscriptionStatus] value when
/// resolved, otherwise the tier table for the [currentTierProvider] tier.
///
/// Every meter / chip / usage surface reads this provider rather than
/// re-deriving `status?.dailyCreditsLimit ?? dailyCreditsLimitForTier(tier)`.

final class DailyCreditsLimitProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// The active daily credits limit: the live [SubscriptionStatus] value when
  /// resolved, otherwise the tier table for the [currentTierProvider] tier.
  ///
  /// Every meter / chip / usage surface reads this provider rather than
  /// re-deriving `status?.dailyCreditsLimit ?? dailyCreditsLimitForTier(tier)`.
  DailyCreditsLimitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyCreditsLimitProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyCreditsLimitHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return dailyCreditsLimit(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$dailyCreditsLimitHash() => r'18e72be7c6ccfb263a431403fdba41c9a66ef750';
