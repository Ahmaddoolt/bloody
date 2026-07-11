import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/blood_utils.dart';

class ReceiverDetailSheet extends StatelessWidget {
  final Map<String, dynamic> receiver;
  final VoidCallback? onCall;

  const ReceiverDetailSheet({
    super.key,
    required this.receiver,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = receiver['username']?.toString().trim().isNotEmpty == true
        ? receiver['username'].toString()
        : 'receiver'.tr();
    final bloodType = receiver['blood_type']?.toString() ?? '?';
    final city = receiver['city']?.toString();
    final age = BloodUtils.calculateAge(receiver['birth_date']);
    final situation = receiver['blood_request_reason']?.toString().trim();
    final priorityStatus = receiver['priority_status']?.toString();
    final hasPhone = receiver['phone']?.toString().trim().isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _BloodBadge(bloodType: bloodType),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (city != null && city.isNotEmpty)
                              _InfoChip(
                                icon: Icons.location_on_outlined,
                                label: city.tr(),
                              ),
                            if (age > 0)
                              _InfoChip(
                                icon: Icons.cake_outlined,
                                label: '$age ${'years_old'.tr()}',
                              ),
                            if (priorityStatus == 'high')
                              _InfoChip(
                                icon: Icons.star_rounded,
                                label: 'high_priority'.tr(),
                                color: const Color(0xFFE65100),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'receiver_situation'.tr(),
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  situation?.isNotEmpty == true
                      ? situation!
                      : 'no_situation_added'.tr(),
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.78),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text('close'.tr()),
                    ),
                  ),
                  if (hasPhone) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onCall,
                        icon: const Icon(Icons.phone_rounded, size: 18),
                        label: Text('call'.tr()),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BloodBadge extends StatelessWidget {
  final String bloodType;

  const _BloodBadge({required this.bloodType});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accentDark, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        bloodType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chipColor = color ?? colors.onSurface.withValues(alpha: 0.62);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

void showReceiverDetailSheet(
  BuildContext context, {
  required Map<String, dynamic> receiver,
  VoidCallback? onCall,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ReceiverDetailSheet(
      receiver: receiver,
      onCall: onCall,
    ),
  );
}
