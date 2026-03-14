import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Generic info row for bottom sheet
class InfoRow {
  final IconData icon;
  final String text;
  final Color? color;

  const InfoRow({
    required this.icon,
    required this.text,
    this.color,
  });
}

/// Generic action button for bottom sheet
class SheetAction {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isOutlined;

  const SheetAction({
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isOutlined = false,
  });
}

/// Generic reusable bottom sheet widget
/// Can be used for any entity: donors, centers, receivers, etc.
///
/// Usage example:
/// ```dart
/// showInfoBottomSheet(
///   context,
///   title: 'John Doe',
///   subtitle: 'A+ Blood Type',
///   avatar: Container(...),
///   infoRows: [
///     InfoRow(icon: Icons.location_on, text: 'Damascus'),
///     InfoRow(icon: Icons.bolt, text: '150 points'),
///   ],
///   actions: [
///     SheetAction(
///       label: 'Call',
///       icon: Icons.phone,
///       onPressed: () => makeCall(),
///       backgroundColor: Colors.green,
///     ),
///     SheetAction(
///       label: 'Close',
///       onPressed: () => Navigator.pop(context),
///       isOutlined: true,
///     ),
///   ],
/// );
/// ```
class InfoBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? avatar;
  final List<InfoRow> infoRows;
  final List<SheetAction> actions;
  final Color? accentColor;

  const InfoBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.avatar,
    required this.infoRows,
    required this.actions,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final effectiveAccent = accentColor ?? AppColors.accent;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: colors.onSurface.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Avatar
          if (avatar != null) ...[
            avatar!,
            const SizedBox(height: 16),
          ],

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          // Subtitle
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // Info rows
          if (infoRows.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...infoRows.map((row) => Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        row.icon,
                        size: 16,
                        color: row.color ?? effectiveAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        row.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: row.color ?? colors.onSurface.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          const SizedBox(height: 20),

          // Action buttons
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: actions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final action = entry.value;
                  final isLast = index == actions.length - 1;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: isLast ? 0 : 16),
                      child: _buildActionButton(action, colors),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton(SheetAction action, ColorScheme colors) {
    if (action.isOutlined) {
      return OutlinedButton.icon(
        onPressed: action.onPressed,
        icon: action.icon != null
            ? Icon(action.icon, size: 18)
            : const SizedBox.shrink(),
        label: Text(action.label),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              action.foregroundColor ?? colors.onSurface.withOpacity(0.7),
          side: BorderSide(color: colors.outline.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: action.onPressed,
      icon: action.icon != null
          ? Icon(action.icon, size: 18)
          : const SizedBox.shrink(),
      label: Text(action.label),
      style: ElevatedButton.styleFrom(
        backgroundColor: action.backgroundColor ?? AppColors.accent,
        foregroundColor: action.foregroundColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Helper function to show the generic info bottom sheet
void showInfoBottomSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  Widget? avatar,
  required List<InfoRow> infoRows,
  required List<SheetAction> actions,
  Color? accentColor,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => InfoBottomSheet(
      title: title,
      subtitle: subtitle,
      avatar: avatar,
      infoRows: infoRows,
      actions: actions,
      accentColor: accentColor,
    ),
  );
}
