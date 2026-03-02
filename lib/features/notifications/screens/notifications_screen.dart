// file: lib/features/notifications/screens/notifications_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_loader.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("notifications".tr()),
        centerTitle: true,
        // ✅ FIX: Let Flutter handle the back button automatically.
        // This ensures native behavior (Navigator.pop) works 100% of the time.
        automaticallyImplyLeading: true,
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryRed,
        foregroundColor: Colors.white, // Forces Title and Back Arrow to be White
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('notifications')
            .stream(primaryKey: ['id'])
            .eq('user_id', userId ?? '')
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoader();
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("no_notifications".tr(), style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final note = notifications[index];
              final isRead = note['is_read'] ?? false;
              final type = note['type'];

              IconData icon = Icons.info;
              Color iconColor = Colors.blue;

              if (type == 'low_stock_alert') {
                icon = Icons.bloodtype;
                iconColor = AppTheme.primaryRed;
              } else if (type == 'system') {
                icon = Icons.settings;
                iconColor = Colors.grey;
              }

              return Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: isRead
                        ? Theme.of(context).cardColor
                        : AppTheme.primaryRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: isRead
                        ? Border.all(color: Colors.grey.withOpacity(0.2))
                        : Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: iconColor.withOpacity(0.1),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    title: Text(
                      note['title'] ?? 'Alert',
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          note['body'] ?? '',
                          style: TextStyle(
                              fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          timeago.format(DateTime.parse(note['created_at'])),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    onTap: () async {
                      if (!isRead) {
                        await Supabase.instance.client
                            .from('notifications')
                            .update({'is_read': true}).eq('id', note['id']);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
