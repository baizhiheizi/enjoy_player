// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todays_credits_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(todaysCreditsUsed)
final todaysCreditsUsedProvider = TodaysCreditsUsedProvider._();

final class TodaysCreditsUsedProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  TodaysCreditsUsedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todaysCreditsUsedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todaysCreditsUsedHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return todaysCreditsUsed(ref);
  }
}

String _$todaysCreditsUsedHash() => r'29596860d28f6d41499e9855a191e444b8c67358';
