// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcript_typeface_settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TranscriptTypefaceSettings)
final transcriptTypefaceSettingsProvider =
    TranscriptTypefaceSettingsProvider._();

final class TranscriptTypefaceSettingsProvider
    extends
        $AsyncNotifierProvider<TranscriptTypefaceSettings, TranscriptTypeface> {
  TranscriptTypefaceSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transcriptTypefaceSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transcriptTypefaceSettingsHash();

  @$internal
  @override
  TranscriptTypefaceSettings create() => TranscriptTypefaceSettings();
}

String _$transcriptTypefaceSettingsHash() =>
    r'0a497781e73cab01fca989507bd4ee74f8fd7498';

abstract class _$TranscriptTypefaceSettings
    extends $AsyncNotifier<TranscriptTypeface> {
  FutureOr<TranscriptTypeface> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TranscriptTypeface>, TranscriptTypeface>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TranscriptTypeface>, TranscriptTypeface>,
              AsyncValue<TranscriptTypeface>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
