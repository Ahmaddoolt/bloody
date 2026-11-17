import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../providers/account_verification_provider.dart';

class DonorVerificationScreen extends ConsumerStatefulWidget {
  const DonorVerificationScreen({super.key});

  @override
  ConsumerState<DonorVerificationScreen> createState() =>
      _DonorVerificationScreenState();
}

class _DonorVerificationScreenState
    extends ConsumerState<DonorVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _identityImage;
  XFile? _medicalImage;

  Future<void> _pickIdentity() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (image != null && mounted) {
      setState(() => _identityImage = image);
    }
  }

  Future<void> _pickMedical() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (image != null && mounted) {
      setState(() => _medicalImage = image);
    }
  }

  Future<void> _submit() async {
    final identityImage = _identityImage;
    final medicalImage = _medicalImage;
    if (identityImage == null || medicalImage == null) return;

    final success = await ref.read(donorVerificationProvider.notifier).submit(
          identityImage: identityImage,
          medicalImage: medicalImage,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'verification_submitted'.tr()
              : 'verification_submit_failed'.tr(),
        ),
        backgroundColor: success ? AppColors.accent : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verificationAsync = ref.watch(donorVerificationProvider);
    final isSubmitting = verificationAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text('account_verification'.tr()),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.lg,
            AppSpacing.screenEdge,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              verificationAsync.when(
                loading: () => const SizedBox(
                  height: 44,
                  child: Center(child: AppLoadingIndicator(size: 22)),
                ),
                error: (_, __) => _StatusBanner(
                  icon: Icons.error_outline_rounded,
                  label: 'verification_submit_failed'.tr(),
                  color: Colors.red,
                ),
                data: (request) => _StatusBanner.fromStatus(
                  request?.status ?? 'unverified',
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'account_verification_desc'.tr(),
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              _UploadTile(
                title: 'identity_proof'.tr(),
                subtitle: _identityImage?.name ?? 'upload_identity_proof'.tr(),
                icon: Icons.badge_outlined,
                hasImage: _identityImage != null,
                onTap: isSubmitting ? null : _pickIdentity,
              ),
              const SizedBox(height: 12),
              _UploadTile(
                title: 'medical_proof'.tr(),
                subtitle: _medicalImage?.name ?? 'upload_medical_proof'.tr(),
                icon: Icons.medical_information_outlined,
                hasImage: _medicalImage != null,
                onTap: isSubmitting ? null : _pickMedical,
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: isSubmitting ||
                        _identityImage == null ||
                        _medicalImage == null
                    ? null
                    : _submit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_user_outlined),
                label: Text('submit_verification'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusBanner({
    required this.icon,
    required this.label,
    required this.color,
  });

  factory _StatusBanner.fromStatus(String status) {
    return switch (status) {
      'pending' => _StatusBanner(
          icon: Icons.hourglass_top_rounded,
          label: 'verification_pending'.tr(),
          color: Colors.orange,
        ),
      'approved' || 'verified' => _StatusBanner(
          icon: Icons.verified_rounded,
          label: 'verified_account'.tr(),
          color: const Color(0xFF2E7D32),
        ),
      'rejected' => _StatusBanner(
          icon: Icons.cancel_outlined,
          label: 'verification_rejected'.tr(),
          color: Colors.grey,
        ),
      _ => _StatusBanner(
          icon: Icons.verified_user_outlined,
          label: 'not_verified'.tr(),
          color: Colors.blue,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool hasImage;
  final VoidCallback? onTap;

  const _UploadTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.hasImage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = hasImage ? AppColors.accent : colors.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasImage ? Icons.check_circle_rounded : Icons.upload_rounded,
              color: hasImage ? AppColors.accent : colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
