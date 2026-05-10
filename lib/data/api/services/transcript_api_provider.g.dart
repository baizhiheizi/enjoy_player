// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcript_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transcriptApi)
final transcriptApiProvider = TranscriptApiProvider._();

final class TranscriptApiProvider
    extends $FunctionalProvider<TranscriptApi, TranscriptApi, TranscriptApi>
    with $Provider<TranscriptApi> {
  TranscriptApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transcriptApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transcriptApiHash();

  @$internal
  @override
  $ProviderElement<TranscriptApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TranscriptApi create(Ref ref) {
    return transcriptApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TranscriptApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TranscriptApi>(value),
    );
  }
}

String _$transcriptApiHash() => r'b7aec1bd48e8c0af48e003048b8a385f9ae55e25';
