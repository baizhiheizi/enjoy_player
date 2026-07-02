/// Shared base for thin REST service wrappers around [ApiClient].
library;

import 'package:meta/meta.dart';

import 'package:enjoy_player/data/api/api_client.dart';

/// Every `*Api` class in `lib/data/api/services/` is a one-field wrapper
/// around [ApiClient]: extend this instead of redeclaring the field and
/// constructor in each service.
///
/// [client] is `@protected` (analyzer-enforced within this package) rather
/// than private: each service lives in its own file/library, and Dart's
/// `_` privacy is per-library, so a private field declared here would not
/// be visible to subclasses declared elsewhere.
abstract class RestApi {
  const RestApi(this.client);

  @protected
  final ApiClient client;
}
