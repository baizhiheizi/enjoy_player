// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_transcript_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeTranscriptId)
final activeTranscriptIdProvider = ActiveTranscriptIdFamily._();

final class ActiveTranscriptIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  ActiveTranscriptIdProvider._({
    required ActiveTranscriptIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeTranscriptIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeTranscriptIdHash();

  @override
  String toString() {
    return r'activeTranscriptIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    final argument = this.argument as String;
    return activeTranscriptId(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveTranscriptIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeTranscriptIdHash() =>
    r'5283a08e0b81fc077d7b5975e2a3073be26b8469';

final class ActiveTranscriptIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<String?>, String> {
  ActiveTranscriptIdFamily._()
    : super(
        retry: null,
        name: r'activeTranscriptIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActiveTranscriptIdProvider call(String mediaId) =>
      ActiveTranscriptIdProvider._(argument: mediaId, from: this);

  @override
  String toString() => r'activeTranscriptIdProvider';
}

@ProviderFor(secondaryTranscriptId)
final secondaryTranscriptIdProvider = SecondaryTranscriptIdFamily._();

final class SecondaryTranscriptIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  SecondaryTranscriptIdProvider._({
    required SecondaryTranscriptIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'secondaryTranscriptIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$secondaryTranscriptIdHash();

  @override
  String toString() {
    return r'secondaryTranscriptIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    final argument = this.argument as String;
    return secondaryTranscriptId(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SecondaryTranscriptIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$secondaryTranscriptIdHash() =>
    r'86f6cba609842ae894502fae59cb18216eb70959';

final class SecondaryTranscriptIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<String?>, String> {
  SecondaryTranscriptIdFamily._()
    : super(
        retry: null,
        name: r'secondaryTranscriptIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SecondaryTranscriptIdProvider call(String mediaId) =>
      SecondaryTranscriptIdProvider._(argument: mediaId, from: this);

  @override
  String toString() => r'secondaryTranscriptIdProvider';
}
