// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hotkeys_ctrl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HotkeysCtrl)
final hotkeysCtrlProvider = HotkeysCtrlProvider._();

final class HotkeysCtrlProvider
    extends $AsyncNotifierProvider<HotkeysCtrl, Map<String, String>> {
  HotkeysCtrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hotkeysCtrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hotkeysCtrlHash();

  @$internal
  @override
  HotkeysCtrl create() => HotkeysCtrl();
}

String _$hotkeysCtrlHash() => r'e08884e4036665111cb094b95d04ad9fb57feb97';

abstract class _$HotkeysCtrl extends $AsyncNotifier<Map<String, String>> {
  FutureOr<Map<String, String>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Map<String, String>>, Map<String, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Map<String, String>>, Map<String, String>>,
              AsyncValue<Map<String, String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
