/// Rails credits packages catalog + checkout.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/services/api_providers.dart';
import 'package:enjoy_player/data/api/services/credits_packages_api.dart';
import 'package:enjoy_player/features/credits/domain/credits_package.dart';

part 'credits_packages_repository.g.dart';

@Riverpod(keepAlive: true)
CreditsPackagesRepository creditsPackagesRepository(Ref ref) {
  return CreditsPackagesRepository(ref.watch(creditsPackagesApiProvider));
}

class CreditsPackagesRepository {
  CreditsPackagesRepository(this._api);

  final CreditsPackagesApi _api;

  Future<List<CreditsPackage>> listPackages() async {
    try {
      final json = await _api.listPackages();
      final raw = json['packages'];
      if (raw is! List) return const [];
      final packages = <CreditsPackage>[];
      for (final e in raw) {
        final map = castJsonObjectOrNull(e);
        if (map != null) packages.add(CreditsPackage.fromJson(map));
      }
      return packages;
    } on ApiException catch (e) {
      throw _map(e);
    } on FormatException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  Future<CreditsPackagePurchaseSession> startPurchase({
    required String packageId,
  }) async {
    try {
      final json = await _api.startPackagePurchase(packageId: packageId);
      return CreditsPackagePurchaseSession.fromJson(json);
    } on ApiException catch (e) {
      throw _map(e);
    } on FormatException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  AppFailure _map(ApiException e) {
    if (e.statusCode == 402) return CreditsFailure(e.message);
    return NetworkFailure(e.message, statusCode: e.statusCode);
  }
}
