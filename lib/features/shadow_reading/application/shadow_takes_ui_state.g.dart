// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shadow_takes_ui_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The selected take's id; null means "the latest take".

@ProviderFor(SelectedTake)
final selectedTakeProvider = SelectedTakeProvider._();

/// The selected take's id; null means "the latest take".
final class SelectedTakeProvider
    extends $NotifierProvider<SelectedTake, String?> {
  /// The selected take's id; null means "the latest take".
  SelectedTakeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedTakeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedTakeHash();

  @$internal
  @override
  SelectedTake create() => SelectedTake();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedTakeHash() => r'e0d915821c2193c2e31d632034e0681869de026b';

/// The selected take's id; null means "the latest take".

abstract class _$SelectedTake extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(LoopPitchVisible)
final loopPitchVisibleProvider = LoopPitchVisibleProvider._();

final class LoopPitchVisibleProvider
    extends $NotifierProvider<LoopPitchVisible, bool> {
  LoopPitchVisibleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loopPitchVisibleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loopPitchVisibleHash();

  @$internal
  @override
  LoopPitchVisible create() => LoopPitchVisible();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$loopPitchVisibleHash() => r'992f88d83e1e6f3029f18b24bff84a66cce91db9';

abstract class _$LoopPitchVisible extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
