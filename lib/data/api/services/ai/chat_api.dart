/// `POST /chat/completions` (OpenAI-compatible).
library;

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/features/ai/domain/chat_message.dart';

typedef JsonMap = Map<String, dynamic>;

class ChatApi {
  ChatApi(this._client);

  final ApiClient _client;

  static const _path = '/chat/completions';

  Future<JsonMap> completions({
    required List<ChatMessage> messages,
    double? temperature,
    int? maxTokens,
    bool stream = false,
    JsonMap? responseFormat,
  }) {
    return _client.postJson(
      _path,
      body: {
        'messages': messages.map((m) => m.toJsonBody()).toList(),
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'maxTokens': maxTokens,
        'stream': stream,
        if (responseFormat != null) 'responseFormat': responseFormat,
      },
    );
  }
}
