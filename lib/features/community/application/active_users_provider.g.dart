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

String _$activeUsersHash() => r'362224c1fcdd1972f09ba4ef67c38c2d80f65163';
