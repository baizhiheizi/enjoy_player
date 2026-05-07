// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mediaLibraryRepository)
const mediaLibraryRepositoryProvider = MediaLibraryRepositoryProvider._();

final class MediaLibraryRepositoryProvider
    extends
        $FunctionalProvider<
          MediaLibraryRepository,
          MediaLibraryRepository,
          MediaLibraryRepository
        >
    with $Provider<MediaLibraryRepository> {
  const MediaLibraryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaLibraryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaLibraryRepositoryHash();

  @$internal
  @override
  $ProviderElement<MediaLibraryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MediaLibraryRepository create(Ref ref) {
    return mediaLibraryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaLibraryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaLibraryRepository>(value),
    );
  }
}

String _$mediaLibraryRepositoryHash() =>
    r'65c7ee03e0dfcef7ee1906265149753a41f5a578';
