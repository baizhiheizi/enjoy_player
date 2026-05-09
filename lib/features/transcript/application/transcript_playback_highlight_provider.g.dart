// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcript_playback_highlight_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Current cue index for transcript highlighting (echo-aware).
///
/// Depends on [displayPositionProvider] but consumers should use
/// `.select((i) => i)` so widgets rebuild only when the index **changes**.

@ProviderFor(transcriptPlaybackHighlight)
final transcriptPlaybackHighlightProvider =
    TranscriptPlaybackHighlightFamily._();

/// Current cue index for transcript highlighting (echo-aware).
///
/// Depends on [displayPositionProvider] but consumers should use
/// `.select((i) => i)` so widgets rebuild only when the index **changes**.

final class TranscriptPlaybackHighlightProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Current cue index for transcript highlighting (echo-aware).
  ///
  /// Depends on [displayPositionProvider] but consumers should use
  /// `.select((i) => i)` so widgets rebuild only when the index **changes**.
  TranscriptPlaybackHighlightProvider._({
    required TranscriptPlaybackHighlightFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'transcriptPlaybackHighlightProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transcriptPlaybackHighlightHash();

  @override
  String toString() {
    return r'transcriptPlaybackHighlightProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    final argument = this.argument as String;
    return transcriptPlaybackHighlight(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TranscriptPlaybackHighlightProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transcriptPlaybackHighlightHash() =>
    r'4ecad8c0a674b26abee5c33a5950b306520fa633';

/// Current cue index for transcript highlighting (echo-aware).
///
/// Depends on [displayPositionProvider] but consumers should use
/// `.select((i) => i)` so widgets rebuild only when the index **changes**.

final class TranscriptPlaybackHighlightFamily extends $Family
    with $FunctionalFamilyOverride<int, String> {
  TranscriptPlaybackHighlightFamily._()
    : super(
        retry: null,
        name: r'transcriptPlaybackHighlightProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Current cue index for transcript highlighting (echo-aware).
  ///
  /// Depends on [displayPositionProvider] but consumers should use
  /// `.select((i) => i)` so widgets rebuild only when the index **changes**.

  TranscriptPlaybackHighlightProvider call(String mediaId) =>
      TranscriptPlaybackHighlightProvider._(argument: mediaId, from: this);

  @override
  String toString() => r'transcriptPlaybackHighlightProvider';
}
