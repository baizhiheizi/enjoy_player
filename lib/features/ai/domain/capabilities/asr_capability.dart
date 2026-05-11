import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';

/// Automatic speech recognition (Whisper on Enjoy worker).
abstract class AsrCapability {
  Future<AsrResult> transcribe(AsrRequest request);
}
