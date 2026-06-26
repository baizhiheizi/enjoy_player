// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apple_sign_in_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appleSignInService)
final appleSignInServiceProvider = AppleSignInServiceProvider._();

final class AppleSignInServiceProvider
    extends
        $FunctionalProvider<
          AppleSignInService,
          AppleSignInService,
          AppleSignInService
        >
    with $Provider<AppleSignInService> {
  AppleSignInServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appleSignInServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appleSignInServiceHash();

  @$internal
  @override
  $ProviderElement<AppleSignInService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppleSignInService create(Ref ref) {
    return appleSignInService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppleSignInService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppleSignInService>(value),
    );
  }
}

String _$appleSignInServiceHash() =>
    r'965e3afb1a3377b0249e8041e68eb8e8c047abab';
