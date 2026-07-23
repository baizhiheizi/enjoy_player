/// Adapter: [CraftTranscriber] backed by [AsrService].
library;

import 'dart:typed_data';

import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/craft/domain/craft_transcriber.dart';

final class CraftAsrServiceTranscriber implements CraftTranscriber {
  CraftAsrServiceTranscriber(this._asr);

  final AsrService _asr;

  @override
  Future<String> transcribe({
    required Uint8List audioBytes,
    String? language,
  }) async {
    final result = await _asr.transcribe(
      AsrRequest(
        audioBytes: audioBytes,
        filename: 'craft_capture.wav',
        mimeType: 'audio/wav',
        language: language,
      ),
    );
    return result.text;
  }
}
