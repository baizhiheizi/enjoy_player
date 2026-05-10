// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SyncCtrl)
final syncCtrlProvider = SyncCtrlProvider._();

final class SyncCtrlProvider extends $NotifierProvider<SyncCtrl, int> {
  SyncCtrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncCtrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncCtrlHash();

  @$internal
  @override
  SyncCtrl create() => SyncCtrl();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$syncCtrlHash() => r'538e56bd71b93923a836c2005ce2fa74fd4da10d';

abstract class _$SyncCtrl extends $Notifier<int> {
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
