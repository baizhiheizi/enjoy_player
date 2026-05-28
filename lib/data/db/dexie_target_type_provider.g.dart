// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dexie_target_type_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dexieTargetTypeForMedia)
final dexieTargetTypeForMediaProvider = DexieTargetTypeForMediaFamily._();

final class DexieTargetTypeForMediaProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  DexieTargetTypeForMediaProvider._({
    required DexieTargetTypeForMediaFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'dexieTargetTypeForMediaProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dexieTargetTypeForMediaHash();

  @override
  String toString() {
    return r'dexieTargetTypeForMediaProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return dexieTargetTypeForMedia(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DexieTargetTypeForMediaProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dexieTargetTypeForMediaHash() =>
    r'545f88377972109adb99d70cdfabfaed3d4de93b';

final class DexieTargetTypeForMediaFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  DexieTargetTypeForMediaFamily._()
    : super(
        retry: null,
        name: r'dexieTargetTypeForMediaProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DexieTargetTypeForMediaProvider call(String mediaId) =>
      DexieTargetTypeForMediaProvider._(argument: mediaId, from: this);

  @override
  String toString() => r'dexieTargetTypeForMediaProvider';
}
