// file: lib/shared/features/notifications/presentation/screens/notifications_screen.dart
import 'package:bloody/core/theme/app_colors.dart';
import 'package:bloody/core/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../data/notifications_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final NotificationsService _service = NotificationsService();
  late final String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser?.id;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _userId == null
          ? Center(child: Text("not_logged_in".tr()))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getNotificationsStream(_userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoadingIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(colors);
                }

                final notifications = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(
                      notifications[index],
                      colors,
                    );
                  },
                );
              },
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('notifications'.tr()),
      centerTitle: true,
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off,
              size: 40,
              color: colors.onSurface.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'no_notifications'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> note,
    ColorScheme colors,
  ) {
    final isRead = note['is_read'] ?? false;
    final type = note['type'];

    // Determine icon and color based on type
    IconData icon;
    Color iconColor;

    if (type == 'low_stock_alert') {
      icon = Icons.bloodtype;
      iconColor = const Color(0xFFE53935); // Red for blood
    } else if (type == 'system') {
      icon = Icons.info;
      iconColor = const Color(0xFF1976D2); // Blue for info
    } else {
      icon = Icons.notifications;
      iconColor = AppColors.accent;
    }

    // Use grey for read notifications
    final effectiveColor =
        isRead ? colors.onSurface.withOpacity(0.4) : iconColor;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead
              ? colors.outline.withOpacity(0.1)
              : effectiveColor.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (!isRead) {
              await _service.markAsRead(note['id'].toString());
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: effectiveColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: effectiveColor, size: 20),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        note['title'] ?? 'notification'.tr(),
                        style: TextStyle(
                          fontWeight:
                              isRead ? FontWeight.w500 : FontWeight.w600,
                          fontSize: 15,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note['body'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeago.format(DateTime.parse(note['created_at'])),
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
