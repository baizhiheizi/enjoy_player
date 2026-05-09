// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mediaLibraryRepository)
final mediaLibraryRepositoryProvider = MediaLibraryRepositoryProvider._();

final class MediaLibraryRepositoryProvider
    extends
        $FunctionalProvider<
          MediaLibraryRepository,
          MediaLibraryRepository,
          MediaLibraryRepository
        >
    with $Provider<MediaLibraryRepository> {
  MediaLibraryRepositoryProvider._()
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
    r'ca0e4abf58a860e0b67ea0c8e00ae4837f40638e';
