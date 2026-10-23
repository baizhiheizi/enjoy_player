// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'byok_secret_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(byokSecretStore)
final byokSecretStoreProvider = ByokSecretStoreProvider._();

final class ByokSecretStoreProvider
    extends
        $FunctionalProvider<
          ByokSecretStoreBase,
          ByokSecretStoreBase,
          ByokSecretStoreBase
        >
    with $Provider<ByokSecretStoreBase> {
  ByokSecretStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'byokSecretStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$byokSecretStoreHash();

  @$internal
  @override
  $ProviderElement<ByokSecretStoreBase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ByokSecretStoreBase create(Ref ref) {
    return byokSecretStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ByokSecretStoreBase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ByokSecretStoreBase>(value),
    );
  }
}

String _$byokSecretStoreHash() => r'2c4dedbc691e11a4b30ce302843495c7175de1af';
