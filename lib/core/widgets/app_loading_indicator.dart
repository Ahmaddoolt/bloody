import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../theme/app_theme.dart';

/// Small inline loading indicator (for buttons)
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.size = 24,
    this.strokeWidth = 2.5,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loaderColor = color ?? (isDark ? Colors.white : AppTheme.primaryRed);

    return SizedBox(
      width: size,
      height: size,
      child: LoadingAnimationWidget.inkDrop(
        color: loaderColor,
        size: size,
      ),
    );
  }
}

/// Full-page centered loading with optional message
class AppLoadingCenter extends StatelessWidget {
  final double size;
  final String? message;

  const AppLoadingCenter({
    super.key,
    this.size = 50,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loaderColor = isDark ? Colors.white : AppTheme.primaryRed;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadingAnimationWidget.inkDrop(
            color: loaderColor,
            size: size,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
