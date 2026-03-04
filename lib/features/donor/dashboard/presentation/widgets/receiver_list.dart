import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/custom_loader.dart';
import '../../../../../core/widgets/user_card.dart';
import '../../../../../references/button_patterns.dart';

class ReceiverList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String? bloodType;
  final bool hasMore;
  final ScrollController scrollController;
  final VoidCallback onRefresh;
  final void Function(String? phone) onCall;

  const ReceiverList({
    super.key,
    required this.items,
    required this.bloodType,
    required this.hasMore,
    required this.scrollController,
    required this.onRefresh,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    if (bloodType == null) return const _BloodTypeMissing();
    if (items.isEmpty) return _EmptyReceivers(onRefresh: onRefresh);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.accent,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length + (hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CustomLoader(size: 28),
            );
          }
          final item = items[i];
          return UserCard(
            userData: item,
            onTap: () {},
            onCall: () => onCall(item['phone']),
          );
        },
      ),
    );
  }
}

class _BloodTypeMissing extends StatelessWidget {
  const _BloodTypeMissing();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bloodtype_outlined,
              size: 64,
              color: colors.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'blood_type_missing'.tr(),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReceivers extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyReceivers({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.accent,
      child: LayoutBuilder(
        builder: (_, constraints) {
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
                        color: Colors.green.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      'no_receivers_nearby'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DonorErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const DonorErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: colors.error,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'error_loading'.tr(),
              style: AppTypography.titleLarge.copyWith(
                color: colors.onSurface,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'check_connection'.tr(),
              style: AppTypography.bodyMedium.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'retry'.tr(),
              icon: Icons.refresh_rounded,
              isExpanded: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
