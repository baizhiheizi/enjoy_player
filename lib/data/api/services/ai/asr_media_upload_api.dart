/// `PUT /audio/media/:media_reference` — Worker DEEPGRAM_ASR upload.
library;

import 'dart:io';

import 'package:enjoy_player/data/api/rest_api.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_constants.dart';

class AsrMediaUploadApi extends RestApi {
  AsrMediaUploadApi(super.client);

  /// Uploads [filePath] or [bytes] and returns the opaque [mediaReference]
  /// confirmed by the Worker (same as requested when the server echoes it).
  Future<({String mediaReference, int byteLength})> upload({
    required String mediaReference,
    List<int>? bytes,
    String? filePath,
    String contentType = kLongFormDefaultAudioContentType,
  }) async {
    final encoded = Uri.encodeComponent(mediaReference);
    final hasFile = filePath != null && filePath.isNotEmpty;
    final map = hasFile
        ? await client.putFileJson(
            '/audio/media/$encoded',
            filePath: filePath,
            contentType: contentType,
          )
        : await client.putBytesJson(
            '/audio/media/$encoded',
            bytes: bytes ?? const [],
            contentType: contentType,
          );
    final serverLen =
        (map['byteLength'] as num?)?.toInt() ??
        (map['byte_length'] as num?)?.toInt();
    final fallbackLen =
        serverLen ??
        (hasFile ? await File(filePath).length() : (bytes?.length ?? 0));
    return (
      mediaReference:
          map['mediaReference'] as String? ??
          map['media_reference'] as String? ??
          mediaReference,
      byteLength: fallbackLen,
    );
  }
}
