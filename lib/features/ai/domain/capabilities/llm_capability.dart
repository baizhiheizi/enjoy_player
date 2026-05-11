import 'package:enjoy_player/features/ai/domain/chat_message.dart';

/// Text generation via Enjoy worker (`/chat/completions`).
abstract class LlmCapability {
  Future<String> generateText({
    String? systemPrompt,
    required String userPrompt,
    double? temperature,
    int? maxTokens,
  });

  Future<String> generateChatCompletion({
    required List<ChatMessage> messages,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? responseFormat,
  });
}
