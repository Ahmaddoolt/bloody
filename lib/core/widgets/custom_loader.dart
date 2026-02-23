import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../theme/app_theme.dart';

class CustomLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const CustomLoader({super.key, this.size = 50, this.color});

  @override
  Widget build(BuildContext context) {
    // Determine color based on theme if not provided
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loaderColor = color ?? (isDark ? Colors.white : AppTheme.primaryRed);

    return Center(
      child: LoadingAnimationWidget.inkDrop(
        color: loaderColor,
        size: size,
      ),
    );
  }
}
