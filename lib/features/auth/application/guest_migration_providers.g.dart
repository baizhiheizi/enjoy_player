// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest_migration_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `true` when the guest DB has at least one row in library or practice tables.

@ProviderFor(guestDatabaseHasData)
final guestDatabaseHasDataProvider = GuestDatabaseHasDataProvider._();

/// `true` when the guest DB has at least one row in library or practice tables.

final class GuestDatabaseHasDataProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// `true` when the guest DB has at least one row in library or practice tables.
  GuestDatabaseHasDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guestDatabaseHasDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guestDatabaseHasDataHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return guestDatabaseHasData(ref);
  }
}

String _$guestDatabaseHasDataHash() =>
    r'c7a8a55b2c1cd0dc01f1c8d56ce986da84acebe2';

/// Banner: signed in, guest has data, user has not dismissed.

@ProviderFor(showGuestMigrationBanner)
final showGuestMigrationBannerProvider = ShowGuestMigrationBannerProvider._();

/// Banner: signed in, guest has data, user has not dismissed.

final class ShowGuestMigrationBannerProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Banner: signed in, guest has data, user has not dismissed.
  ShowGuestMigrationBannerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'showGuestMigrationBannerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$showGuestMigrationBannerHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return showGuestMigrationBanner(ref);
  }
}

String _$showGuestMigrationBannerHash() =>
    r'75802bbafb1ab35285b34a6b2a706e25d587a664';

@ProviderFor(GuestMigrationCtrl)
final guestMigrationCtrlProvider = GuestMigrationCtrlProvider._();

final class GuestMigrationCtrlProvider
    extends $AsyncNotifierProvider<GuestMigrationCtrl, void> {
  GuestMigrationCtrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guestMigrationCtrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guestMigrationCtrlHash();

  @$internal
  @override
  GuestMigrationCtrl create() => GuestMigrationCtrl();
}

String _$guestMigrationCtrlHash() =>
    r'cbd36c96cea8ca0f6c2d9b0e6d81bd86cd2a9783';

abstract class _$GuestMigrationCtrl extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
