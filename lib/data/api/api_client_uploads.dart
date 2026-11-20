part of 'api_client.dart';

mixin _ApiClientUploads on _ApiClientDispatch {
  /// PUT raw bytes to a relative API path with optional bearer auth.
  ///
  /// Used for Worker media upload (`PUT /audio/media/:ref`). Returns decoded
  /// JSON object with camelCase keys when the body is a JSON object.
  Future<Map<String, dynamic>> putBytesJson(
    String path, {
    required List<int> bytes,
    required String contentType,
    bool requireAuth = true,
  }) async {
    final merged = await _resolveApiUrl(path);

    final bearer = await _ensureAuthenticated(requireAuth);

    final request = http.Request('PUT', merged)..bodyBytes = bytes;
    request.headers['Accept'] = 'application/json';
    request.headers['Content-Type'] = contentType;
    if (bearer != null) {
      request.headers['Authorization'] = 'Bearer $bearer';
    }

    final response = await _sendUnbuffered(
      request,
      merged,
      logLabel: ' (bytes len=${bytes.length})',
    );
    return _decodeMapResponse(response);
  }

  /// Streams a file from disk via PUT without materializing its bytes in RAM.
  Future<Map<String, dynamic>> putFileJson(
    String path, {
    required String filePath,
    required String contentType,
    bool requireAuth = true,
  }) async {
    final merged = await _resolveApiUrl(path);
    final bearer = await _ensureAuthenticated(requireAuth);
    final file = File(filePath);
    final len = await file.length();

    final request = http.StreamedRequest('PUT', merged);
    request.contentLength = len;
    request.headers['Accept'] = 'application/json';
    request.headers['Content-Type'] = contentType;
    if (bearer != null) {
      request.headers['Authorization'] = 'Bearer $bearer';
    }
    unawaited(
      file.openRead().pipe(request.sink).catchError((Object e, StackTrace st) {
        request.sink.addError(e, st);
        return request.sink.close();
      }),
    );

    final response = await _sendUnbuffered(
      request,
      merged,
      logLabel: ' (file len=$len)',
    );
    return _decodeMapResponse(response);
  }

  /// PUT raw bytes to an absolute URL (e.g. Active Storage direct-upload target).
  ///
  /// Does not attach the Enjoy bearer token — storage backends use [headers]
  /// from the direct-upload create response.
  Future<void> putBytesAbsolute(
    Uri url, {
    required List<int> bytes,
    Map<String, String> headers = const {},
  }) async {
    final request = http.Request('PUT', url)..bodyBytes = bytes;
    request.headers.addAll(headers);

    final response = await _sendUnbuffered(
      request,
      url,
      logLabel: ' (bytes len=${bytes.length})',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: 'Direct upload failed (${response.statusCode})',
        statusCode: response.statusCode,
        body: utf8.decode(response.bodyBytes, allowMalformed: true),
      );
    }
  }

  /// Multipart POST (e.g. Whisper) returning a JSON object with camelCase keys.
  Future<Map<String, dynamic>> postMultipartJson(
    String path, {
    required String fileFieldName,
    List<int>? fileBytes,
    String? filePath,
    String? fileFilename,
    Map<String, String> fields = const {},
    bool requireAuth = true,
  }) async {
    final merged = await _resolveApiUrl(path);

    final bearer = await _ensureAuthenticated(requireAuth);

    final request = http.MultipartRequest('POST', merged);
    request.headers['Accept'] = 'application/json';
    if (bearer != null) {
      request.headers['Authorization'] = 'Bearer $bearer';
    }
    if (filePath != null && filePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          fileFieldName,
          filePath,
          filename: fileFilename,
        ),
      );
    } else {
      request.files.add(
        http.MultipartFile.fromBytes(
          fileFieldName,
          fileBytes ?? const [],
          filename: fileFilename,
        ),
      );
    }
    for (final e in fields.entries) {
      request.fields[e.key] = e.value;
    }

    final response = await _sendUnbuffered(
      request,
      merged,
      method: 'POST',
      logLabel: ' (multipart)',
    );
    return _decodeMapResponse(response);
  }

  /// Sends an unbuffered [request] (bytes / multipart) with the shared
  /// trace + stopwatch + error logging scaffolding, buffering the streamed
  /// reply into an [http.Response].
  Future<http.Response> _sendUnbuffered(
    http.BaseRequest request,
    Uri url, {
    String method = 'PUT',
    String logLabel = '',
  }) async {
    final sw = Stopwatch()..start();
    _apiHttpTrace('HTTP → $method $url$logLabel');
    try {
      final streamed = await _client.send(request);
      final bodyBytes = await streamed.stream.toBytes();
      sw.stop();
      final response = http.Response.bytes(
        bodyBytes,
        streamed.statusCode,
        headers: streamed.headers,
        request: request,
      );
      _apiHttpTrace(
        'HTTP ← $method $url ${response.statusCode} '
        '${sw.elapsedMilliseconds}ms len=${bodyBytes.length}',
      );
      return response;
    } catch (e, st) {
      sw.stop();
      _log.warning(
        'HTTP ✗ $method $url$logLabel after ${sw.elapsedMilliseconds}ms: $e',
        e,
        st,
      );
      rethrow;
    }
  }
}
