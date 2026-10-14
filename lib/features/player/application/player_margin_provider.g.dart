// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_margin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlayerMargin)
final playerMarginProvider = PlayerMarginProvider._();

final class PlayerMarginProvider
    extends $NotifierProvider<PlayerMargin, PlayerMarginEntry?> {
  PlayerMarginProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerMarginProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerMarginHash();

  @$internal
  @override
  PlayerMargin create() => PlayerMargin();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayerMarginEntry? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayerMarginEntry?>(value),
    );
  }
}

String _$playerMarginHash() => r'8f39239cb7f38779f7fd904f16791597a94fe823';

abstract class _$PlayerMargin extends $Notifier<PlayerMarginEntry?> {
  PlayerMarginEntry? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlayerMarginEntry?, PlayerMarginEntry?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlayerMarginEntry?, PlayerMarginEntry?>,
              PlayerMarginEntry?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
