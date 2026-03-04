// file: lib/actors/admin/features/inventory/presentation/screens/center_inventory_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/app_logger.dart';
import '../../../../../../core/widgets/custom_loader.dart';
import '../../../../shared/centers_list/presentation/widgets/blood_stock_tile.dart';
import '../../data/inventory_service.dart';
import '../../data/low_stock_alert_service.dart';

class CenterInventoryScreen extends StatefulWidget {
  final Map<String, dynamic> center;

  const CenterInventoryScreen({super.key, required this.center});

  @override
  State<CenterInventoryScreen> createState() => _CenterInventoryScreenState();
}

class _CenterInventoryScreenState extends State<CenterInventoryScreen> {
  // ✅ CLEAN ARCHITECTURE: Call the service, not Supabase directly
  final InventoryService _inventoryService = InventoryService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _inventory = [];

  final List<String> _allBloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() => _isLoading = true);
    try {
      final loadedData = await _inventoryService.getCenterInventory(widget.center['id'].toString());

      _inventory = _allBloodTypes.map((type) {
        final existing = loadedData.firstWhere(
          (element) => element['blood_type'] == type,
          orElse: () => <String, dynamic>{},
        );
        return {
          'blood_type': type,
          'quantity': (existing['quantity'] as num?)?.toInt() ?? 0,
          'is_urgent': existing['is_urgent'] ?? false,
          'needed_quantity': (existing['needed_quantity'] as num?)?.toInt() ?? 0,
          'id': existing['id'],
        };
      }).toList();
    } catch (e, stack) {
      AppLogger.error("CenterInventoryScreen._fetchInventory", e, stack);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('error_loading'.tr())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveItem(String type, int quantity, int needed) async {
    // Optimistic UI update
    final index = _inventory.indexWhere((i) => i['blood_type'] == type);
    if (index != -1) {
      setState(() {
        _inventory[index]['quantity'] = quantity;
        _inventory[index]['needed_quantity'] = needed;
        _inventory[index]['is_urgent'] = (needed > 0);
      });
    }

    try {
      // ✅ Call Data Layer
      final alertSent = await _inventoryService.updateInventoryItem(
        centerId: widget.center['id'].toString(),
        centerName: widget.center['name'] ?? 'Blood Center',
        bloodType: type,
        quantity: quantity,
        neededQuantity: needed,
      );

      // If the service says it sent an alert, show the Snackbar!
      if (alertSent && mounted) {
        AppLogger.success("Low stock alert sent successfully.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text('Alert sent to $type donors!',
                        style: const TextStyle(color: Colors.white))),
              ],
            ),
            backgroundColor: AppTheme.primaryRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      AppLogger.error("CenterInventoryScreen._saveItem", e, stack);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('error_saving'.tr())));
    }
  }

  void _showEditSheet(Map<String, dynamic> item) {
    final type = item['blood_type'] as String;
    int currentQty = item['quantity'] as int;
    int neededQty = item['needed_quantity'] as int;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = Theme.of(context).colorScheme.onSurface;
            final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
            final containerColor =
                isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05);

            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                          color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text('$type ${'management'.tr()}',
                        style:
                            TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                  ),

                  // Warning Banner
                  if (currentQty < LowStockAlertService.lowStockThreshold) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppTheme.primaryRed, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Critical: Below ${LowStockAlertService.lowStockThreshold}. Saving alerts donors.',
                              style: const TextStyle(
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

                  // Stock Control
                  Text('current_stock'.tr(),
                      style: TextStyle(
                          color: subTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: containerColor, borderRadius: BorderRadius.circular(16)),
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
                              color: currentQty < LowStockAlertService.lowStockThreshold
                                  ? AppTheme.primaryRed
                                  : textColor),
                        ),
                        _CircleButton(
                          icon: Icons.add,
                          onTap: () => setSheetState(() => currentQty++),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 50),

                  // Request Control
                  Text('request_more'.tr(),
                      style: TextStyle(
                          color: subTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: neededQty > 0 ? Colors.red.withOpacity(0.1) : containerColor,
                        border: Border.all(
                            color:
                                neededQty > 0 ? Colors.red.withOpacity(0.3) : Colors.transparent),
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: neededQty > 0 ? AppTheme.primaryRed : Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('declare_shortage'.tr(),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: neededQty > 0 ? textColor : subTextColor)),
                            ),
                            Switch(
                              value: neededQty > 0,
                              activeColor: AppTheme.primaryRed,
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
                                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 100,
                                child: TextFormField(
                                  initialValue: neededQty.toString(),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryRed),
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    border:
                                        OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    filled: true,
                                    fillColor: isDark ? Colors.black26 : Colors.white,
                                  ),
                                  onChanged: (val) {
                                    neededQty = int.tryParse(val) ?? 0;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('bags'.tr(),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () {
                        _saveItem(type, currentQty, neededQty);
                        Navigator.pop(ctx);
                      },
                      child: Text('save_changes'.tr(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.center['name'])),
      body: _isLoading
          ? const CustomLoader()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryRed.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app_outlined, color: AppTheme.primaryRed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'tap_to_edit_stock'.tr(),
                          style: const TextStyle(
                              color: AppTheme.primaryRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                ..._inventory.map((item) {
                  return BloodStockTile(
                    bloodType: item['blood_type'],
                    quantity: item['quantity'],
                    neededQuantity: item['needed_quantity'],
                    isEditing: true,
                    onTap: () => _showEditSheet(item),
                  );
                }),
              ],
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
            border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
            ]),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }
}
