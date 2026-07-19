// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asr_long_form_attempt_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(asrLongFormAttemptStore)
final asrLongFormAttemptStoreProvider = AsrLongFormAttemptStoreProvider._();

final class AsrLongFormAttemptStoreProvider
    extends
        $FunctionalProvider<
          AsrLongFormAttemptStore,
          AsrLongFormAttemptStore,
          AsrLongFormAttemptStore
        >
    with $Provider<AsrLongFormAttemptStore> {
  AsrLongFormAttemptStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asrLongFormAttemptStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asrLongFormAttemptStoreHash();

  @$internal
  @override
  $ProviderElement<AsrLongFormAttemptStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsrLongFormAttemptStore create(Ref ref) {
    return asrLongFormAttemptStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsrLongFormAttemptStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsrLongFormAttemptStore>(value),
    );
  }
}

String _$asrLongFormAttemptStoreHash() =>
    r'83890a8eb5eb6feb8920364482fcf359ec01b8d3';
