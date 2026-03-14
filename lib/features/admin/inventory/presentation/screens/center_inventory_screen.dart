import 'package:bloody/core/theme/app_colors.dart';
import 'package:bloody/core/theme/app_spacing.dart';
import 'package:bloody/core/theme/app_theme.dart';
import 'package:bloody/core/widgets/app_loading_indicator.dart';
import 'package:bloody/features/admin/inventory/domain/entities/inventory_entity.dart';
import 'package:bloody/features/admin/inventory/presentation/providers/inventory_provider.dart';
import 'package:bloody/features/shared/centers_list/presentation/widgets/blood_stock_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CenterInventoryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> center;

  const CenterInventoryScreen({super.key, required this.center});

  @override
  ConsumerState<CenterInventoryScreen> createState() =>
      _CenterInventoryScreenState();
}

class _CenterInventoryScreenState extends ConsumerState<CenterInventoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(inventoryProvider.notifier)
          .fetchInventory(widget.center['id'].toString());
    });
  }

  void _showEditSheet(InventoryItemEntity item) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int currentQty = item.quantity;
    int neededQty = item.neededQuantity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (_, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(ctx).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      '${item.bloodType} ${'management'.tr()}',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface),
                    ),
                  ),
                  if (currentQty < 5) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primaryRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppTheme.primaryRed, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'critical_stock_alert'.tr(),
                              style: TextStyle(
                                  color: AppTheme.primaryRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  Text(
                    'current_stock'.tr(),
                    style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CircleButton(
                          icon: Icons.remove,
                          onTap: () => setSheetState(() {
                            if (currentQty > 0) currentQty--;
                          }),
                        ),
                        Text(
                          '$currentQty',
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: currentQty < 5
                                  ? AppTheme.primaryRed
                                  : colorScheme.onSurface),
                        ),
                        _CircleButton(
                          icon: Icons.add,
                          onTap: () => setSheetState(() => currentQty++),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 50),
                  Text(
                    'request_more'.tr(),
                    style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: neededQty > 0
                            ? Colors.red.withValues(alpha: 0.1)
                            : isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.withValues(alpha: 0.05),
                        border: Border.all(
                            color: neededQty > 0
                                ? Colors.red.withValues(alpha: 0.3)
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: neededQty > 0
                                    ? AppTheme.primaryRed
                                    : Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('declare_shortage'.tr(),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: neededQty > 0
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurface
                                              .withValues(alpha: 0.6))),
                            ),
                            Switch(
                              value: neededQty > 0,
                              activeTrackColor:
                                  AppTheme.primaryRed.withValues(alpha: 0.5),
                              activeThumbColor: AppTheme.primaryRed,
                              onChanged: (val) {
                                setSheetState(() {
                                  neededQty = val ? 10 : 0;
                                });
                              },
                            ),
                          ],
                        ),
                        if (neededQty > 0) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('we_need'.tr(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface)),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 100,
                                child: TextFormField(
                                  initialValue: neededQty.toString(),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryRed),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: InputDecoration(
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor:
                                        isDark ? Colors.black26 : Colors.white,
                                  ),
                                  onChanged: (val) {
                                    neededQty = int.tryParse(val) ?? 0;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('bags'.tr(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final alertSent = await ref
                            .read(inventoryProvider.notifier)
                            .updateItem(
                              centerId: widget.center['id'].toString(),
                              centerName:
                                  widget.center['name'] ?? 'blood_center'.tr(),
                              bloodType: item.bloodType,
                              quantity: currentQty,
                              neededQuantity: neededQty,
                            );
                        if (!mounted) return;
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.notifications_active,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      alertSent
                                          ? 'alert_sent_donors'
                                              .tr(args: [item.bloodType])
                                          : 'stock_updated'.tr(),
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                            backgroundColor:
                                alertSent ? AppTheme.primaryRed : Colors.green,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      child: Text('save_changes'.tr(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final centerName = widget.center['name'] ?? 'Blood Center';

    return Scaffold(
      appBar: AppBar(
        title: Text(centerName),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: state.isLoading
          ? const AppLoadingCenter()
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: AppSpacing.page,
                  padding: AppSpacing.card,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primaryRed.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app_outlined,
                          color: AppTheme.primaryRed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'tap_to_edit_stock'.tr(),
                          style: TextStyle(
                              color: AppTheme.primaryRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return BloodStockTile(
                        bloodType: item.bloodType,
                        quantity: item.quantity,
                        neededQuantity: item.neededQuantity,
                        isEditing: true,
                        onTap: () => _showEditSheet(item),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref
              .read(inventoryProvider.notifier)
              .fetchInventory(widget.center['id'].toString());
        },
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.refresh),
        label: Text('refresh'.tr()),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.white,
            border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2))
            ]),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }
}
