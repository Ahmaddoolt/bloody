// file: lib/shared/features/settings/presentation/widgets/donation_history_list.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/custom_loader.dart';

class DonationHistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final bool isLoading;

  const DonationHistoryList({
    super.key,
    required this.history,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CustomLoader(size: 30),
        ),
      );
    }

    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 10),
              Text(
                "no_donations_yet".tr(),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: history.map((donation) {
        final String date = donation['created_at'] != null
            ? DateTime.parse(donation['created_at']).toLocal().toString().split(' ')[0]
            : 'N/A';
        final String center = donation['centers']?['name'] ?? 'Unknown Center';
        final String status = donation['status'] ?? 'completed';

        Color statusColor = Colors.green;
        Color statusBg = Colors.green.withOpacity(0.1);

        if (status == 'pending') {
          statusColor = Colors.orange;
          statusBg = Colors.orange.withOpacity(0.1);
        }

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.volunteer_activism, color: AppTheme.primaryRed, size: 20),
            ),
            title: Text(center, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
              child: Text(status, style: TextStyle(color: statusColor, fontSize: 12)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
