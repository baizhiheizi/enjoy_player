// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_lens_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(playerLens)
final playerLensProvider = PlayerLensProvider._();

final class PlayerLensProvider
    extends $FunctionalProvider<PlayerLens, PlayerLens, PlayerLens>
    with $Provider<PlayerLens> {
  PlayerLensProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerLensProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerLensHash();

  @$internal
  @override
  $ProviderElement<PlayerLens> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlayerLens create(Ref ref) {
    return playerLens(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayerLens value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayerLens>(value),
    );
  }
}

String _$playerLensHash() => r'197cdcca7800c50bc318c09bf55865b9a8d291bb';
