/// Shared error-handling template for REST repositories.
library;

import 'package:meta/meta.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/data/api/api_exception.dart';

/// Mixin for repositories that wrap `*Api` services and translate transport
/// errors into [AppFailure]s. Consolidates the `try / on ApiException /
/// on FormatException` template so error-mapping changes happen in one place.
mixin RestRepository {
  /// Maps an [ApiException] to the feature-specific [AppFailure].
  @protected
  AppFailure mapApiException(ApiException e);

  /// Runs [call], rethrowing [ApiException] through [mapApiException] and
  /// JSON-decode [FormatException]s as [NetworkFailure].
  Future<T> apiCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      throw mapApiException(e);
    } on FormatException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  /// Parses the list at [field] in an API response, skipping entries that are
  /// not JSON objects. Returns an empty list when the field is absent.
  List<T> parseJsonListField<T>(
    Map<String, dynamic> json,
    String field,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = json[field];
    if (raw is! List) return const [];
    final items = <T>[];
    for (final e in raw) {
      final map = castJsonObjectOrNull(e);
      if (map != null) items.add(fromJson(map));
    }
    return items;
  }
}
