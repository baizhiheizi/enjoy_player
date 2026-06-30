// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(subscriptionStatus)
final subscriptionStatusProvider = SubscriptionStatusProvider._();

final class SubscriptionStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<SubscriptionStatus>,
          SubscriptionStatus,
          FutureOr<SubscriptionStatus>
        >
    with
        $FutureModifier<SubscriptionStatus>,
        $FutureProvider<SubscriptionStatus> {
  SubscriptionStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionStatusHash();

  @$internal
  @override
  $FutureProviderElement<SubscriptionStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SubscriptionStatus> create(Ref ref) {
    return subscriptionStatus(ref);
  }
}

String _$subscriptionStatusHash() =>
    r'562f2c2bddc0e1de00a31fa830e023d5e5f6736b';
