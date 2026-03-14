// file: lib/shared/centers_list/presentation/widgets/centers_list.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/custom_loader.dart';
import '../providers/centers_provider.dart';
import 'center_card.dart';

class CentersList extends StatelessWidget {
  final List<CenterModel> centers;
  final bool isLoading;
  final bool isSuperAdmin;
  final ScrollController scrollController;
  final Function(CenterModel)? onEdit;
  final Function(String)? onDelete;
  final Function(CenterModel)? onViewStock;
  final Function(CenterModel)? onViewDetails;
  final RefreshCallback onRefresh;

  const CentersList({
    super.key,
    required this.centers,
    required this.isLoading,
    this.isSuperAdmin = false,
    required this.scrollController,
    this.onEdit,
    this.onDelete,
    this.onViewStock,
    this.onViewDetails,
    required this.onRefresh,
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
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CustomLoader(size: 28))
                : const SizedBox.shrink();
          }
          final center = centers[index];
          return CenterCard(
            center: center,
            isSuperAdmin: isSuperAdmin,
            onEdit: onEdit != null ? () => onEdit!(center) : null,
            onDelete: onDelete != null ? () => onDelete!(center.id) : null,
            onViewStock:
                onViewStock != null ? () => onViewStock!(center) : null,
            onViewDetails:
                onViewDetails != null ? () => onViewDetails!(center) : null,
          );
        },
      ),
    );
  }
}
