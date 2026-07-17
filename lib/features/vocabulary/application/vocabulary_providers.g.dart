// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocabulary_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(vocabularyRepository)
final vocabularyRepositoryProvider = VocabularyRepositoryProvider._();

final class VocabularyRepositoryProvider
    extends
        $FunctionalProvider<
          VocabularyRepository,
          VocabularyRepository,
          VocabularyRepository
        >
    with $Provider<VocabularyRepository> {
  VocabularyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vocabularyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vocabularyRepositoryHash();

  @$internal
  @override
  $ProviderElement<VocabularyRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VocabularyRepository create(Ref ref) {
    return vocabularyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VocabularyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VocabularyRepository>(value),
    );
  }
}

String _$vocabularyRepositoryHash() =>
    r'f1ddf4bf145fc20973431e70951417146d9d4524';

/// Live list of all vocabulary items (updates after add/rate/delete).

@ProviderFor(vocabularyItems)
final vocabularyItemsProvider = VocabularyItemsProvider._();

/// Live list of all vocabulary items (updates after add/rate/delete).

final class VocabularyItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<VocabularyItem>>,
          List<VocabularyItem>,
          Stream<List<VocabularyItem>>
        >
    with
        $FutureModifier<List<VocabularyItem>>,
        $StreamProvider<List<VocabularyItem>> {
  /// Live list of all vocabulary items (updates after add/rate/delete).
  VocabularyItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vocabularyItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vocabularyItemsHash();

  @$internal
  @override
  $StreamProviderElement<List<VocabularyItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<VocabularyItem>> create(Ref ref) {
    return vocabularyItems(ref);
  }
}

String _$vocabularyItemsHash() => r'4e8749ff97524c47021992f223058d8dce9c0d29';

/// Aggregated stats for the Vocabulary stats strip.

@ProviderFor(vocabularyStats)
final vocabularyStatsProvider = VocabularyStatsProvider._();

/// Aggregated stats for the Vocabulary stats strip.

final class VocabularyStatsProvider
    extends
        $FunctionalProvider<VocabularyStats, VocabularyStats, VocabularyStats>
    with $Provider<VocabularyStats> {
  /// Aggregated stats for the Vocabulary stats strip.
  VocabularyStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vocabularyStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vocabularyStatsHash();

  @$internal
  @override
  $ProviderElement<VocabularyStats> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VocabularyStats create(Ref ref) {
    return vocabularyStats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VocabularyStats value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VocabularyStats>(value),
    );
  }
}

String _$vocabularyStatsHash() => r'7b0c923f7ddb6109fbe85d182e7f6820960c37e0';
