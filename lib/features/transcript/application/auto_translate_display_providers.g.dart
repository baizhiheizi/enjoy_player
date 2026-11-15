// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_translate_display_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the auto-translate AI track is the live secondary for [mediaId],
/// plus the source → target pair its lines render with — the derivation both
/// transcript hosts (the echo merged card and the scrollable list) previously
/// re-spelled field by field.

@ProviderFor(autoTranslateDisplayState)
final autoTranslateDisplayStateProvider = AutoTranslateDisplayStateFamily._();

/// Whether the auto-translate AI track is the live secondary for [mediaId],
/// plus the source → target pair its lines render with — the derivation both
/// transcript hosts (the echo merged card and the scrollable list) previously
/// re-spelled field by field.

final class AutoTranslateDisplayStateProvider
    extends
        $FunctionalProvider<
          ({bool active, String? sourceLanguage, String? targetLanguage}),
          ({bool active, String? sourceLanguage, String? targetLanguage}),
          ({bool active, String? sourceLanguage, String? targetLanguage})
        >
    with
        $Provider<
          ({bool active, String? sourceLanguage, String? targetLanguage})
        > {
  /// Whether the auto-translate AI track is the live secondary for [mediaId],
  /// plus the source → target pair its lines render with — the derivation both
  /// transcript hosts (the echo merged card and the scrollable list) previously
  /// re-spelled field by field.
  AutoTranslateDisplayStateProvider._({
    required AutoTranslateDisplayStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'autoTranslateDisplayStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$autoTranslateDisplayStateHash();

  @override
  String toString() {
    return r'autoTranslateDisplayStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<
    ({bool active, String? sourceLanguage, String? targetLanguage})
  >
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ({bool active, String? sourceLanguage, String? targetLanguage}) create(
    Ref ref,
  ) {
    final argument = this.argument as String;
    return autoTranslateDisplayState(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    ({bool active, String? sourceLanguage, String? targetLanguage}) value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            ({bool active, String? sourceLanguage, String? targetLanguage})
          >(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AutoTranslateDisplayStateProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$autoTranslateDisplayStateHash() =>
    r'9958b0188610af49045c07c467e03ab73565136c';

/// Whether the auto-translate AI track is the live secondary for [mediaId],
/// plus the source → target pair its lines render with — the derivation both
/// transcript hosts (the echo merged card and the scrollable list) previously
/// re-spelled field by field.

final class AutoTranslateDisplayStateFamily extends $Family
    with
        $FunctionalFamilyOverride<
          ({bool active, String? sourceLanguage, String? targetLanguage}),
          String
        > {
  AutoTranslateDisplayStateFamily._()
    : super(
        retry: null,
        name: r'autoTranslateDisplayStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether the auto-translate AI track is the live secondary for [mediaId],
  /// plus the source → target pair its lines render with — the derivation both
  /// transcript hosts (the echo merged card and the scrollable list) previously
  /// re-spelled field by field.

  AutoTranslateDisplayStateProvider call(String mediaId) =>
      AutoTranslateDisplayStateProvider._(argument: mediaId, from: this);

  @override
  String toString() => r'autoTranslateDisplayStateProvider';
}
