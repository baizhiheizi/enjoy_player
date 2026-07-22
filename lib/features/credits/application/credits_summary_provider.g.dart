// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credits_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(creditsSummary)
final creditsSummaryProvider = CreditsSummaryProvider._();

final class CreditsSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<CreditsSummary>,
          CreditsSummary,
          FutureOr<CreditsSummary>
        >
    with $FutureModifier<CreditsSummary>, $FutureProvider<CreditsSummary> {
  CreditsSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'creditsSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$creditsSummaryHash();

  @$internal
  @override
  $FutureProviderElement<CreditsSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CreditsSummary> create(Ref ref) {
    return creditsSummary(ref);
  }
}

String _$creditsSummaryHash() => r'ea2ccd0fda8c0d8d422f558276a6af7579db6fee';
