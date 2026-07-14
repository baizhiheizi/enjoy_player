// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_profiles_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(youtubeProfiles)
final youtubeProfilesProvider = YoutubeProfilesProvider._();

final class YoutubeProfilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ClientProfile>>,
          List<ClientProfile>,
          FutureOr<List<ClientProfile>>
        >
    with
        $FutureModifier<List<ClientProfile>>,
        $FutureProvider<List<ClientProfile>> {
  YoutubeProfilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'youtubeProfilesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$youtubeProfilesHash();

  @$internal
  @override
  $FutureProviderElement<List<ClientProfile>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ClientProfile>> create(Ref ref) {
    return youtubeProfiles(ref);
  }
}

String _$youtubeProfilesHash() => r'7ade9e166f41d449cd3467fed74bc5a11bba9094';
