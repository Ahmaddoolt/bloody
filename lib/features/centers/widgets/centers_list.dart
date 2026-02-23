// file: lib/features/centers/widgets/centers_list.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_loader.dart';
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
  final RefreshCallback onRefresh; // NEW CALLBACK

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
    required this.onRefresh, // REQUIRED
  });

  @override
  Widget build(BuildContext context) {
    if (centers.isEmpty && !isLoading) {
      // Empty state with Pull-to-Refresh support
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppTheme.primaryRed,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_hospital_outlined,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text("no_centers".tr(),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 18)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // List with Pull-to-Refresh
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primaryRed,
      child: ListView.builder(
        controller: scrollController,
        padding:
            const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
        itemCount: centers.length + 1, // +1 for loader
        itemBuilder: (context, index) {
          if (index == centers.length) {
            return isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CustomLoader(size: 30),
                  )
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
          );
        },
      ),
    );
  }
}
