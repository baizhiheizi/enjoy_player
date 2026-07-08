// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcript_cue_reveal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns `true` when [cueId] should be rendered without the blur
/// filter given the current global toggle and tap-reveal hold.
///
/// Always returns `true` when blur practice mode is OFF — the toggle
/// off path is the no-blur default.
///
/// When blur practice mode is ON, the cue is revealed only if the
/// tap-reveal hold currently names this cue AND its expiry has not
/// passed. Hover state is intentionally NOT read here — it lives on
/// the tile widget so per-frame hover changes do not invalidate
/// unrelated cues.

@ProviderFor(transcriptCueReveal)
final transcriptCueRevealProvider = TranscriptCueRevealFamily._();

/// Returns `true` when [cueId] should be rendered without the blur
/// filter given the current global toggle and tap-reveal hold.
///
/// Always returns `true` when blur practice mode is OFF — the toggle
/// off path is the no-blur default.
///
/// When blur practice mode is ON, the cue is revealed only if the
/// tap-reveal hold currently names this cue AND its expiry has not
/// passed. Hover state is intentionally NOT read here — it lives on
/// the tile widget so per-frame hover changes do not invalidate
/// unrelated cues.

final class TranscriptCueRevealProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Returns `true` when [cueId] should be rendered without the blur
  /// filter given the current global toggle and tap-reveal hold.
  ///
  /// Always returns `true` when blur practice mode is OFF — the toggle
  /// off path is the no-blur default.
  ///
  /// When blur practice mode is ON, the cue is revealed only if the
  /// tap-reveal hold currently names this cue AND its expiry has not
  /// passed. Hover state is intentionally NOT read here — it lives on
  /// the tile widget so per-frame hover changes do not invalidate
  /// unrelated cues.
  TranscriptCueRevealProvider._({
    required TranscriptCueRevealFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'transcriptCueRevealProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transcriptCueRevealHash();

  @override
  String toString() {
    return r'transcriptCueRevealProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as (String, String);
    return transcriptCueReveal(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TranscriptCueRevealProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transcriptCueRevealHash() =>
    r'90230006c8b88cad3653baa5a9e0d26da5a741f2';

/// Returns `true` when [cueId] should be rendered without the blur
/// filter given the current global toggle and tap-reveal hold.
///
/// Always returns `true` when blur practice mode is OFF — the toggle
/// off path is the no-blur default.
///
/// When blur practice mode is ON, the cue is revealed only if the
/// tap-reveal hold currently names this cue AND its expiry has not
/// passed. Hover state is intentionally NOT read here — it lives on
/// the tile widget so per-frame hover changes do not invalidate
/// unrelated cues.

final class TranscriptCueRevealFamily extends $Family
    with $FunctionalFamilyOverride<bool, (String, String)> {
  TranscriptCueRevealFamily._()
    : super(
        retry: null,
        name: r'transcriptCueRevealProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns `true` when [cueId] should be rendered without the blur
  /// filter given the current global toggle and tap-reveal hold.
  ///
  /// Always returns `true` when blur practice mode is OFF — the toggle
  /// off path is the no-blur default.
  ///
  /// When blur practice mode is ON, the cue is revealed only if the
  /// tap-reveal hold currently names this cue AND its expiry has not
  /// passed. Hover state is intentionally NOT read here — it lives on
  /// the tile widget so per-frame hover changes do not invalidate
  /// unrelated cues.

  TranscriptCueRevealProvider call(String mediaId, String cueId) =>
      TranscriptCueRevealProvider._(argument: (mediaId, cueId), from: this);

  @override
  String toString() => r'transcriptCueRevealProvider';
}
