// file: lib/features/priority/widgets/priority_request_button.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart'; // ✅ IMPORTED LOGGER
import '../../../core/widgets/custom_loader.dart';

class PriorityRequestButton extends StatefulWidget {
  const PriorityRequestButton({super.key});

  @override
  State<PriorityRequestButton> createState() => _PriorityRequestButtonState();
}

class _PriorityRequestButtonState extends State<PriorityRequestButton> {
  final _supabase = Supabase.instance.client;

  String _priorityStatus = 'none';
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data =
          await _supabase.from('profiles').select('priority_status').eq('id', userId).single();

      if (mounted) {
        setState(() {
          _priorityStatus = (data['priority_status'] as String?) ?? 'none';
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      // Log generic fetch error
      AppLogger.error("PriorityRequestButton._fetchStatus", e, stack);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRequest() async {
    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    setState(() => _isSubmitting = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      AppLogger.info("Button requesting priority for $userId");

      await _supabase.from('profiles').update({'priority_status': 'pending'}).eq('id', userId);

      if (mounted) {
        setState(() {
          _priorityStatus = 'pending';
          _isSubmitting = false;
        });
        AppLogger.success("Request Submitted Successfully");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('priority_request_submitted'.tr()),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e, stack) {
      // 🔴 COLORFUL LOGGING
      AppLogger.error("PriorityRequestButton._submitRequest", e, stack);

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_saving'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.priority_high_rounded, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'request_priority_title'.tr(),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Text(
              'request_priority_body'.tr(),
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('cancel'.tr(), style: const TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('confirm'.tr()),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 56,
        child: Center(child: CustomLoader(size: 24)),
      );
    }

    return _PriorityStatusCard(
      status: _priorityStatus,
      isSubmitting: _isSubmitting,
      onRequest: _submitRequest,
    );
  }
}

class _PriorityStatusCard extends StatelessWidget {
  final String status;
  final bool isSubmitting;
  final VoidCallback onRequest;

  const _PriorityStatusCard({
    required this.status,
    required this.isSubmitting,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final _StatusConfig cfg = _resolveConfig(status, isDark);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cfg.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cfg.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cfg.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cfg.iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(cfg.icon, color: cfg.iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cfg.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cfg.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (status == 'none' || status == 'rejected') ...[
            const SizedBox(width: 8),
            isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                  )
                : ElevatedButton(
                    onPressed: onRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'request'.tr(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cfg.badgeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cfg.badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StatusConfig _resolveConfig(String status, bool isDark) {
    switch (status) {
      case 'pending':
        return _StatusConfig(
          title: 'Priority Request Pending',
          subtitle: 'An admin is reviewing your request.',
          icon: Icons.hourglass_top_rounded,
          iconColor: Colors.orange,
          iconBackground: Colors.orange.withOpacity(0.12),
          background: isDark ? Colors.orange.withOpacity(0.08) : Colors.orange.shade50,
          borderColor: Colors.orange.withOpacity(0.3),
          shadowColor: Colors.orange,
          badgeColor: Colors.orange,
          badge: 'PENDING',
        );
      case 'high':
        return _StatusConfig(
          title: 'High Priority Active',
          subtitle: 'You are marked as a high-priority recipient.',
          icon: Icons.verified_rounded,
          iconColor: Colors.green,
          iconBackground: Colors.green.withOpacity(0.12),
          background: isDark ? Colors.green.withOpacity(0.08) : Colors.green.shade50,
          borderColor: Colors.green.withOpacity(0.3),
          shadowColor: Colors.green,
          badgeColor: Colors.green,
          badge: 'ACTIVE',
        );
      case 'rejected':
        return _StatusConfig(
          title: 'Request Rejected',
          subtitle: 'Your request was not approved. You may request again.',
          icon: Icons.cancel_outlined,
          iconColor: Colors.red,
          iconBackground: Colors.red.withOpacity(0.12),
          background: isDark ? Colors.red.withOpacity(0.06) : Colors.red.shade50,
          borderColor: Colors.red.withOpacity(0.25),
          shadowColor: Colors.red,
          badgeColor: Colors.red,
          badge: 'REJECTED',
        );
      default:
        return _StatusConfig(
          title: 'Request High Priority',
          subtitle: 'Are you in urgent need? Request priority status to appear at the top.',
          icon: Icons.priority_high_rounded,
          iconColor: AppTheme.primaryRed,
          iconBackground: AppTheme.primaryRed.withOpacity(0.1),
          background: isDark
              ? AppTheme.primaryRed.withOpacity(0.06)
              : AppTheme.primaryRed.withOpacity(0.04),
          borderColor: AppTheme.primaryRed.withOpacity(0.2),
          shadowColor: AppTheme.primaryRed,
          badgeColor: Colors.grey,
          badge: '',
        );
    }
  }
}

class _StatusConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color background;
  final Color borderColor;
  final Color shadowColor;
  final Color badgeColor;
  final String badge;

  const _StatusConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.background,
    required this.borderColor,
    required this.shadowColor,
    required this.badgeColor,
    required this.badge,
  });
}
