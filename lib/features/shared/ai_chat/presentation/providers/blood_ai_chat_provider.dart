import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/utils/app_logger.dart';
import '../../domain/entities/ai_chat_message_entity.dart';

class BloodAiChatState {
  final List<AiChatMessageEntity> messages;
  final bool isSending;
  final String? errorKey;

  const BloodAiChatState({
    this.messages = const [],
    this.isSending = false,
    this.errorKey,
  });

  BloodAiChatState copyWith({
    List<AiChatMessageEntity>? messages,
    bool? isSending,
    String? errorKey,
    bool clearError = false,
  }) {
    return BloodAiChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
    );
  }
}

final bloodAiChatProvider =
    StateNotifierProvider<BloodAiChatNotifier, BloodAiChatState>((ref) {
  return BloodAiChatNotifier(Supabase.instance.client);
});

class BloodAiChatNotifier extends StateNotifier<BloodAiChatState> {
  final SupabaseClient _supabase;

  BloodAiChatNotifier(this._supabase) : super(const BloodAiChatState());

  Future<void> send({
    required String message,
    required String locale,
    required String refusalText,
  }) async {
    final text = message.trim();
    if (text.isEmpty || state.isSending) return;

    final userMessage = AiChatMessageEntity(
      role: AiChatRole.user,
      text: text,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
      clearError: true,
    );

    if (!_isBloodHealthTopic(text)) {
      _appendAssistant(refusalText);
      return;
    }

    try {
      final response = await _supabase.functions.invoke(
        'blood-health-chat',
        body: {
          'message': text,
          'locale': locale,
          'history':
              state.messages.map((message) => message.toPayload()).toList(),
        },
      );

      final data = response.data as Map<String, dynamic>?;
      final answer = data?['answer']?.toString();
      final allowed = data?['allowed'] == true;

      _appendAssistant(
        allowed && answer?.isNotEmpty == true ? answer! : refusalText,
      );
    } catch (e, st) {
      AppLogger.error('BloodAiChatNotifier.send', e, st);
      state = state.copyWith(isSending: false, errorKey: 'ai_error');
      _appendAssistant(refusalText);
    }
  }

  void clear() {
    state = const BloodAiChatState();
  }

  void _appendAssistant(String text) {
    final assistantMessage = AiChatMessageEntity(
      role: AiChatRole.assistant,
      text: text,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, assistantMessage],
      isSending: false,
    );
  }

  bool _isBloodHealthTopic(String message) {
    final normalized = message.toLowerCase();
    const terms = [
      'blood',
      'donat',
      'donor',
      'hemoglobin',
      'cbc',
      'anemia',
      'iron',
      'hepatitis',
      'hiv',
      'syphilis',
      'platelet',
      'plasma',
      'دم',
      'تبرع',
      'متبرع',
      'هيموغلوبين',
      'فقر',
      'حديد',
      'التهاب الكبد',
      'صفائح',
      'بلازما',
    ];
    return terms.any(normalized.contains);
  }
}
