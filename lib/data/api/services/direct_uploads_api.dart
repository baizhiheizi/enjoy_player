/// Active Storage direct uploads (`POST /api/v1/direct_uploads`).
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/rest_api.dart';

/// Creates a blob via Rails Active Storage direct uploads, PUTs bytes to the
/// returned URL, and returns the blob `signedId` for attaching on a model.
class DirectUploadsApi extends RestApi {
  const DirectUploadsApi(super.client);

  static const _path = '/api/v1/direct_uploads';

  /// Uploads [bytes] and returns the Active Storage `signed_id`.
  Future<String> uploadBlob({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    final checksum = base64.encode(md5.convert(bytes).bytes);
    final created = await client.postJson(
      _path,
      body: {
        'blob': {
          'filename': filename,
          'byteSize': bytes.length,
          'checksum': checksum,
          'contentType': contentType,
        },
      },
    );

    final signedId = created['signedId']?.toString();
    if (signedId == null || signedId.isEmpty) {
      throw const ApiException(
        message: 'Direct upload response missing signedId',
      );
    }

    final direct = castJsonObjectOrNull(created['directUpload']);
    if (direct == null) {
      throw const ApiException(
        message: 'Direct upload response missing directUpload',
      );
    }
    final urlRaw = direct['url']?.toString();
    if (urlRaw == null || urlRaw.isEmpty) {
      throw const ApiException(
        message: 'Direct upload response missing upload URL',
      );
    }
    final headers = <String, String>{};
    final rawHeaders = direct['headers'];
    if (rawHeaders is Map) {
      for (final e in rawHeaders.entries) {
        headers['${e.key}'] = '${e.value}';
      }
    }

    await client.putBytesAbsolute(
      Uri.parse(urlRaw),
      bytes: bytes,
      headers: headers,
    );
    return signedId;
  }
}
