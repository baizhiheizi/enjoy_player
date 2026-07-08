// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcript_blur_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TranscriptBlurPreferencesCtrl)
final transcriptBlurPreferencesCtrlProvider =
    TranscriptBlurPreferencesCtrlProvider._();

final class TranscriptBlurPreferencesCtrlProvider
    extends
        $AsyncNotifierProvider<
          TranscriptBlurPreferencesCtrl,
          TranscriptBlurPreferences
        > {
  TranscriptBlurPreferencesCtrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transcriptBlurPreferencesCtrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transcriptBlurPreferencesCtrlHash();

  @$internal
  @override
  TranscriptBlurPreferencesCtrl create() => TranscriptBlurPreferencesCtrl();
}

String _$transcriptBlurPreferencesCtrlHash() =>
    r'1da12d0e8b186cba27aea9d0729a6d74ce2c033a';

abstract class _$TranscriptBlurPreferencesCtrl
    extends $AsyncNotifier<TranscriptBlurPreferences> {
  FutureOr<TranscriptBlurPreferences> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<TranscriptBlurPreferences>,
              TranscriptBlurPreferences
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<TranscriptBlurPreferences>,
                TranscriptBlurPreferences
              >,
              AsyncValue<TranscriptBlurPreferences>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Read-only projection of the persisted preferences. Useful when a
/// widget only needs to read the current value without ever
/// triggering a setter.

@ProviderFor(transcriptBlurPreferences)
final transcriptBlurPreferencesProvider = TranscriptBlurPreferencesProvider._();

/// Read-only projection of the persisted preferences. Useful when a
/// widget only needs to read the current value without ever
/// triggering a setter.

final class TranscriptBlurPreferencesProvider
    extends
        $FunctionalProvider<
          TranscriptBlurPreferences,
          TranscriptBlurPreferences,
          TranscriptBlurPreferences
        >
    with $Provider<TranscriptBlurPreferences> {
  /// Read-only projection of the persisted preferences. Useful when a
  /// widget only needs to read the current value without ever
  /// triggering a setter.
  TranscriptBlurPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transcriptBlurPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transcriptBlurPreferencesHash();

  @$internal
  @override
  $ProviderElement<TranscriptBlurPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TranscriptBlurPreferences create(Ref ref) {
    return transcriptBlurPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TranscriptBlurPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TranscriptBlurPreferences>(value),
    );
  }
}

String _$transcriptBlurPreferencesHash() =>
    r'3225e6e6ef3e1b2a5b096fbd78570a36a6de8864';
