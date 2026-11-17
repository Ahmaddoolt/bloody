import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/account_verification_request_entity.dart';
import '../providers/account_verification_provider.dart';

class AdminVerificationScreen extends ConsumerWidget {
  const AdminVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(adminVerificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('verification_requests'.tr()),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(adminVerificationProvider.notifier).fetch(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: requestsAsync.when(
          loading: () => const AppLoadingCenter(),
          error: (_, __) => Center(child: Text('error_loading_data'.tr())),
          data: (requests) {
            if (requests.isEmpty) {
              return Center(child: Text('no_verification_requests'.tr()));
            }

            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(adminVerificationProvider.notifier).fetch(),
              color: AppColors.accent,
              child: ListView.builder(
                padding: AppSpacing.page,
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  return _VerificationRequestCard(request: requests[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VerificationRequestCard extends ConsumerWidget {
  final AccountVerificationRequestEntity request;

  const _VerificationRequestCard({required this.request});

  Future<void> _openDocument(WidgetRef ref, String path) async {
    final url =
        await ref.read(adminVerificationProvider.notifier).signedUrl(path);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref, {
    required bool approved,
  }) async {
    final note = approved ? null : await _askForNote(context);
    if (!context.mounted) return;
    if (!approved && note == null) return;

    final success = await ref.read(adminVerificationProvider.notifier).review(
          request: request,
          approved: approved,
          note: note,
        );
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? (approved ? 'request_approved'.tr() : 'request_rejected'.tr())
            : 'error_loading'.tr()),
        backgroundColor: success ? AppColors.accent : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<String?> _askForNote(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('review_note'.tr()),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: 'review_note'.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('reject'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                child: const Icon(Icons.person, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.username ?? request.email ?? 'donor'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      [
                        request.bloodType,
                        request.city?.tr(),
                        request.phone,
                      ].whereType<String>().join(' • '),
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openDocument(
                    ref,
                    request.identityDocumentPath,
                  ),
                  icon: const Icon(Icons.badge_outlined, size: 18),
                  label: Text('identity_proof'.tr()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openDocument(
                    ref,
                    request.medicalDocumentPath,
                  ),
                  icon:
                      const Icon(Icons.medical_information_outlined, size: 18),
                  label: Text('medical_proof'.tr()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _review(context, ref, approved: false),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text('reject_verification'.tr()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _review(context, ref, approved: true),
                  icon: const Icon(Icons.verified_rounded, size: 18),
                  label: Text('approve_verification'.tr()),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
