/// Build a query-string map for `ApiClient` GETs, dropping `null` and empty values.
///
/// Several API service methods used to repeat the same boilerplate:
///
/// ```dart
/// final q = <String, String>{};
/// if (provider != null) q['provider'] = provider;
/// if (limit != null) q['limit'] = '$limit';
/// return _client.getJsonList(_path, queryParameters: q.isEmpty ? null : q);
/// ```
///
/// [buildQuery] collapses that into a single call so adding/removing a query
/// parameter is a one-line change. `null` values are dropped; empty strings
/// are dropped (matching the `isNotEmpty` guard `credits_api.dart` used); all
/// other values are coerced to their string form.
library;

Map<String, String>? buildQuery(Map<String, Object?> params) {
  final out = <String, String>{};
  params.forEach((key, value) {
    if (value == null) return;
    if (value is String && value.isEmpty) return;
    out[key] = value is String ? value : value.toString();
  });
  return out.isEmpty ? null : out;
}
