/// `POST /chat/completions` (OpenAI-compatible).
library;

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/rest_api.dart';
import 'package:enjoy_player/features/ai/domain/chat_message.dart';

class ChatApi extends RestApi {
  ChatApi(super.client);

  static const _path = '/chat/completions';

  Future<JsonMap> completions({
    required List<ChatMessage> messages,
    double? temperature,
    int? maxTokens,
    bool stream = false,
    JsonMap? responseFormat,
  }) {
    return client.postJson(
      _path,
      body: {
        'messages': messages.map((m) => m.toJsonBody()).toList(),
        'temperature': ?temperature,
        'maxTokens': ?maxTokens,
        'stream': stream,
        'responseFormat': ?responseFormat,
      },
    );
  }
}
