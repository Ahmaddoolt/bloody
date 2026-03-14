import 'package:bloody/core/theme/app_colors.dart';
import 'package:bloody/core/theme/app_spacing.dart';
import 'package:bloody/core/widgets/app_loading_indicator.dart';
import 'package:bloody/features/admin/priority_mgmt/domain/entities/priority_request_entity.dart';
import 'package:bloody/features/admin/priority_mgmt/presentation/providers/priority_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminPriorityScreen extends ConsumerWidget {
  const AdminPriorityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(priorityProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('priority_requests'.tr()),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(priorityProvider.notifier).fetchPendingRequests(),
          ),
        ],
      ),
      body: state.isLoading
          ? const AppLoadingCenter()
          : state.requests.isEmpty
              ? _buildEmptyState(colorScheme)
              : _buildRequestList(state.requests, ref, colorScheme),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'no_pending_requests'.tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'all_requests_processed'.tr(),
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(
    List<PriorityRequestEntity> requests,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      padding: AppSpacing.page,
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _RequestCard(
          request: request,
          onApprove: () async {
            final success = await ref
                .read(priorityProvider.notifier)
                .approveRequest(request.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'request_approved'.tr()
                      : 'approve_failed'.tr()),
                  backgroundColor: success ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          onReject: () async {
            final success = await ref
                .read(priorityProvider.notifier)
                .rejectRequest(request.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      success ? 'request_rejected'.tr() : 'reject_failed'.tr()),
                  backgroundColor: success ? Colors.orange : Colors.red,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          onCall:
              request.phone != null ? () => _makeCall(request.phone!) : null,
        );
      },
    );
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _RequestCard extends StatelessWidget {
  final PriorityRequestEntity request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onCall;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.username ?? 'Unknown',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      if (request.phone != null)
                        Text(
                          request.phone!,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                if (onCall != null)
                  IconButton(
                    icon: const Icon(Icons.phone),
                    onPressed: onCall,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bloodtype, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  if (request.bloodType != null)
                    Text(
                      request.bloodType!,
                      style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500),
                    ),
                  if (request.city != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.location_on,
                        size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      request.city!,
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: Text('reject'.tr()),
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: Text('approve'.tr()),
                    onPressed: onApprove,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
