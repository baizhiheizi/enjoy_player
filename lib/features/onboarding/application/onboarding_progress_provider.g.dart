// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_progress_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OnboardingProgress)
final onboardingProgressProvider = OnboardingProgressProvider._();

final class OnboardingProgressProvider
    extends $AsyncNotifierProvider<OnboardingProgress, TipProgressSnapshot> {
  OnboardingProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingProgressProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingProgressHash();

  @$internal
  @override
  OnboardingProgress create() => OnboardingProgress();
}

String _$onboardingProgressHash() =>
    r'b5e4f7e51a36a7b34effe351e16214907c1b4652';

abstract class _$OnboardingProgress
    extends $AsyncNotifier<TipProgressSnapshot> {
  FutureOr<TipProgressSnapshot> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TipProgressSnapshot>, TipProgressSnapshot>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TipProgressSnapshot>, TipProgressSnapshot>,
              AsyncValue<TipProgressSnapshot>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
