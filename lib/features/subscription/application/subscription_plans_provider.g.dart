// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_plans_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(subscriptionPlans)
final subscriptionPlansProvider = SubscriptionPlansProvider._();

final class SubscriptionPlansProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SubscriptionPlan>>,
          List<SubscriptionPlan>,
          FutureOr<List<SubscriptionPlan>>
        >
    with
        $FutureModifier<List<SubscriptionPlan>>,
        $FutureProvider<List<SubscriptionPlan>> {
  SubscriptionPlansProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionPlansProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionPlansHash();

  @$internal
  @override
  $FutureProviderElement<List<SubscriptionPlan>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SubscriptionPlan>> create(Ref ref) {
    return subscriptionPlans(ref);
  }
}

String _$subscriptionPlansHash() => r'0cf8752cf814eb621000141a5df3e928d6db3a30';
