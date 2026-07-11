import 'package:ai_sdk_anthropic/ai_sdk_anthropic.dart';
import 'package:ai_sdk_google/ai_sdk_google.dart';
import 'package:ai_sdk_openai/ai_sdk_openai.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';

import 'package:enjoy_player/core/validation/byok_http.dart';
import 'package:enjoy_player/features/ai/domain/llm_api_spec.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';

export 'package:enjoy_player/core/validation/byok_http.dart'
    show normalizeByokBaseUrl;

/// Builds an [LanguageModelV3] for BYOK LLM calls from persisted config + key.
LanguageModelV3 createByokLanguageModel({
  required LlmByokConfig config,
  required String apiKey,
}) {
  final baseUrl = normalizeByokBaseUrl(config.baseUrl);
  return switch (config.apiSpec) {
    LlmApiSpec.openAiCompatible => OpenAIProvider(
      apiKey: apiKey,
      baseUrl: baseUrl,
    )(config.model),
    LlmApiSpec.anthropicCompatible => AnthropicProvider(
      apiKey: apiKey,
      baseUrl: baseUrl,
    )(config.model),
    LlmApiSpec.googleCompatible => GoogleGenerativeAIProvider(
      apiKey: apiKey,
      baseUrl: baseUrl,
    )(config.model),
  };
}
