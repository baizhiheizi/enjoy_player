import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/services/ai/chat_api.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/llm_capability.dart';
import 'package:enjoy_player/features/ai/domain/chat_message.dart';

final class EnjoyLlmCapability implements LlmCapability {
  EnjoyLlmCapability(this._api);

  final ChatApi _api;

  String _contentFromResponse(Map<String, dynamic> map) {
    final choicesRaw = map['choices'];
    if (choicesRaw is! List || choicesRaw.isEmpty) {
      throw const ApiException(
        message: 'No choices in chat completion',
        statusCode: 502,
      );
    }
    final first = castJsonObjectOrNull(choicesRaw.first);
    if (first == null) {
      throw const ApiException(
        message: 'No choices in chat completion',
        statusCode: 502,
      );
    }
    final message = castJsonObjectOrNull(first['message']);
    if (message == null) {
      throw const ApiException(
        message: 'No message in completion choice',
        statusCode: 502,
      );
    }
    final content = message['content'];
    final String? text = switch (content) {
      final String s => s.trim().isEmpty ? null : s.trim(),
      _ => null,
    };
    if (text == null || text.isEmpty) {
      throw const ApiException(
        message: 'Empty completion content',
        statusCode: 502,
      );
    }
    return text;
  }

  @override
  Future<String> generateText({
    String? systemPrompt,
    required String userPrompt,
    double? temperature,
    int? maxTokens,
  }) {
    final messages = <ChatMessage>[
      if (systemPrompt != null && systemPrompt.isNotEmpty)
        ChatMessage(role: ChatMessage.roleSystem, content: systemPrompt),
      ChatMessage(role: ChatMessage.roleUser, content: userPrompt),
    ];
    return generateChatCompletion(
      messages: messages,
      temperature: temperature ?? 0.7,
      maxTokens: maxTokens ?? 2048,
    );
  }

  @override
  Future<String> generateChatCompletion({
    required List<ChatMessage> messages,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? responseFormat,
  }) async {
    final map = await _api.completions(
      messages: messages,
      temperature: temperature ?? 0.7,
      maxTokens: maxTokens ?? 2048,
      stream: false,
      responseFormat: responseFormat,
    );
    return _contentFromResponse(map);
  }
}
