// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_interactions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlayerInteractions)
final playerInteractionsProvider = PlayerInteractionsProvider._();

final class PlayerInteractionsProvider
    extends $NotifierProvider<PlayerInteractions, int> {
  PlayerInteractionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerInteractionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerInteractionsHash();

  @$internal
  @override
  PlayerInteractions create() => PlayerInteractions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$playerInteractionsHash() =>
    r'91538e94d5b02ebed9e3f1d353f56ce1f467f3ec';

abstract class _$PlayerInteractions extends $Notifier<int> {
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
