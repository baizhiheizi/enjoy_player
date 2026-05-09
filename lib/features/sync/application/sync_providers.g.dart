// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(syncQueueRepository)
final syncQueueRepositoryProvider = SyncQueueRepositoryProvider._();

final class SyncQueueRepositoryProvider
    extends
        $FunctionalProvider<
          SyncQueueRepository,
          SyncQueueRepository,
          SyncQueueRepository
        >
    with $Provider<SyncQueueRepository> {
  SyncQueueRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncQueueRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncQueueRepositoryHash();

  @$internal
  @override
  $ProviderElement<SyncQueueRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SyncQueueRepository create(Ref ref) {
    return syncQueueRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncQueueRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncQueueRepository>(value),
    );
  }
}

String _$syncQueueRepositoryHash() =>
    r'13004c01d63849f75b9590e23f906e1432377d69';

@ProviderFor(syncUploadService)
final syncUploadServiceProvider = SyncUploadServiceProvider._();

final class SyncUploadServiceProvider
    extends
        $FunctionalProvider<
          SyncUploadService,
          SyncUploadService,
          SyncUploadService
        >
    with $Provider<SyncUploadService> {
  SyncUploadServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncUploadServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncUploadServiceHash();

  @$internal
  @override
  $ProviderElement<SyncUploadService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SyncUploadService create(Ref ref) {
    return syncUploadService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncUploadService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncUploadService>(value),
    );
  }
}

String _$syncUploadServiceHash() => r'4563a2a90cddc3c92c292aafe68c4b943a72499b';

@ProviderFor(syncDownloadService)
final syncDownloadServiceProvider = SyncDownloadServiceProvider._();

final class SyncDownloadServiceProvider
    extends
        $FunctionalProvider<
          SyncDownloadService,
          SyncDownloadService,
          SyncDownloadService
        >
    with $Provider<SyncDownloadService> {
  SyncDownloadServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncDownloadServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncDownloadServiceHash();

  @$internal
  @override
  $ProviderElement<SyncDownloadService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SyncDownloadService create(Ref ref) {
    return syncDownloadService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncDownloadService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncDownloadService>(value),
    );
  }
}

String _$syncDownloadServiceHash() =>
    r'bd29b8afaa903812ebfc8fff44aed9608fff7751';

@ProviderFor(syncEngine)
final syncEngineProvider = SyncEngineProvider._();

final class SyncEngineProvider
    extends $FunctionalProvider<SyncEngine, SyncEngine, SyncEngine>
    with $Provider<SyncEngine> {
  SyncEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncEngineHash();

  @$internal
  @override
  $ProviderElement<SyncEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncEngine create(Ref ref) {
    return syncEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncEngine>(value),
    );
  }
}

String _$syncEngineHash() => r'70bd781209e364951120a0af7c86c112d5f02f24';

@ProviderFor(syncEnqueue)
final syncEnqueueProvider = SyncEnqueueProvider._();

final class SyncEnqueueProvider
    extends $FunctionalProvider<SyncEnqueueFn, SyncEnqueueFn, SyncEnqueueFn>
    with $Provider<SyncEnqueueFn> {
  SyncEnqueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncEnqueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncEnqueueHash();

  @$internal
  @override
  $ProviderElement<SyncEnqueueFn> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncEnqueueFn create(Ref ref) {
    return syncEnqueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncEnqueueFn value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncEnqueueFn>(value),
    );
  }
}

String _$syncEnqueueHash() => r'828d8bec4c564e653e7812646bba1b8ac4c0c0c8';
