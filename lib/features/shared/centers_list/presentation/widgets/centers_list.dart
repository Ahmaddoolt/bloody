// file: lib/shared/centers_list/presentation/widgets/centers_list.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/custom_loader.dart';
import 'center_card.dart';

class CentersList extends StatelessWidget {
  final List<Map<String, dynamic>> centers;
  final bool isLoading;
  final bool isSuperAdmin;
  final String? currentUserId;
  final ScrollController scrollController;
  final Function(Map<String, dynamic>) onEdit;
  final Function(String) onDelete;
  final Function(Map<String, dynamic>) onViewStock;
  final RefreshCallback onRefresh;
  final Function(Map<String, dynamic>)? onNotifyDonors;

  const CentersList({
    super.key,
    required this.centers,
    required this.isLoading,
    required this.isSuperAdmin,
    required this.currentUserId,
    required this.scrollController,
    required this.onEdit,
    required this.onDelete,
    required this.onViewStock,
    required this.onRefresh,
    this.onNotifyDonors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (centers.isEmpty && !isLoading) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppTheme.primaryRed,
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_hospital_outlined,
                          size: 44, color: AppTheme.primaryRed),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'no_centers'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primaryRed,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: centers.length + 1,
        itemBuilder: (context, index) {
          if (index == centers.length) {
            return isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20), child: CustomLoader(size: 28))
                : const SizedBox.shrink();
          }
          final center = centers[index];
          return CenterCard(
            center: center,
            isSuperAdmin: isSuperAdmin,
            currentUserId: currentUserId,
            onEdit: () => onEdit(center),
            onDelete: () => onDelete(center['id']),
            onViewStock: onViewStock,
            onNotifyDonors: onNotifyDonors != null ? () => onNotifyDonors!(center) : null,
          );
        },
      ),
    );
  }
}
