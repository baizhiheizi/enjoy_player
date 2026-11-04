// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(systemProxyCoordinator)
final systemProxyCoordinatorProvider = SystemProxyCoordinatorProvider._();

final class SystemProxyCoordinatorProvider
    extends
        $FunctionalProvider<
          SystemProxyCoordinator,
          SystemProxyCoordinator,
          SystemProxyCoordinator
        >
    with $Provider<SystemProxyCoordinator> {
  SystemProxyCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'systemProxyCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$systemProxyCoordinatorHash();

  @$internal
  @override
  $ProviderElement<SystemProxyCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SystemProxyCoordinator create(Ref ref) {
    return systemProxyCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SystemProxyCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SystemProxyCoordinator>(value),
    );
  }
}

String _$systemProxyCoordinatorHash() =>
    r'474f8e75d9652a3074e6ba1cdc9ad79ebe20c1bd';

@ProviderFor(NetworkProxySettings)
final networkProxySettingsProvider = NetworkProxySettingsProvider._();

final class NetworkProxySettingsProvider
    extends $AsyncNotifierProvider<NetworkProxySettings, ProxyConfig> {
  NetworkProxySettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkProxySettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkProxySettingsHash();

  @$internal
  @override
  NetworkProxySettings create() => NetworkProxySettings();
}

String _$networkProxySettingsHash() =>
    r'6ffc79a7923fc2e29b9b319b2729592424c1ff45';

abstract class _$NetworkProxySettings extends $AsyncNotifier<ProxyConfig> {
  FutureOr<ProxyConfig> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ProxyConfig>, ProxyConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ProxyConfig>, ProxyConfig>,
              AsyncValue<ProxyConfig>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
