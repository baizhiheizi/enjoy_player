// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_translate_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AutoTranslateCtrl)
final autoTranslateCtrlProvider = AutoTranslateCtrlFamily._();

final class AutoTranslateCtrlProvider
    extends $NotifierProvider<AutoTranslateCtrl, AutoTranslateUiState> {
  AutoTranslateCtrlProvider._({
    required AutoTranslateCtrlFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'autoTranslateCtrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$autoTranslateCtrlHash();

  @override
  String toString() {
    return r'autoTranslateCtrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AutoTranslateCtrl create() => AutoTranslateCtrl();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutoTranslateUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutoTranslateUiState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AutoTranslateCtrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$autoTranslateCtrlHash() => r'080e018c7fc10514b1d11c675642d8d8691ebb32';

final class AutoTranslateCtrlFamily extends $Family
    with
        $ClassFamilyOverride<
          AutoTranslateCtrl,
          AutoTranslateUiState,
          AutoTranslateUiState,
          AutoTranslateUiState,
          String
        > {
  AutoTranslateCtrlFamily._()
    : super(
        retry: null,
        name: r'autoTranslateCtrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AutoTranslateCtrlProvider call(String mediaId) =>
      AutoTranslateCtrlProvider._(argument: mediaId, from: this);

  @override
  String toString() => r'autoTranslateCtrlProvider';
}

abstract class _$AutoTranslateCtrl extends $Notifier<AutoTranslateUiState> {
  late final _$args = ref.$arg as String;
  String get mediaId => _$args;

  AutoTranslateUiState build(String mediaId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AutoTranslateUiState, AutoTranslateUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AutoTranslateUiState, AutoTranslateUiState>,
              AutoTranslateUiState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
