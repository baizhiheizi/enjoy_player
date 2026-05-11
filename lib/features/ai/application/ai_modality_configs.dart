import 'package:flutter/foundation.dart';

import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/ai/domain/ai_service_config.dart';

/// Per-modality [AIServiceConfig]. Replace via [AiModalityConfigs] override later.
@immutable
final class AiModalityConfigs {
  const AiModalityConfigs({
    required this.asr,
    required this.tts,
    required this.llm,
    required this.translation,
    required this.dictionary,
    required this.assessment,
  });

  static const AiModalityConfigs defaults = AiModalityConfigs(
    asr: AIServiceConfig(provider: AIProvider.enjoy),
    tts: AIServiceConfig(provider: AIProvider.enjoy),
    llm: AIServiceConfig(provider: AIProvider.enjoy),
    translation: AIServiceConfig(provider: AIProvider.enjoy),
    dictionary: AIServiceConfig(provider: AIProvider.enjoy),
    assessment: AIServiceConfig(provider: AIProvider.enjoy),
  );

  final AIServiceConfig asr;
  final AIServiceConfig tts;
  final AIServiceConfig llm;
  final AIServiceConfig translation;
  final AIServiceConfig dictionary;
  final AIServiceConfig assessment;
}
