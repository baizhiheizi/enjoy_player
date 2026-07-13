// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_result_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-user `AiMapCache` (JSON-typed payload). Cleared on sign-out /
/// user-id change.
///
/// The cache is `keepAlive` because lookup-sheet and contextual-translation
/// flows outlive any single widget mount; closing the sheet must not
/// invalidate the cache.

@ProviderFor(aiResultCache)
final aiResultCacheProvider = AiResultCacheProvider._();

/// Per-user `AiMapCache` (JSON-typed payload). Cleared on sign-out /
/// user-id change.
///
/// The cache is `keepAlive` because lookup-sheet and contextual-translation
/// flows outlive any single widget mount; closing the sheet must not
/// invalidate the cache.

final class AiResultCacheProvider
    extends $FunctionalProvider<AiMapCache, AiMapCache, AiMapCache>
    with $Provider<AiMapCache> {
  /// Per-user `AiMapCache` (JSON-typed payload). Cleared on sign-out /
  /// user-id change.
  ///
  /// The cache is `keepAlive` because lookup-sheet and contextual-translation
  /// flows outlive any single widget mount; closing the sheet must not
  /// invalidate the cache.
  AiResultCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiResultCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiResultCacheHash();

  @$internal
  @override
  $ProviderElement<AiMapCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AiMapCache create(Ref ref) {
    return aiResultCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiMapCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiMapCache>(value),
    );
  }
}

String _$aiResultCacheHash() => r'1174c0e7699ae9017884ae7d4a602658ccc30ac1';

/// Per-user `AiTranslationCache` (typed `TranslationResult`). Shares the
/// L2 Drift table with `aiResultCache` (different `AiKind.wire`).

@ProviderFor(aiTranslationCache)
final aiTranslationCacheProvider = AiTranslationCacheProvider._();

/// Per-user `AiTranslationCache` (typed `TranslationResult`). Shares the
/// L2 Drift table with `aiResultCache` (different `AiKind.wire`).

final class AiTranslationCacheProvider
    extends
        $FunctionalProvider<
          AiTranslationCache,
          AiTranslationCache,
          AiTranslationCache
        >
    with $Provider<AiTranslationCache> {
  /// Per-user `AiTranslationCache` (typed `TranslationResult`). Shares the
  /// L2 Drift table with `aiResultCache` (different `AiKind.wire`).
  AiTranslationCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiTranslationCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiTranslationCacheHash();

  @$internal
  @override
  $ProviderElement<AiTranslationCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AiTranslationCache create(Ref ref) {
    return aiTranslationCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiTranslationCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiTranslationCache>(value),
    );
  }
}

String _$aiTranslationCacheHash() =>
    r'2d0c04ebd0e3399a66fecf1b0ca485f84fd39ffe';

/// Per-user `AiDictionaryCache`.

@ProviderFor(aiDictionaryCache)
final aiDictionaryCacheProvider = AiDictionaryCacheProvider._();

/// Per-user `AiDictionaryCache`.

final class AiDictionaryCacheProvider
    extends
        $FunctionalProvider<
          AiDictionaryCache,
          AiDictionaryCache,
          AiDictionaryCache
        >
    with $Provider<AiDictionaryCache> {
  /// Per-user `AiDictionaryCache`.
  AiDictionaryCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiDictionaryCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiDictionaryCacheHash();

  @$internal
  @override
  $ProviderElement<AiDictionaryCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AiDictionaryCache create(Ref ref) {
    return aiDictionaryCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiDictionaryCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiDictionaryCache>(value),
    );
  }
}

String _$aiDictionaryCacheHash() => r'217497e734742cd533a39726ebbe94371710e782';

/// Per-user `AiContextualTranslationCache`.

@ProviderFor(aiContextualTranslationCache)
final aiContextualTranslationCacheProvider =
    AiContextualTranslationCacheProvider._();

/// Per-user `AiContextualTranslationCache`.

final class AiContextualTranslationCacheProvider
    extends
        $FunctionalProvider<
          AiContextualTranslationCache,
          AiContextualTranslationCache,
          AiContextualTranslationCache
        >
    with $Provider<AiContextualTranslationCache> {
  /// Per-user `AiContextualTranslationCache`.
  AiContextualTranslationCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiContextualTranslationCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiContextualTranslationCacheHash();

  @$internal
  @override
  $ProviderElement<AiContextualTranslationCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AiContextualTranslationCache create(Ref ref) {
    return aiContextualTranslationCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiContextualTranslationCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiContextualTranslationCache>(value),
    );
  }
}

String _$aiContextualTranslationCacheHash() =>
    r'4718d09d436cc5c94da273658fbcec3f1ae9d5dc';
