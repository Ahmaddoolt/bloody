// file: lib/actors/admin/features/priority_mgmt/presentation/screens/admin_priority_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/app_logger.dart';
import '../../../../../../core/widgets/custom_loader.dart';
import '../data/priority_service.dart'; // ✅ Import the new Data Service

class AdminPriorityScreen extends StatefulWidget {
  const AdminPriorityScreen({super.key});

  @override
  State<AdminPriorityScreen> createState() => _AdminPriorityScreenState();
}

class _AdminPriorityScreenState extends State<AdminPriorityScreen> {
  // ✅ CLEAN ARCHITECTURE: Instantiate the service
  final PriorityService _priorityService = PriorityService();

  List<Map<String, dynamic>> _pendingUsers = [];
  bool _isLoading = true;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  // ── Data Fetching ────────────────────────────────────────────────────────

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoading = true);
    try {
      final users = await _priorityService.fetchPendingRequests();

      if (mounted) {
        setState(() {
          _pendingUsers = users;
          _isLoading = false;
        });
        AppLogger.success("Found ${_pendingUsers.length} pending requests.");
      }
    } catch (e, stack) {
      AppLogger.error("AdminPriorityScreen._loadPendingRequests", e, stack);
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error fetching requests', isError: true);
      }
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _handlePriorityUpdate(String userId, String newStatus) async {
    setState(() => _processingIds.add(userId));
    try {
      // ✅ Call Data Service
      await _priorityService.updatePriorityStatus(userId, newStatus);

      // Update UI
      if (mounted) {
        setState(() {
          _pendingUsers.removeWhere((u) => u['id'] == userId);
          _processingIds.remove(userId);
        });
        final msg = newStatus == 'high' ? 'User approved as high priority ✅' : 'Request rejected ❌';
        _showSnackBar(msg);
      }
    } catch (e, stack) {
      AppLogger.error("AdminPriorityScreen._handlePriorityUpdate", e, stack);
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
            onPressed: _loadPendingRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const CustomLoader()
          : RefreshIndicator(
              color: AppTheme.primaryRed,
              onRefresh: _loadPendingRequests,
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
          onApprove: () => _handlePriorityUpdate(user['id'], 'high'),
          onReject: () => _handlePriorityUpdate(user['id'], 'rejected'),
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

    final bloodType = user['blood_type'] ?? '?';
    final String email = user['email'] ?? 'No Email';
    final String username = (user['username'] != null && user['username'].toString().isNotEmpty)
        ? user['username']
        : email.split('@')[0];
    final String city = user['city'] ?? 'Unknown City';
    final String? phone = user['phone'];
    final bool isDonor = user['user_type'] == 'donor';

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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
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

                // Role + Pending Badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDonor ? AppTheme.primaryRed : Colors.blue).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isDonor ? 'DONOR' : 'RECEIVER',
                        style: TextStyle(
                          color: isDonor ? AppTheme.primaryRed : Colors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PENDING',
                        style: TextStyle(
                            color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
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
                          label: const Text('Reject', style: TextStyle(color: Colors.red)),
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
                          label: const Text('Approve Priority',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
