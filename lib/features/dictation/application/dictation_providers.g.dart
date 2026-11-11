// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dictation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DictationSessionCtrl)
final dictationSessionCtrlProvider = DictationSessionCtrlFamily._();

final class DictationSessionCtrlProvider
    extends $NotifierProvider<DictationSessionCtrl, DictationSessionState> {
  DictationSessionCtrlProvider._({
    required DictationSessionCtrlFamily super.from,
    required (String, String, int, int, String, String) super.argument,
  }) : super(
         retry: null,
         name: r'dictationSessionCtrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dictationSessionCtrlHash();

  @override
  String toString() {
    return r'dictationSessionCtrlProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  DictationSessionCtrl create() => DictationSessionCtrl();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DictationSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DictationSessionState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DictationSessionCtrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dictationSessionCtrlHash() =>
    r'f9ed2e2927f1263b688a468ac305ee9d463a0a19';

final class DictationSessionCtrlFamily extends $Family
    with
        $ClassFamilyOverride<
          DictationSessionCtrl,
          DictationSessionState,
          DictationSessionState,
          DictationSessionState,
          (String, String, int, int, String, String)
        > {
  DictationSessionCtrlFamily._()
    : super(
        retry: null,
        name: r'dictationSessionCtrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DictationSessionCtrlProvider call(
    String targetType,
    String targetId,
    int startMs,
    int durationMs,
    String referenceText,
    String language,
  ) => DictationSessionCtrlProvider._(
    argument: (
      targetType,
      targetId,
      startMs,
      durationMs,
      referenceText,
      language,
    ),
    from: this,
  );

  @override
  String toString() => r'dictationSessionCtrlProvider';
}

abstract class _$DictationSessionCtrl extends $Notifier<DictationSessionState> {
  late final _$args = ref.$arg as (String, String, int, int, String, String);
  String get targetType => _$args.$1;
  String get targetId => _$args.$2;
  int get startMs => _$args.$3;
  int get durationMs => _$args.$4;
  String get referenceText => _$args.$5;
  String get language => _$args.$6;

  DictationSessionState build(
    String targetType,
    String targetId,
    int startMs,
    int durationMs,
    String referenceText,
    String language,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DictationSessionState, DictationSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DictationSessionState, DictationSessionState>,
              DictationSessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        _$args.$1,
        _$args.$2,
        _$args.$3,
        _$args.$4,
        _$args.$5,
        _$args.$6,
      ),
    );
  }
}
