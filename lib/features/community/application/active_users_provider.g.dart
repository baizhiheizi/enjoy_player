// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_users_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeUsers)
final activeUsersProvider = ActiveUsersProvider._();

final class ActiveUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<ActiveUsersResponse?>,
          ActiveUsersResponse?,
          FutureOr<ActiveUsersResponse?>
        >
    with
        $FutureModifier<ActiveUsersResponse?>,
        $FutureProvider<ActiveUsersResponse?> {
  ActiveUsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeUsersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeUsersHash();

  @$internal
  @override
  $FutureProviderElement<ActiveUsersResponse?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ActiveUsersResponse?> create(Ref ref) {
    return activeUsers(ref);
  }
}

String _$activeUsersHash() => r'd06ba9a7e0afe604aa8e320bae832bbc7ad9b5bc';
