// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credits_packages_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(creditsPackagesRepository)
final creditsPackagesRepositoryProvider = CreditsPackagesRepositoryProvider._();

final class CreditsPackagesRepositoryProvider
    extends
        $FunctionalProvider<
          CreditsPackagesRepository,
          CreditsPackagesRepository,
          CreditsPackagesRepository
        >
    with $Provider<CreditsPackagesRepository> {
  CreditsPackagesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'creditsPackagesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$creditsPackagesRepositoryHash();

  @$internal
  @override
  $ProviderElement<CreditsPackagesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreditsPackagesRepository create(Ref ref) {
    return creditsPackagesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreditsPackagesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreditsPackagesRepository>(value),
    );
  }
}

String _$creditsPackagesRepositoryHash() =>
    r'b4daed30f7248761a970dede586cffc7847772d7';
