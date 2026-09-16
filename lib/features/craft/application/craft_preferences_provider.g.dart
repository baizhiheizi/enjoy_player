// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'craft_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CraftPreferencesCtrl)
final craftPreferencesCtrlProvider = CraftPreferencesCtrlProvider._();

final class CraftPreferencesCtrlProvider
    extends $NotifierProvider<CraftPreferencesCtrl, CraftPreferences> {
  CraftPreferencesCtrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'craftPreferencesCtrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$craftPreferencesCtrlHash();

  @$internal
  @override
  CraftPreferencesCtrl create() => CraftPreferencesCtrl();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CraftPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CraftPreferences>(value),
    );
  }
}

String _$craftPreferencesCtrlHash() =>
    r'2d9c596a5702bd182e4d74fea14bf52dddd7336f';

abstract class _$CraftPreferencesCtrl extends $Notifier<CraftPreferences> {
  CraftPreferences build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CraftPreferences, CraftPreferences>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CraftPreferences, CraftPreferences>,
              CraftPreferences,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
