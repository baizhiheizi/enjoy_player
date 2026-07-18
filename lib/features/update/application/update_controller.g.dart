// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UpdateCtrl)
final updateCtrlProvider = UpdateCtrlProvider._();

final class UpdateCtrlProvider
    extends $NotifierProvider<UpdateCtrl, UpdateCheckResult?> {
  UpdateCtrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateCtrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateCtrlHash();

  @$internal
  @override
  UpdateCtrl create() => UpdateCtrl();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateCheckResult? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateCheckResult?>(value),
    );
  }
}

String _$updateCtrlHash() => r'b2cfb9e6ea41c35a90b0f1be0d488f6a0d7d8cbd';

abstract class _$UpdateCtrl extends $Notifier<UpdateCheckResult?> {
  UpdateCheckResult? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UpdateCheckResult?, UpdateCheckResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UpdateCheckResult?, UpdateCheckResult?>,
              UpdateCheckResult?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
