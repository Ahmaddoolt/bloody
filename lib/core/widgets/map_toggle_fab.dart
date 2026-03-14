import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Reusable Map/List toggle FAB button
/// Follows DRY principle - use this everywhere instead of duplicating
class MapToggleFab extends StatelessWidget {
  final bool isMapView;
  final VoidCallback onToggle;
  final String? heroTag;

  const MapToggleFab({
    super.key,
    required this.isMapView,
    required this.onToggle,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onToggle,
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        isMapView ? Icons.list_rounded : Icons.map_rounded,
        size: 24,
      ),
    );
  }
}
