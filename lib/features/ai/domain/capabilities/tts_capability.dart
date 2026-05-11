import 'package:enjoy_player/features/ai/domain/models/tts_request.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_result.dart';

/// Text-to-speech (Enjoy path uses Azure Speech SDK on web; Flutter pending).
abstract class TtsCapability {
  Future<TtsResult> synthesize(TtsRequest request);
}
