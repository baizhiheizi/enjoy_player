// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_translate_selection_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether [secondaryId] is the auto-translate AI track for [mediaId].

@ProviderFor(isAutoTranslateSecondary)
final isAutoTranslateSecondaryProvider = IsAutoTranslateSecondaryFamily._();

/// Whether [secondaryId] is the auto-translate AI track for [mediaId].

final class IsAutoTranslateSecondaryProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether [secondaryId] is the auto-translate AI track for [mediaId].
  IsAutoTranslateSecondaryProvider._({
    required IsAutoTranslateSecondaryFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'isAutoTranslateSecondaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isAutoTranslateSecondaryHash();

  @override
  String toString() {
    return r'isAutoTranslateSecondaryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as (String, String?);
    return isAutoTranslateSecondary(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is IsAutoTranslateSecondaryProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isAutoTranslateSecondaryHash() =>
    r'b30ac8a0be47960d06c5b4ff1b767e7f1bf64038';

/// Whether [secondaryId] is the auto-translate AI track for [mediaId].

final class IsAutoTranslateSecondaryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, (String, String?)> {
  IsAutoTranslateSecondaryFamily._()
    : super(
        retry: null,
        name: r'isAutoTranslateSecondaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether [secondaryId] is the auto-translate AI track for [mediaId].

  IsAutoTranslateSecondaryProvider call(String mediaId, String? secondaryId) =>
      IsAutoTranslateSecondaryProvider._(
        argument: (mediaId, secondaryId),
        from: this,
      );

  @override
  String toString() => r'isAutoTranslateSecondaryProvider';
}

/// Predicted AI track id for picker radio value (may not exist in DB yet).

@ProviderFor(autoTranslateSelectionId)
final autoTranslateSelectionIdProvider = AutoTranslateSelectionIdFamily._();

/// Predicted AI track id for picker radio value (may not exist in DB yet).

final class AutoTranslateSelectionIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Predicted AI track id for picker radio value (may not exist in DB yet).
  AutoTranslateSelectionIdProvider._({
    required AutoTranslateSelectionIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'autoTranslateSelectionIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$autoTranslateSelectionIdHash();

  @override
  String toString() {
    return r'autoTranslateSelectionIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return autoTranslateSelectionId(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AutoTranslateSelectionIdProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$autoTranslateSelectionIdHash() =>
    r'02d72757d828d04a8b4d9e234e384e115765f169';

/// Predicted AI track id for picker radio value (may not exist in DB yet).

final class AutoTranslateSelectionIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  AutoTranslateSelectionIdFamily._()
    : super(
        retry: null,
        name: r'autoTranslateSelectionIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Predicted AI track id for picker radio value (may not exist in DB yet).

  AutoTranslateSelectionIdProvider call(String mediaId) =>
      AutoTranslateSelectionIdProvider._(argument: mediaId, from: this);

  @override
  String toString() => r'autoTranslateSelectionIdProvider';
}
