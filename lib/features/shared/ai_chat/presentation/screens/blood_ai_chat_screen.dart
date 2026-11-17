import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/ai_chat_message_entity.dart';
import '../providers/blood_ai_chat_provider.dart';

class BloodAiChatScreen extends ConsumerStatefulWidget {
  const BloodAiChatScreen({super.key});

  @override
  ConsumerState<BloodAiChatScreen> createState() => _BloodAiChatScreenState();
}

class _BloodAiChatScreenState extends ConsumerState<BloodAiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    _controller.clear();
    await ref.read(bloodAiChatProvider.notifier).send(
          message: text,
          locale: context.locale.languageCode,
          refusalText: 'ai_refusal'.tr(),
        );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bloodAiChatProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('ai_health_assistant'.tr()),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => ref.read(bloodAiChatProvider.notifier).clear(),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: state.messages.isEmpty
                  ? _EmptyChat()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        return _MessageBubble(message: state.messages[index]);
                      },
                    ),
            ),
            if (state.isSending)
              const LinearProgressIndicator(color: AppColors.accent),
            _Composer(
              controller: _controller,
              enabled: !state.isSending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.health_and_safety_outlined,
                color: AppColors.accent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ask_blood_question'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ai_health_assistant_desc'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.58),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AiChatMessageEntity message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiChatRole.user;
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accent : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : colors.onSurface,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => enabled ? onSend() : null,
              decoration: InputDecoration(
                hintText: 'type_message'.tr(),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: FilledButton(
              onPressed: enabled ? onSend : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
