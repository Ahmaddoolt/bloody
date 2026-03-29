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
    final pendingRequests =
        state.requests.where((request) => request.status == 'pending').toList();
    final activeRequests =
        state.requests.where((request) => request.status == 'high').toList();

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
              : _buildRequestList(
                  context,
                  pendingRequests,
                  activeRequests,
                  ref,
                  colorScheme,
                ),
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
    BuildContext context,
    List<PriorityRequestEntity> pendingRequests,
    List<PriorityRequestEntity> activeRequests,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    final sections = <Widget>[
      if (pendingRequests.isNotEmpty) ...[
        _SectionHeader(title: 'pending_requests_section'.tr()),
        ...pendingRequests.map(
          (request) => _RequestCard(
            request: request,
            onApprove: () async {
              final success =
                  await ref.read(priorityProvider.notifier).approveRequest(
                        request.id,
                      );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'request_approved'.tr() : 'approve_failed'.tr(),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            onReject: () async {
              final success =
                  await ref.read(priorityProvider.notifier).rejectRequest(
                        request.id,
                      );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'request_rejected'.tr() : 'reject_failed'.tr(),
                    ),
                    backgroundColor: success ? Colors.orange : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            onCall:
                request.phone != null ? () => _makeCall(request.phone!) : null,
          ),
        ),
      ],
      if (activeRequests.isNotEmpty) ...[
        const SizedBox(height: 8),
        _SectionHeader(title: 'active_priorities'.tr()),
        ...activeRequests.map(
          (request) => _RequestCard(
            request: request,
            onDisable: () async {
              final success =
                  await ref.read(priorityProvider.notifier).disableRequest(
                        request.id,
                      );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'priority_disabled'.tr()
                          : 'disable_failed'.tr(),
                    ),
                    backgroundColor: success ? Colors.orange : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            onCall:
                request.phone != null ? () => _makeCall(request.phone!) : null,
          ),
        ),
      ],
    ];

    return ListView(
      padding: AppSpacing.page,
      children: sections,
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
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onDisable;
  final VoidCallback? onCall;

  const _RequestCard({
    required this.request,
    this.onApprove,
    this.onReject,
    this.onDisable,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasReason = request.bloodRequestReason != null &&
        request.bloodRequestReason!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + name/phone + call button
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.username ?? 'unknown'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (request.phone != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 13,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              request.phone!,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (onCall != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      tooltip: 'call'.tr(),
                      onPressed: onCall,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Blood type + city chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (request.bloodType != null)
                  _InfoChip(
                    icon: Icons.bloodtype,
                    label: request.bloodType!,
                    color: AppColors.accent,
                  ),
                if (request.city != null)
                  _InfoChip(
                    icon: Icons.location_on,
                    label: request.city!.tr(),
                    color: Colors.blue,
                  ),
                if (request.createdAt != null)
                  _InfoChip(
                    icon: Icons.access_time,
                    label: _formatDate(request.createdAt!),
                    color: Colors.grey,
                  ),
              ],
            ),

            // Situation / reason section
            if (hasReason) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notes_rounded,
                            size: 15,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 6),
                        Text(
                          'blood_request_reason_label'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.55),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      request.bloodRequestReason!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            if (request.status == 'pending')
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              )
            else if (request.status == 'high')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                  label: Text('disable_priority'.tr()),
                  onPressed: onDisable,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    side: const BorderSide(color: Colors.deepOrange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
