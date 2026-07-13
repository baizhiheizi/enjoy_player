// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lookup_sheet_result_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lookupSheetResultCache)
final lookupSheetResultCacheProvider = LookupSheetResultCacheProvider._();

final class LookupSheetResultCacheProvider
    extends
        $FunctionalProvider<
          LookupSheetResultCache,
          LookupSheetResultCache,
          LookupSheetResultCache
        >
    with $Provider<LookupSheetResultCache> {
  LookupSheetResultCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lookupSheetResultCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lookupSheetResultCacheHash();

  @$internal
  @override
  $ProviderElement<LookupSheetResultCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LookupSheetResultCache create(Ref ref) {
    return lookupSheetResultCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LookupSheetResultCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LookupSheetResultCache>(value),
    );
  }
}

String _$lookupSheetResultCacheHash() =>
    r'db3858707eac2bec289bc17f4d4e3d3f757d5031';
