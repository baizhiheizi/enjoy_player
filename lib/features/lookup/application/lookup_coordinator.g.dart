// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lookup_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LookupCoordinator)
final lookupCoordinatorProvider = LookupCoordinatorProvider._();

final class LookupCoordinatorProvider
    extends $NotifierProvider<LookupCoordinator, int> {
  LookupCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lookupCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lookupCoordinatorHash();

  @$internal
  @override
  LookupCoordinator create() => LookupCoordinator();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$lookupCoordinatorHash() => r'3931316ebb4671ad86af2c8d687eea43dda5ee92';

abstract class _$LookupCoordinator extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
