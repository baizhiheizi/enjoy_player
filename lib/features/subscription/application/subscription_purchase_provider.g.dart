// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_purchase_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SubscriptionPurchaseCtrl)
final subscriptionPurchaseCtrlProvider = SubscriptionPurchaseCtrlProvider._();

final class SubscriptionPurchaseCtrlProvider
    extends $NotifierProvider<SubscriptionPurchaseCtrl, AsyncValue<void>> {
  SubscriptionPurchaseCtrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionPurchaseCtrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionPurchaseCtrlHash();

  @$internal
  @override
  SubscriptionPurchaseCtrl create() => SubscriptionPurchaseCtrl();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$subscriptionPurchaseCtrlHash() =>
    r'c62f4971e7e7e71e60ebd8755f580e23ce282375';

abstract class _$SubscriptionPurchaseCtrl extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
