// file: lib/features/admin/screens/admin_priority_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart'; // Import Logger
import '../../../core/widgets/custom_loader.dart';

class AdminPriorityScreen extends StatefulWidget {
  const AdminPriorityScreen({super.key});

  @override
  State<AdminPriorityScreen> createState() => _AdminPriorityScreenState();
}

class _AdminPriorityScreenState extends State<AdminPriorityScreen> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _pendingUsers = [];
  bool _isLoading = true;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  // ── Data Fetching ────────────────────────────────────────────────────────

  Future<void> _fetchPendingRequests() async {
    setState(() => _isLoading = true);
    try {
      AppLogger.info("Fetching pending priority requests...");

      final data = await _supabase
          .from('profiles')
          .select('id, username, email, phone, blood_type, city, priority_status')
          .eq('priority_status', 'pending')
          .order('created_at', ascending: true);

      AppLogger.logData("Pending Requests", data);

      if (mounted) {
        setState(() {
          _pendingUsers = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
        AppLogger.success("Found ${_pendingUsers.length} pending requests.");
      }
    } catch (e, stack) {
      AppLogger.error("AdminPriorityScreen._fetchPendingRequests", e, stack);
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error fetching requests', isError: true);
      }
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _approvePriority(String userId) async {
    await _updatePriorityStatus(userId, newStatus: 'high');
  }

  Future<void> _rejectPriority(String userId) async {
    await _updatePriorityStatus(userId, newStatus: 'rejected');
  }

  Future<void> _updatePriorityStatus(
    String userId, {
    required String newStatus,
  }) async {
    setState(() => _processingIds.add(userId));
    try {
      AppLogger.info("Updating user $userId to status: $newStatus");

      // 1. Update Profile (CRITICAL ACTION)
      await _supabase.from('profiles').update({'priority_status': newStatus}).eq('id', userId);
      AppLogger.success("Profile updated successfully.");

      // 2. Notify User (NON-CRITICAL ACTION)
      // We wrap this in a separate try-catch so if notifications fail (e.g. table missing),
      // the Admin Action still succeeds in the UI.
      try {
        await _supabase.from('notifications').insert({
          'user_id': userId,
          'title': newStatus == 'high' ? 'Priority Approved ✅' : 'Priority Update',
          'body': newStatus == 'high'
              ? 'Your request for high priority status has been approved.'
              : 'Your priority request was not approved.',
          'type': 'system',
          'is_read': false,
        });
        AppLogger.success("Notification sent.");
      } catch (noteError) {
        AppLogger.warning("Could not send notification (Table missing?): $noteError");
      }

      // 3. Update UI
      if (mounted) {
        setState(() {
          _pendingUsers.removeWhere((u) => u['id'] == userId);
          _processingIds.remove(userId);
        });
        final msg = newStatus == 'high' ? 'User approved as high priority ✅' : 'Request rejected ❌';
        _showSnackBar(msg);
      }
    } catch (e, stack) {
      AppLogger.error("AdminPriorityScreen._updatePriorityStatus", e, stack);
      if (mounted) {
        setState(() => _processingIds.remove(userId));
        _showSnackBar('Error updating status: ${e.toString()}', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Priority Requests'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchPendingRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const CustomLoader()
          : RefreshIndicator(
              color: AppTheme.primaryRed,
              onRefresh: _fetchPendingRequests,
              child: _pendingUsers.isEmpty ? _buildEmptyState() : _buildPendingList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Column(
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade300),
            const SizedBox(height: 16),
            const Text(
              'No Pending Requests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'All priority requests have been handled.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPendingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingUsers.length,
      itemBuilder: (context, index) {
        final user = _pendingUsers[index];
        return _PriorityRequestCard(
          user: user,
          isProcessing: _processingIds.contains(user['id']),
          onApprove: () => _approvePriority(user['id']),
          onReject: () => _rejectPriority(user['id']),
        );
      },
    );
  }
}

// ── Sub-Widget ───────────────────────────────────────────────────────────────

class _PriorityRequestCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PriorityRequestCard({
    required this.user,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Extract data with fallbacks
    final bloodType = user['blood_type'] ?? '?';
    final String email = user['email'] ?? 'No Email';

    // ✅ Logic: Prefer username, fallback to email prefix
    final String username = (user['username'] != null && user['username'].toString().isNotEmpty)
        ? user['username']
        : email.split('@')[0];

    final String city = user['city'] ?? 'Unknown City';
    final String? phone = user['phone'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Blood Type Avatar
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    bloodType,
                    style: const TextStyle(
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // User Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // City Row
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            city,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Phone Row
                      GestureDetector(
                        onTap: () => _makeCall(phone),
                        child: Row(
                          children: [
                            Icon(Icons.phone,
                                size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              phone ?? 'No Phone',
                              style: TextStyle(
                                fontSize: 13,
                                color: phone != null
                                    ? Colors.blue
                                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                decoration: phone != null ? TextDecoration.underline : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Pending Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Action Buttons
            isProcessing
                ? const Center(child: CustomLoader(size: 28))
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                          label: const Text(
                            'Reject',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text(
                            'Approve Priority',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
