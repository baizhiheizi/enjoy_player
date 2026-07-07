// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(statsApi)
final statsApiProvider = StatsApiProvider._();

final class StatsApiProvider
    extends $FunctionalProvider<StatsApi, StatsApi, StatsApi>
    with $Provider<StatsApi> {
  StatsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statsApiHash();

  @$internal
  @override
  $ProviderElement<StatsApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StatsApi create(Ref ref) {
    return statsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatsApi>(value),
    );
  }
}

String _$statsApiHash() => r'db1ca67e645d88e0df385ea6c42a39615201d7fa';

@ProviderFor(userApi)
final userApiProvider = UserApiProvider._();

final class UserApiProvider
    extends $FunctionalProvider<UserApi, UserApi, UserApi>
    with $Provider<UserApi> {
  UserApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userApiHash();

  @$internal
  @override
  $ProviderElement<UserApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserApi create(Ref ref) {
    return userApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserApi>(value),
    );
  }
}

String _$userApiHash() => r'23f185146d93445fd66b7da737968db3c665f211';

@ProviderFor(transcriptApi)
final transcriptApiProvider = TranscriptApiProvider._();

final class TranscriptApiProvider
    extends $FunctionalProvider<TranscriptApi, TranscriptApi, TranscriptApi>
    with $Provider<TranscriptApi> {
  TranscriptApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transcriptApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transcriptApiHash();

  @$internal
  @override
  $ProviderElement<TranscriptApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TranscriptApi create(Ref ref) {
    return transcriptApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TranscriptApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TranscriptApi>(value),
    );
  }
}

String _$transcriptApiHash() => r'5c8a8aeafad31ac0eb988aed22346d0abd8994b3';

@ProviderFor(subscriptionApi)
final subscriptionApiProvider = SubscriptionApiProvider._();

final class SubscriptionApiProvider
    extends
        $FunctionalProvider<SubscriptionApi, SubscriptionApi, SubscriptionApi>
    with $Provider<SubscriptionApi> {
  SubscriptionApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionApiHash();

  @$internal
  @override
  $ProviderElement<SubscriptionApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SubscriptionApi create(Ref ref) {
    return subscriptionApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubscriptionApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubscriptionApi>(value),
    );
  }
}

String _$subscriptionApiHash() => r'5f8b0690c51890e7d76326084dfb73238be30c4c';
