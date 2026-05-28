// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcript_line_recording_counts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Map of transcript line index → overlapping recording count for [mediaId].

@ProviderFor(transcriptLineRecordingCounts)
final transcriptLineRecordingCountsProvider =
    TranscriptLineRecordingCountsFamily._();

/// Map of transcript line index → overlapping recording count for [mediaId].

final class TranscriptLineRecordingCountsProvider
    extends $FunctionalProvider<Map<int, int>?, Map<int, int>?, Map<int, int>?>
    with $Provider<Map<int, int>?> {
  /// Map of transcript line index → overlapping recording count for [mediaId].
  TranscriptLineRecordingCountsProvider._({
    required TranscriptLineRecordingCountsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'transcriptLineRecordingCountsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transcriptLineRecordingCountsHash();

  @override
  String toString() {
    return r'transcriptLineRecordingCountsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Map<int, int>?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Map<int, int>? create(Ref ref) {
    final argument = this.argument as String;
    return transcriptLineRecordingCounts(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<int, int>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<int, int>?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TranscriptLineRecordingCountsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transcriptLineRecordingCountsHash() =>
    r'ccc2badb2b487d90a602ad7d264554b68857844b';

/// Map of transcript line index → overlapping recording count for [mediaId].

final class TranscriptLineRecordingCountsFamily extends $Family
    with $FunctionalFamilyOverride<Map<int, int>?, String> {
  TranscriptLineRecordingCountsFamily._()
    : super(
        retry: null,
        name: r'transcriptLineRecordingCountsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Map of transcript line index → overlapping recording count for [mediaId].

  TranscriptLineRecordingCountsProvider call(String mediaId) =>
      TranscriptLineRecordingCountsProvider._(argument: mediaId, from: this);

  @override
  String toString() => r'transcriptLineRecordingCountsProvider';
}
