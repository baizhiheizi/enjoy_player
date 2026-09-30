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
    r'28c63b22e9a196751f26dfea0a4d4725d9914f44';

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

/// Distinct, sorted languages across all items for the word-list filter
/// menu (issue #827 C2). Re-runs on every `vocabularyItemsProvider`
/// emission — each emission carries a fresh list — and the result is
/// cached between emissions, so word-list rebuilds that are unrelated to
/// the items (filter toggles, keystroke setStates) stop re-deriving it.

@ProviderFor(vocabularyListLanguages)
final vocabularyListLanguagesProvider = VocabularyListLanguagesProvider._();

/// Distinct, sorted languages across all items for the word-list filter
/// menu (issue #827 C2). Re-runs on every `vocabularyItemsProvider`
/// emission — each emission carries a fresh list — and the result is
/// cached between emissions, so word-list rebuilds that are unrelated to
/// the items (filter toggles, keystroke setStates) stop re-deriving it.

final class VocabularyListLanguagesProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// Distinct, sorted languages across all items for the word-list filter
  /// menu (issue #827 C2). Re-runs on every `vocabularyItemsProvider`
  /// emission — each emission carries a fresh list — and the result is
  /// cached between emissions, so word-list rebuilds that are unrelated to
  /// the items (filter toggles, keystroke setStates) stop re-deriving it.
  VocabularyListLanguagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vocabularyListLanguagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vocabularyListLanguagesHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return vocabularyListLanguages(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$vocabularyListLanguagesHash() =>
    r'8f70907c83f28d3957801bf5c5c34414a1770fd2';

/// [filterVocabularyItems] keyed on `(items, filters)` (issue #827 C2) —
/// the word list watches this instead of re-filtering inside `build` on
/// every rebuild. Re-runs when the items stream emits or the filters
/// change; cached otherwise.

@ProviderFor(vocabularyVisibleItems)
final vocabularyVisibleItemsProvider = VocabularyVisibleItemsProvider._();

/// [filterVocabularyItems] keyed on `(items, filters)` (issue #827 C2) —
/// the word list watches this instead of re-filtering inside `build` on
/// every rebuild. Re-runs when the items stream emits or the filters
/// change; cached otherwise.

final class VocabularyVisibleItemsProvider
    extends
        $FunctionalProvider<
          List<VocabularyItem>,
          List<VocabularyItem>,
          List<VocabularyItem>
        >
    with $Provider<List<VocabularyItem>> {
  /// [filterVocabularyItems] keyed on `(items, filters)` (issue #827 C2) —
  /// the word list watches this instead of re-filtering inside `build` on
  /// every rebuild. Re-runs when the items stream emits or the filters
  /// change; cached otherwise.
  VocabularyVisibleItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vocabularyVisibleItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vocabularyVisibleItemsHash();

  @$internal
  @override
  $ProviderElement<List<VocabularyItem>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<VocabularyItem> create(Ref ref) {
    return vocabularyVisibleItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<VocabularyItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<VocabularyItem>>(value),
    );
  }
}

String _$vocabularyVisibleItemsHash() =>
    r'2953423e75ca2264871b9b5def1945eb1fdfdb34';
