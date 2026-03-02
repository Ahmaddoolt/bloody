// file: lib/shared/features/settings/presentation/widgets/priority_request_card.dart
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
    String cardTitle = 'Request High Priority';
    String cardSubtitle =
        'If you urgently need blood, request high-priority status for faster assistance.';

    if (isApproved) {
      cardColor = AppTheme.primaryRed;
      cardIcon = Icons.star_rounded;
      cardTitle = 'High Priority Approved ⭐';
      cardSubtitle = 'You have been granted high priority status by an admin.';
    } else if (isPending) {
      cardColor = Colors.orange;
      cardIcon = Icons.hourglass_top_rounded;
      cardTitle = 'Request Pending Review';
      cardSubtitle = 'Your priority request is awaiting admin approval.';
    } else if (isRejected) {
      cardColor = Colors.grey;
      cardIcon = Icons.cancel_outlined;
      cardTitle = 'Request Rejected';
      cardSubtitle = 'Your previous request was rejected. You may submit a new one.';
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cardColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cardSubtitle,
                      style: TextStyle(
                          fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700]),
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
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(isRequesting ? 'Submitting...' : 'Request High Priority'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cardColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
