import 'package:enjoy_player/features/ai/domain/capabilities/tts_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_request.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_result.dart';

/// Enjoy TTS uses Azure Speech in the web stack; Flutter has no SDK wiring yet.
final class EnjoyTtsCapability implements TtsCapability {
  const EnjoyTtsCapability();

  @override
  Future<TtsResult> synthesize(TtsRequest request) {
    throw UnimplementedError(
      'Enjoy TTS requires Azure Speech integration (see ADR-0014).',
    );
  }
}
