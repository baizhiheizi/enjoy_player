// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Device-global Drift DB (`enjoy_player`) — API base URL and other non-user data.
///
/// Kept separate from [appDatabaseProvider] so [ApiBaseUrl] does not depend on
/// auth-scoped DB (avoids Riverpod cycles with [authCtrlProvider]).

@ProviderFor(guestAppDatabase)
final guestAppDatabaseProvider = GuestAppDatabaseProvider._();

/// Device-global Drift DB (`enjoy_player`) — API base URL and other non-user data.
///
/// Kept separate from [appDatabaseProvider] so [ApiBaseUrl] does not depend on
/// auth-scoped DB (avoids Riverpod cycles with [authCtrlProvider]).

final class GuestAppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Device-global Drift DB (`enjoy_player`) — API base URL and other non-user data.
  ///
  /// Kept separate from [appDatabaseProvider] so [ApiBaseUrl] does not depend on
  /// auth-scoped DB (avoids Riverpod cycles with [authCtrlProvider]).
  GuestAppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guestAppDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guestAppDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return guestAppDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$guestAppDatabaseHash() => r'104228fd0537e40c9dcc9276b27b47c823966b38';

/// Per-session library + prefs: guest file when signed out; `enjoy_player_<userId>` when signed in.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Per-session library + prefs: guest file when signed out; `enjoy_player_<userId>` when signed in.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Per-session library + prefs: guest file when signed out; `enjoy_player_<userId>` when signed in.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'346e988ff0ac0912b80f71c798a25b8b2d540b02';
