enum AiChatRole { user, assistant }

class AiChatMessageEntity {
  final AiChatRole role;
  final String text;
  final DateTime createdAt;

  const AiChatMessageEntity({
    required this.role,
    required this.text,
    required this.createdAt,
  });

  Map<String, String> toPayload() {
    return {
      'role': role == AiChatRole.assistant ? 'assistant' : 'user',
      'text': text,
    };
  }
}
