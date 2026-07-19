/// `PUT /audio/media/:media_reference` — Worker DEEPGRAM_ASR upload.
library;

import 'package:enjoy_player/data/api/rest_api.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_constants.dart';

class AsrMediaUploadApi extends RestApi {
  AsrMediaUploadApi(super.client);

  /// Uploads [bytes] and returns the opaque [mediaReference] confirmed by
  /// the Worker (same as requested when the server echoes it).
  Future<({String mediaReference, int byteLength})> upload({
    required String mediaReference,
    required List<int> bytes,
    String contentType = kLongFormDefaultAudioContentType,
  }) async {
    final encoded = Uri.encodeComponent(mediaReference);
    final map = await client.putBytesJson(
      '/audio/media/$encoded',
      bytes: bytes,
      contentType: contentType,
    );
    return (
      mediaReference:
          map['mediaReference'] as String? ??
          map['media_reference'] as String? ??
          mediaReference,
      byteLength:
          (map['byteLength'] as num?)?.toInt() ??
          (map['byte_length'] as num?)?.toInt() ??
          bytes.length,
    );
  }
}
