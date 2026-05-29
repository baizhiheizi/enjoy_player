// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(versionManifestRepository)
final versionManifestRepositoryProvider = VersionManifestRepositoryProvider._();

final class VersionManifestRepositoryProvider
    extends
        $FunctionalProvider<
          VersionManifestRepository,
          VersionManifestRepository,
          VersionManifestRepository
        >
    with $Provider<VersionManifestRepository> {
  VersionManifestRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'versionManifestRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$versionManifestRepositoryHash();

  @$internal
  @override
  $ProviderElement<VersionManifestRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VersionManifestRepository create(Ref ref) {
    return versionManifestRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VersionManifestRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VersionManifestRepository>(value),
    );
  }
}

String _$versionManifestRepositoryHash() =>
    r'6c07e36fb2b6d21686f796ca1d5f832c710b2cbb';

@ProviderFor(updateStrategy)
final updateStrategyProvider = UpdateStrategyProvider._();

final class UpdateStrategyProvider
    extends $FunctionalProvider<UpdateStrategy, UpdateStrategy, UpdateStrategy>
    with $Provider<UpdateStrategy> {
  UpdateStrategyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateStrategyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateStrategyHash();

  @$internal
  @override
  $ProviderElement<UpdateStrategy> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UpdateStrategy create(Ref ref) {
    return updateStrategy(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateStrategy value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateStrategy>(value),
    );
  }
}

String _$updateStrategyHash() => r'd661a72aaf841f70705627e3c30e84631815883b';
