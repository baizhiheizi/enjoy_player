/// Adapter: [CraftSynthesizer] backed by [TtsService].
library;

import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_request.dart';
import 'package:enjoy_player/features/craft/domain/craft_synthesizer.dart';

final class CraftTtsServiceSynthesizer implements CraftSynthesizer {
  CraftTtsServiceSynthesizer(this._tts);

  final TtsService _tts;

  @override
  Future<CraftSynthesisResult> synthesize({
    required String text,
    required String language,
    String? voice,
  }) async {
    final result = await _tts.synthesize(
      TtsRequest(text: text, language: language, voice: voice),
    );
    return CraftSynthesisResult(
      audioBytes: result.audioBytes!,
      format: result.format ?? 'wav',
      wordBoundaries: result.wordBoundaries
          .map(
            (w) => CraftWordBoundary(
              text: w.text,
              audioOffsetMs: w.audioOffsetMs,
              durationMs: w.durationMs,
            ),
          )
          .toList(),
    );
  }
}
