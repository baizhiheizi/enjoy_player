/// OpenAI-style chat message for `/chat/completions`.
final class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  static const String roleSystem = 'system';
  static const String roleUser = 'user';
  static const String roleAssistant = 'assistant';

  Map<String, dynamic> toJsonBody() => {'role': role, 'content': content};
}
