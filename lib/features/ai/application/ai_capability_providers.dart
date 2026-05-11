import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/api/services/ai/ai_api_providers.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_configs.dart';
import 'package:enjoy_player/features/ai/data/enjoy/enjoy_asr_capability.dart';
import 'package:enjoy_player/features/ai/data/enjoy/enjoy_assessment_capability.dart';
import 'package:enjoy_player/features/ai/data/enjoy/enjoy_dictionary_capability.dart';
import 'package:enjoy_player/features/ai/data/enjoy/enjoy_llm_capability.dart';
import 'package:enjoy_player/features/ai/data/enjoy/enjoy_translation_capability.dart';
import 'package:enjoy_player/features/ai/data/enjoy/enjoy_tts_capability.dart';
import 'package:enjoy_player/features/ai/data/stub_ai_capabilities.dart';
import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/ai/domain/ai_service_config.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/assessment_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/dictionary_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/llm_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/translation_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/tts_capability.dart';

part 'ai_capability_providers.g.dart';

AsrCapability resolveAsrCapability(Ref ref, AIServiceConfig config) {
  switch (config.provider) {
    case AIProvider.enjoy:
      return EnjoyAsrCapability(ref.read(asrApiProvider));
    case AIProvider.byok:
    case AIProvider.local:
      return const UnimplementedAsrCapability();
  }
}

LlmCapability resolveLlmCapability(Ref ref, AIServiceConfig config) {
  switch (config.provider) {
    case AIProvider.enjoy:
      return EnjoyLlmCapability(ref.read(chatApiProvider));
    case AIProvider.byok:
    case AIProvider.local:
      return const UnimplementedLlmCapability();
  }
}

TranslationCapability resolveTranslationCapability(
  Ref ref,
  AIServiceConfig config,
) {
  switch (config.provider) {
    case AIProvider.enjoy:
      return EnjoyTranslationCapability(ref.read(translationApiProvider));
    case AIProvider.byok:
    case AIProvider.local:
      return const UnimplementedTranslationCapability();
  }
}

DictionaryCapability resolveDictionaryCapability(
  Ref ref,
  AIServiceConfig config,
) {
  switch (config.provider) {
    case AIProvider.enjoy:
      return EnjoyDictionaryCapability(ref.read(dictionaryApiProvider));
    case AIProvider.byok:
    case AIProvider.local:
      return const UnimplementedDictionaryCapability();
  }
}

TtsCapability resolveTtsCapability(Ref ref, AIServiceConfig config) {
  switch (config.provider) {
    case AIProvider.enjoy:
      return const EnjoyTtsCapability();
    case AIProvider.byok:
    case AIProvider.local:
      return const UnimplementedTtsCapability();
  }
}

AssessmentCapability resolveAssessmentCapability(
  Ref ref,
  AIServiceConfig config,
) {
  switch (config.provider) {
    case AIProvider.enjoy:
      return const EnjoyAssessmentCapability();
    case AIProvider.byok:
    case AIProvider.local:
      return const UnimplementedAssessmentCapability();
  }
}

@Riverpod(keepAlive: true)
AiModalityConfigs aiModalityConfigs(Ref ref) => AiModalityConfigs.defaults;

@Riverpod(keepAlive: true)
AsrCapability asrCapability(Ref ref) {
  final c = ref.watch(aiModalityConfigsProvider);
  return resolveAsrCapability(ref, c.asr);
}

@Riverpod(keepAlive: true)
LlmCapability llmCapability(Ref ref) {
  final c = ref.watch(aiModalityConfigsProvider);
  return resolveLlmCapability(ref, c.llm);
}

@Riverpod(keepAlive: true)
TranslationCapability translationCapability(Ref ref) {
  final c = ref.watch(aiModalityConfigsProvider);
  return resolveTranslationCapability(ref, c.translation);
}

@Riverpod(keepAlive: true)
DictionaryCapability dictionaryCapability(Ref ref) {
  final c = ref.watch(aiModalityConfigsProvider);
  return resolveDictionaryCapability(ref, c.dictionary);
}

@Riverpod(keepAlive: true)
TtsCapability ttsCapability(Ref ref) {
  final c = ref.watch(aiModalityConfigsProvider);
  return resolveTtsCapability(ref, c.tts);
}

@Riverpod(keepAlive: true)
AssessmentCapability assessmentCapability(Ref ref) {
  final c = ref.watch(aiModalityConfigsProvider);
  return resolveAssessmentCapability(ref, c.assessment);
}
