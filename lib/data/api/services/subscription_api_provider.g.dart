// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(subscriptionApi)
final subscriptionApiProvider = SubscriptionApiProvider._();

final class SubscriptionApiProvider
    extends
        $FunctionalProvider<SubscriptionApi, SubscriptionApi, SubscriptionApi>
    with $Provider<SubscriptionApi> {
  SubscriptionApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionApiHash();

  @$internal
  @override
  $ProviderElement<SubscriptionApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SubscriptionApi create(Ref ref) {
    return subscriptionApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubscriptionApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubscriptionApi>(value),
    );
  }
}

String _$subscriptionApiHash() => r'f13e57ad6a92124daf21720f3ba0a3fcc01507ba';
