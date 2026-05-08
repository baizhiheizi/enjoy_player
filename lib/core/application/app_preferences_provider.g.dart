// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppPreferencesCtrl)
final appPreferencesCtrlProvider = AppPreferencesCtrlProvider._();

final class AppPreferencesCtrlProvider
    extends $AsyncNotifierProvider<AppPreferencesCtrl, AppPreferencesState> {
  AppPreferencesCtrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appPreferencesCtrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appPreferencesCtrlHash();

  @$internal
  @override
  AppPreferencesCtrl create() => AppPreferencesCtrl();
}

String _$appPreferencesCtrlHash() =>
    r'04134847c76d86cfb87f7ce79a6106483c18f563';

abstract class _$AppPreferencesCtrl
    extends $AsyncNotifier<AppPreferencesState> {
  FutureOr<AppPreferencesState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AppPreferencesState>, AppPreferencesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppPreferencesState>, AppPreferencesState>,
              AsyncValue<AppPreferencesState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
