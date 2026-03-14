import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import 'receiver_card.dart';

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: items.length + (hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: AppLoadingIndicator(size: 24),
            );
          }
          final item = items[i];
          return ReceiverCard(
            userData: item,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bloodtype_outlined,
              size: 56,
              color: colors.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'blood_type_missing'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurface.withOpacity(0.5),
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
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        size: 36,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'no_receivers_nearby'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface.withOpacity(0.6),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 32,
                color: colors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'error_loading'.tr(),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'check_connection'.tr(),
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('retry'.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
