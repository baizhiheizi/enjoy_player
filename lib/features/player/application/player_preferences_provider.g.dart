// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlayerPreferencesCtrl)
final playerPreferencesCtrlProvider = PlayerPreferencesCtrlProvider._();

final class PlayerPreferencesCtrlProvider
    extends $NotifierProvider<PlayerPreferencesCtrl, PlayerPreferences> {
  PlayerPreferencesCtrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerPreferencesCtrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerPreferencesCtrlHash();

  @$internal
  @override
  PlayerPreferencesCtrl create() => PlayerPreferencesCtrl();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayerPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayerPreferences>(value),
    );
  }
}

String _$playerPreferencesCtrlHash() =>
    r'bd03612b37884e0423acaead3b5eb4fb034059b4';

abstract class _$PlayerPreferencesCtrl extends $Notifier<PlayerPreferences> {
  PlayerPreferences build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PlayerPreferences, PlayerPreferences>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlayerPreferences, PlayerPreferences>,
              PlayerPreferences,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
