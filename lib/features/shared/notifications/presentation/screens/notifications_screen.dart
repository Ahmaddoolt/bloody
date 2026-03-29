// file: lib/shared/features/notifications/presentation/screens/notifications_screen.dart
import 'package:bloody/core/theme/app_colors.dart';
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
  final ScrollController _scrollController = ScrollController();

  late final String? _userId;

  static const int _pageSize = 20;

  final List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser?.id;
    _scrollController.addListener(_onScroll);
    if (_userId != null) _loadPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    if (_isLoadingMore || !_hasMore || _userId == null) return;

    setState(() => _isLoadingMore = true);

    final page = await _service.fetchNotifications(
      _userId!,
      offset: _offset,
      limit: _pageSize,
    );

    if (!mounted) return;

    setState(() {
      _notifications.addAll(page);
      _offset += page.length;
      _hasMore = page.length == _pageSize;
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _notifications.clear();
      _offset = 0;
      _hasMore = true;
      _isLoading = true;
    });
    await _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('notifications'.tr()),
        centerTitle: true,
      ),
      body: _userId == null
          ? Center(child: Text('not_logged_in'.tr()))
          : _isLoading
              ? const Center(child: AppLoadingIndicator())
              : _notifications.isEmpty
                  ? _buildEmptyState(colors)
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == _notifications.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: AppLoadingIndicator()),
                            );
                          }
                          return _buildNotificationCard(
                            _notifications[index],
                            colors,
                          );
                        },
                      ),
                    ),
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

    IconData icon;
    Color iconColor;

    if (type == 'low_stock_alert') {
      icon = Icons.bloodtype;
      iconColor = const Color(0xFFE53935);
    } else if (type == 'system') {
      icon = Icons.info;
      iconColor = const Color(0xFF1976D2);
    } else {
      icon = Icons.notifications;
      iconColor = AppColors.accent;
    }

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
              final idx = _notifications.indexWhere(
                (n) => n['id'] == note['id'],
              );
              if (idx != -1 && mounted) {
                setState(() => _notifications[idx] = {
                      ..._notifications[idx],
                      'is_read': true,
                    });
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        note['title']?.toString().isNotEmpty == true
                            ? note['title'].toString().tr()
                            : 'notification'.tr(),
                        style: TextStyle(
                          fontWeight:
                              isRead ? FontWeight.w500 : FontWeight.w600,
                          fontSize: 15,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note['body']?.toString().tr() ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeago.format(
                          DateTime.parse(note['created_at']),
                          locale: context.locale.languageCode,
                        ),
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
