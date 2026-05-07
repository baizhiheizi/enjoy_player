// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'embedded_tracks_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EmbeddedTracksNotifier)
final embeddedTracksProvider = EmbeddedTracksNotifierProvider._();

final class EmbeddedTracksNotifierProvider
    extends $NotifierProvider<EmbeddedTracksNotifier, EmbeddedTracksEvent?> {
  EmbeddedTracksNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'embeddedTracksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$embeddedTracksNotifierHash();

  @$internal
  @override
  EmbeddedTracksNotifier create() => EmbeddedTracksNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmbeddedTracksEvent? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmbeddedTracksEvent?>(value),
    );
  }
}

String _$embeddedTracksNotifierHash() =>
    r'75f2293af9f8b7d55309049f4ab66da60d52e60b';

abstract class _$EmbeddedTracksNotifier
    extends $Notifier<EmbeddedTracksEvent?> {
  EmbeddedTracksEvent? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<EmbeddedTracksEvent?, EmbeddedTracksEvent?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EmbeddedTracksEvent?, EmbeddedTracksEvent?>,
              EmbeddedTracksEvent?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
