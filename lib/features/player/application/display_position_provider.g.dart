// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'display_position_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(displayPosition)
final displayPositionProvider = DisplayPositionProvider._();

final class DisplayPositionProvider
    extends
        $FunctionalProvider<AsyncValue<Duration>, Duration, Stream<Duration>>
    with $FutureModifier<Duration>, $StreamProvider<Duration> {
  DisplayPositionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'displayPositionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$displayPositionHash();

  @$internal
  @override
  $StreamProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Duration> create(Ref ref) {
    return displayPosition(ref);
  }
}

String _$displayPositionHash() => r'4042801a08804a3667421c494e7355aa6c5d2d17';
