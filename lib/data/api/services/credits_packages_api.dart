/// Rails `/api/v1/credits/packages` catalog and checkout.
library;

import 'package:enjoy_player/data/api/rest_api.dart';

class CreditsPackagesApi extends RestApi {
  CreditsPackagesApi(super.client);

  static const _path = '/api/v1/credits/packages';

  Future<Map<String, dynamic>> listPackages() => client.getJson(_path);

  Future<Map<String, dynamic>> startPackagePurchase({
    required String packageId,
  }) => client.postJson('$_path/purchases', body: {'packageId': packageId});
}
