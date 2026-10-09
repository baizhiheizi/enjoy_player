// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lookup_credits_exhausted_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LookupCreditsExhausted)
final lookupCreditsExhaustedProvider = LookupCreditsExhaustedProvider._();

final class LookupCreditsExhaustedProvider
    extends
        $NotifierProvider<
          LookupCreditsExhausted,
          Map<LookupSectionId, String>
        > {
  LookupCreditsExhaustedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lookupCreditsExhaustedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lookupCreditsExhaustedHash();

  @$internal
  @override
  LookupCreditsExhausted create() => LookupCreditsExhausted();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<LookupSectionId, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<LookupSectionId, String>>(value),
    );
  }
}

String _$lookupCreditsExhaustedHash() =>
    r'442b6dc8fbf0512e326b202a55f5e0081690c660';

abstract class _$LookupCreditsExhausted
    extends $Notifier<Map<LookupSectionId, String>> {
  Map<LookupSectionId, String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<Map<LookupSectionId, String>, Map<LookupSectionId, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<LookupSectionId, String>,
                Map<LookupSectionId, String>
              >,
              Map<LookupSectionId, String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
