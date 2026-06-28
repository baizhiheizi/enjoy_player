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

String _$authCtrlHash() => r'93a0e389f787128195699465cddffe6f4bb96ead';

abstract class _$AuthCtrl extends $AsyncNotifier<AuthState> {
  FutureOr<AuthState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuthState>, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthState>, AuthState>,
              AsyncValue<AuthState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
