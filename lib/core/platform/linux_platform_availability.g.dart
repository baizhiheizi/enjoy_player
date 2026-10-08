// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'linux_platform_availability.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(youtubeAvailability)
final youtubeAvailabilityProvider = YoutubeAvailabilityProvider._();

final class YoutubeAvailabilityProvider
    extends
        $FunctionalProvider<
          AsyncValue<YouTubeAvailability>,
          YouTubeAvailability,
          FutureOr<YouTubeAvailability>
        >
    with
        $FutureModifier<YouTubeAvailability>,
        $FutureProvider<YouTubeAvailability> {
  YoutubeAvailabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'youtubeAvailabilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$youtubeAvailabilityHash();

  @$internal
  @override
  $FutureProviderElement<YouTubeAvailability> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<YouTubeAvailability> create(Ref ref) {
    return youtubeAvailability(ref);
  }
}

String _$youtubeAvailabilityHash() =>
    r'3e6fa2f9baca0040f4bcaabc3873f73602cefd31';
