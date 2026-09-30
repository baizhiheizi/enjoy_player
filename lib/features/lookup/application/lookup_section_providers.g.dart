// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lookup_section_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lookupSheetTranslation)
final lookupSheetTranslationProvider = LookupSheetTranslationFamily._();

final class LookupSheetTranslationProvider
    extends
        $FunctionalProvider<
          AsyncValue<TranslationResult>,
          TranslationResult,
          FutureOr<TranslationResult>
        >
    with
        $FutureModifier<TranslationResult>,
        $FutureProvider<TranslationResult> {
  LookupSheetTranslationProvider._({
    required LookupSheetTranslationFamily super.from,
    required (LookupTranslationParams, {bool forceRefresh}) super.argument,
  }) : super(
         retry: null,
         name: r'lookupSheetTranslationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lookupSheetTranslationHash();

  @override
  String toString() {
    return r'lookupSheetTranslationProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<TranslationResult> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TranslationResult> create(Ref ref) {
    final argument =
        this.argument as (LookupTranslationParams, {bool forceRefresh});
    return lookupSheetTranslation(
      ref,
      argument.$1,
      forceRefresh: argument.forceRefresh,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LookupSheetTranslationProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lookupSheetTranslationHash() =>
    r'f7621d025c4332b7e45e99b68d3fa29f711f7207';

final class LookupSheetTranslationFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<TranslationResult>,
          (LookupTranslationParams, {bool forceRefresh})
        > {
  LookupSheetTranslationFamily._()
    : super(
        retry: null,
        name: r'lookupSheetTranslationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LookupSheetTranslationProvider call(
    LookupTranslationParams params, {
    bool forceRefresh = false,
  }) => LookupSheetTranslationProvider._(
    argument: (params, forceRefresh: forceRefresh),
    from: this,
  );

  @override
  String toString() => r'lookupSheetTranslationProvider';
}

@ProviderFor(lookupSheetDictionary)
final lookupSheetDictionaryProvider = LookupSheetDictionaryFamily._();

final class LookupSheetDictionaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<DictionaryResult>,
          DictionaryResult,
          FutureOr<DictionaryResult>
        >
    with $FutureModifier<DictionaryResult>, $FutureProvider<DictionaryResult> {
  LookupSheetDictionaryProvider._({
    required LookupSheetDictionaryFamily super.from,
    required (LookupDictionaryParams, {bool forceRefresh}) super.argument,
  }) : super(
         retry: null,
         name: r'lookupSheetDictionaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lookupSheetDictionaryHash();

  @override
  String toString() {
    return r'lookupSheetDictionaryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<DictionaryResult> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DictionaryResult> create(Ref ref) {
    final argument =
        this.argument as (LookupDictionaryParams, {bool forceRefresh});
    return lookupSheetDictionary(
      ref,
      argument.$1,
      forceRefresh: argument.forceRefresh,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LookupSheetDictionaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lookupSheetDictionaryHash() =>
    r'8e58b38ff1c108e3d8d3766e6033d2713e3c78c3';

final class LookupSheetDictionaryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<DictionaryResult>,
          (LookupDictionaryParams, {bool forceRefresh})
        > {
  LookupSheetDictionaryFamily._()
    : super(
        retry: null,
        name: r'lookupSheetDictionaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LookupSheetDictionaryProvider call(
    LookupDictionaryParams params, {
    bool forceRefresh = false,
  }) => LookupSheetDictionaryProvider._(
    argument: (params, forceRefresh: forceRefresh),
    from: this,
  );

  @override
  String toString() => r'lookupSheetDictionaryProvider';
}
