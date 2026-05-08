// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_search_focus_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(librarySearchFocusNode)
final librarySearchFocusNodeProvider = LibrarySearchFocusNodeProvider._();

final class LibrarySearchFocusNodeProvider
    extends $FunctionalProvider<FocusNode, FocusNode, FocusNode>
    with $Provider<FocusNode> {
  LibrarySearchFocusNodeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'librarySearchFocusNodeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$librarySearchFocusNodeHash();

  @$internal
  @override
  $ProviderElement<FocusNode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FocusNode create(Ref ref) {
    return librarySearchFocusNode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FocusNode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FocusNode>(value),
    );
  }
}

String _$librarySearchFocusNodeHash() =>
    r'cedebc56634790652972cead06b89fd52e374140';
