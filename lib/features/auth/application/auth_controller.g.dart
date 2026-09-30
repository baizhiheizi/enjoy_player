// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthCtrl)
final authCtrlProvider = AuthCtrlProvider._();

final class AuthCtrlProvider
    extends $AsyncNotifierProvider<AuthCtrl, AuthState> {
  AuthCtrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authCtrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authCtrlHash();

  @$internal
  @override
  AuthCtrl create() => AuthCtrl();
}

String _$authCtrlHash() => r'953ac823017fa56cdcefce05ef606887353501bd';

abstract class _$AuthCtrl extends $AsyncNotifier<AuthState> {
  FutureOr<AuthState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuthState>, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthState>, AuthState>,
              AsyncValue<AuthState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether the session is signed in, leaf-scoped off [AuthCtrl] so
/// profile refreshes (credits, avatar, name) do not rebuild consumers —
/// one definition of the projection instead of a `select` per call site
/// (issue #827 C1).

@ProviderFor(authIsSignedIn)
final authIsSignedInProvider = AuthIsSignedInProvider._();

/// Whether the session is signed in, leaf-scoped off [AuthCtrl] so
/// profile refreshes (credits, avatar, name) do not rebuild consumers —
/// one definition of the projection instead of a `select` per call site
/// (issue #827 C1).

final class AuthIsSignedInProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the session is signed in, leaf-scoped off [AuthCtrl] so
  /// profile refreshes (credits, avatar, name) do not rebuild consumers —
  /// one definition of the projection instead of a `select` per call site
  /// (issue #827 C1).
  AuthIsSignedInProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authIsSignedInProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authIsSignedInHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return authIsSignedIn(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$authIsSignedInHash() => r'92c39b4b6007b1ac44c75c2536b811c850b256b1';
