// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_router_tick.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRouterTick)
final authRouterTickProvider = AuthRouterTickProvider._();

final class AuthRouterTickProvider
    extends
        $FunctionalProvider<
          ValueNotifier<int>,
          ValueNotifier<int>,
          ValueNotifier<int>
        >
    with $Provider<ValueNotifier<int>> {
  AuthRouterTickProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRouterTickProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRouterTickHash();

  @$internal
  @override
  $ProviderElement<ValueNotifier<int>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ValueNotifier<int> create(Ref ref) {
    return authRouterTick(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ValueNotifier<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ValueNotifier<int>>(value),
    );
  }
}

String _$authRouterTickHash() => r'7e01e82c7b2a4673aa52277636a280cff8cdf8b7';
