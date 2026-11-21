part of 'api_client.dart';

mixin _ApiClientDecoding {
  Future<Object?> _decodeResponseBody(http.Response response) async {
    final raw = response.body;
    if (raw.isEmpty) return null;
    return decodeJsonGated(raw, decode: decodeJsonToCamel);
  }

  /// The JSON-object envelope contract: a 2xx body must decode to a JSON
  /// object, anything else raises the API error for that status.
  Future<Map<String, dynamic>> _decodeMapResponse(
    http.Response response, {
    bool allowEmptyBody = false,
  }) async {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return await _failResponse(response);
    }
    if (response.body.isEmpty && allowEmptyBody) {
      return const <String, dynamic>{};
    }
    final decoded = await _decodeResponseBody(response);
    final map = castJsonObjectOrNull(decoded);
    if (map == null) {
      throw ApiException(
        message: 'Expected JSON object',
        statusCode: response.statusCode,
        body: decoded,
      );
    }
    return map;
  }

  /// The JSON-array envelope contract: a 2xx body must decode to a JSON array
  /// whose every element is an object.
  Future<List<Map<String, dynamic>>> _decodeListResponse(
    http.Response response,
  ) async {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return await _failResponse(response);
    }
    final decoded = await _decodeResponseBody(response);
    if (decoded is! List) {
      throw ApiException(
        message: 'Expected JSON array',
        statusCode: response.statusCode,
        body: decoded,
      );
    }
    return decoded.map<Map<String, dynamic>>((e) {
      final map = castJsonObjectOrNull(e);
      if (map == null) {
        throw ApiException(
          message: 'Array element is not an object',
          statusCode: response.statusCode,
          body: e,
        );
      }
      return map;
    }).toList();
  }

  /// Raises the API error for a non-2xx [response]. Never returns.
  Future<Never> _failResponse(http.Response response) async {
    await _throwApiError(response);
    throw AssertionError('unreachable');
  }

  Future<void> _throwApiError(http.Response response) async {
    Object? errBody;
    try {
      errBody = response.body.isEmpty
          ? null
          : await decodeJsonGated(response.body, decode: decodeJsonToCamel);
    } catch (_) {
      errBody = response.body;
    }

    throw ApiException(
      message: 'HTTP ${response.statusCode}',
      statusCode: response.statusCode,
      body: errBody,
    );
  }
}
