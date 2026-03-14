// file: lib/shared/features/settings/presentation/widgets/priority_request_card.dart
import 'package:bloody/core/widgets/app_loading_indicator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class PriorityRequestCard extends StatelessWidget {
  final String priorityStatus;
  final bool isRequesting;
  final VoidCallback onRequest;

  const PriorityRequestCard({
    super.key,
    required this.priorityStatus,
    required this.isRequesting,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isPending = priorityStatus == 'pending';
    final isApproved = priorityStatus == 'high';
    final isRejected = priorityStatus == 'rejected';

    Color cardColor = Colors.blue;
    IconData cardIcon = Icons.priority_high_rounded;
    String cardTitle = 'request_high_priority'.tr();
    String cardSubtitle = 'request_high_priority_desc'.tr();

    if (isApproved) {
      cardColor = AppTheme.primaryRed;
      cardIcon = Icons.star_rounded;
      cardTitle = 'high_priority_approved'.tr();
      cardSubtitle = 'high_priority_approved_desc'.tr();
    } else if (isPending) {
      cardColor = Colors.orange;
      cardIcon = Icons.hourglass_top_rounded;
      cardTitle = 'request_pending_review'.tr();
      cardSubtitle = 'request_pending_desc'.tr();
    } else if (isRejected) {
      cardColor = Colors.grey;
      cardIcon = Icons.cancel_outlined;
      cardTitle = 'request_rejected'.tr();
      cardSubtitle = 'request_rejected_desc'.tr();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(cardIcon, color: cardColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardTitle,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: cardColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cardSubtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isApproved && !isPending) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isRequesting ? null : onRequest,
                icon: isRequesting
                    ? const AppLoadingIndicator(
                        size: 16,
                        strokeWidth: 2,
                        color: Colors.white,
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(isRequesting
                    ? 'submitting'.tr()
                    : 'request_high_priority'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cardColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
