import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/features/ai/application/ai_api_failures.dart';
import 'package:enjoy_player/features/ai/application/ai_capability_providers.dart';
import 'package:enjoy_player/features/ai/domain/chat_message.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_result.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/ai/domain/models/translation_result.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_request.dart';
import 'package:enjoy_player/features/ai/domain/models/tts_result.dart';

part 'ai_services.g.dart';

final class AsrService {
  AsrService(this._ref);

  final Ref _ref;

  Future<AsrResult> transcribe(AsrRequest request) async {
    try {
      return await _ref.read(asrCapabilityProvider).transcribe(request);
    } on ApiException catch (e) {
      throw mapApiExceptionToAppFailure(e);
    }
  }
}

final class ChatService {
  ChatService(this._ref);

  final Ref _ref;

  Future<String> complete({
    required List<ChatMessage> messages,
    double? temperature,
    int? maxTokens,
  }) async {
    try {
      return await _ref.read(llmCapabilityProvider).generateChatCompletion(
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    } on ApiException catch (e) {
      throw mapApiExceptionToAppFailure(e);
    }
  }
}

final class TranslationService {
  TranslationService(this._ref);

  final Ref _ref;

  Future<TranslationResult> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) async {
    try {
      return await _ref.read(translationCapabilityProvider).translate(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        forceRefresh: forceRefresh,
      );
    } on ApiException catch (e) {
      throw mapApiExceptionToAppFailure(e);
    }
  }
}

final class DictionaryService {
  DictionaryService(this._ref);

  final Ref _ref;

  Future<DictionaryResult> lookup({
    required String word,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) async {
    try {
      return await _ref.read(dictionaryCapabilityProvider).lookupDictionary(
        word: word,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        forceRefresh: forceRefresh,
      );
    } on ApiException catch (e) {
      throw mapApiExceptionToAppFailure(e);
    }
  }
}

final class TtsService {
  TtsService(this._ref);

  final Ref _ref;

  Future<TtsResult> synthesize(TtsRequest request) async {
    try {
      return await _ref.read(ttsCapabilityProvider).synthesize(request);
    } on ApiException catch (e) {
      throw mapApiExceptionToAppFailure(e);
    }
  }
}

final class AssessmentService {
  AssessmentService(this._ref);

  final Ref _ref;

  Future<AssessmentResult> assess(AssessmentRequest request) async {
    try {
      return await _ref.read(assessmentCapabilityProvider).assess(request);
    } on ApiException catch (e) {
      throw mapApiExceptionToAppFailure(e);
    }
  }
}

@Riverpod(keepAlive: true)
AsrService asrService(Ref ref) => AsrService(ref);

@Riverpod(keepAlive: true)
ChatService chatService(Ref ref) => ChatService(ref);

@Riverpod(keepAlive: true)
TranslationService translationService(Ref ref) => TranslationService(ref);

@Riverpod(keepAlive: true)
DictionaryService dictionaryService(Ref ref) => DictionaryService(ref);

@Riverpod(keepAlive: true)
TtsService ttsService(Ref ref) => TtsService(ref);

@Riverpod(keepAlive: true)
AssessmentService assessmentService(Ref ref) => AssessmentService(ref);
