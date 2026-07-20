// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_statistics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(learningStatistics)
final learningStatisticsProvider = LearningStatisticsProvider._();

final class LearningStatisticsProvider
    extends
        $FunctionalProvider<
          AsyncValue<LearningStatistics?>,
          LearningStatistics?,
          FutureOr<LearningStatistics?>
        >
    with
        $FutureModifier<LearningStatistics?>,
        $FutureProvider<LearningStatistics?> {
  LearningStatisticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'learningStatisticsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$learningStatisticsHash();

  @$internal
  @override
  $FutureProviderElement<LearningStatistics?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LearningStatistics?> create(Ref ref) {
    return learningStatistics(ref);
  }
}

String _$learningStatisticsHash() =>
    r'4a878c38b4a3414bcc7734de3092055604a2c603';
