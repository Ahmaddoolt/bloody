import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/moderated_user_entity.dart';
import '../providers/account_moderation_provider.dart';

class AccountModerationScreen extends ConsumerStatefulWidget {
  const AccountModerationScreen({super.key});

  @override
  ConsumerState<AccountModerationScreen> createState() =>
      _AccountModerationScreenState();
}

class _AccountModerationScreenState
    extends ConsumerState<AccountModerationScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    await ref
        .read(accountModerationProvider.notifier)
        .fetch(query: _searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(accountModerationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('user_moderation'.tr()),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.page.copyWith(bottom: 8),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'search_users'.tr(),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: _search,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                ),
              ),
            ),
            Expanded(
              child: usersAsync.when(
                loading: () => const AppLoadingCenter(),
                error: (_, __) => Center(child: Text('error_loading'.tr())),
                data: (users) {
                  if (users.isEmpty) {
                    return Center(child: Text('no_users_found'.tr()));
                  }

                  return RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: () =>
                        ref.read(accountModerationProvider.notifier).fetch(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return _UserModerationCard(user: users[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserModerationCard extends ConsumerWidget {
  final ModeratedUserEntity user;

  const _UserModerationCard({required this.user});

  Future<void> _ban(BuildContext context, WidgetRef ref) async {
    final reason = await _askBanReason(context);
    if (reason == null || !context.mounted) return;

    final success = await ref.read(accountModerationProvider.notifier).ban(
          userId: user.id,
          reason: reason,
        );
    if (!context.mounted) return;
    _showResult(context, success, 'account_banned'.tr());
  }

  Future<void> _unban(BuildContext context, WidgetRef ref) async {
    final success =
        await ref.read(accountModerationProvider.notifier).unban(user.id);
    if (!context.mounted) return;
    _showResult(context, success, 'account_unbanned'.tr());
  }

  Future<String?> _askBanReason(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ban_reason'.tr()),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: 'ban_reason_hint'.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('ban_account'.tr()),
          ),
        ],
      ),
    );
  }

  void _showResult(BuildContext context, bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? message : 'error_loading'.tr()),
        backgroundColor: success ? AppColors.accent : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final title = user.username.isNotEmpty ? user.username : user.email;
    final statusColor = user.isForbidden ? Colors.red : const Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.12),
            child: Icon(
              user.isForbidden
                  ? Icons.block_rounded
                  : Icons.person_outline_rounded,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    user.email,
                    user.userType,
                    user.bloodType,
                    user.city?.tr(),
                  ].whereType<String>().join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
                if (user.forbiddenReason?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.forbiddenReason!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.red.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: user.isForbidden
                ? () => _unban(context, ref)
                : () => _ban(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: user.isForbidden ? Colors.green : Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
                user.isForbidden ? 'unban_account'.tr() : 'ban_account'.tr()),
          ),
        ],
      ),
    );
  }
}
