import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/assessment_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/dictionary_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/llm_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/translation_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/tts_capability.dart';
import 'package:enjoy_player/features/ai/domain/chat_message.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_result.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/ai/domain/models/translation_result.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_request.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_result.dart';

/// BYOK / local AI is not implemented in the player yet.
final class UnimplementedAsrCapability implements AsrCapability {
  const UnimplementedAsrCapability();

  @override
  Future<AsrResult> transcribe(AsrRequest request) {
    throw UnimplementedError(
      'ASR with BYOK or local models is not implemented yet.',
    );
  }
}

final class UnimplementedLlmCapability implements LlmCapability {
  const UnimplementedLlmCapability();

  @override
  Future<String> generateChatCompletion({
    required List<ChatMessage> messages,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? responseFormat,
  }) {
    throw UnimplementedError(
      'LLM with BYOK or local models is not implemented yet.',
    );
  }

  @override
  Future<String> generateText({
    String? systemPrompt,
    required String userPrompt,
    double? temperature,
    int? maxTokens,
  }) {
    throw UnimplementedError(
      'LLM with BYOK or local models is not implemented yet.',
    );
  }
}

final class UnimplementedTranslationCapability implements TranslationCapability {
  const UnimplementedTranslationCapability();

  @override
  Future<TranslationResult> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) {
    throw UnimplementedError(
      'Translation with BYOK or local models is not implemented yet.',
    );
  }
}

final class UnimplementedDictionaryCapability implements DictionaryCapability {
  const UnimplementedDictionaryCapability();

  @override
  Future<DictionaryResult> lookupDictionary({
    required String word,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) {
    throw UnimplementedError(
      'Dictionary with BYOK or local models is not implemented yet.',
    );
  }
}

final class UnimplementedTtsCapability implements TtsCapability {
  const UnimplementedTtsCapability();

  @override
  Future<TtsResult> synthesize(TtsRequest request) {
    throw UnimplementedError(
      'TTS with BYOK or local models is not implemented yet.',
    );
  }
}

final class UnimplementedAssessmentCapability implements AssessmentCapability {
  const UnimplementedAssessmentCapability();

  @override
  Future<AssessmentResult> assess(AssessmentRequest request) {
    throw UnimplementedError(
      'Assessment with BYOK or local models is not implemented yet.',
    );
  }
}
