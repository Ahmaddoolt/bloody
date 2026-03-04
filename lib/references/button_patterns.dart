// file: lib/references/button_patterns.dart
//
// Button Patterns — Reference Implementation
//
// A set of premium button styles with built-in press feedback and loading states.
//
// Design Principles:
// - Every button has physical-feeling tap feedback (scale to 0.96 with spring curve)
// - Consistent heights: primary 52dp, secondary 44dp, icon 44dp
// - Minimum touch target: 48dp in all directions
// - Loading state replaces label with a sized circular indicator (never shifts layout)
//
// ignore_for_file: unused_element, deprecated_member_use

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Variant enum
// ─────────────────────────────────────────────────────────────────────────────

enum AppButtonVariant { primary, secondary, ghost }

// ─────────────────────────────────────────────────────────────────────────────
// AppButton
// ─────────────────────────────────────────────────────────────────────────────

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
    this.variant = AppButtonVariant.primary,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleController.forward();
  void _onTapUp(TapUpDetails _) => _scaleController.reverse();
  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: isDisabled ? null : _onTapDown,
        onTapUp: isDisabled ? null : _onTapUp,
        onTapCancel: isDisabled ? null : _onTapCancel,
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: widget.variant == AppButtonVariant.primary ? 52 : 44,
          constraints: widget.isExpanded
              ? const BoxConstraints(minWidth: double.infinity)
              : const BoxConstraints(minWidth: 120),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: _buildDecoration(isDisabled),
          child: Center(child: _buildContent(isDisabled)),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(bool isDisabled) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return BoxDecoration(
          color: isDisabled
              ? AppColors.accent.withOpacity(0.4)
              : AppColors.accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        );
      case AppButtonVariant.secondary:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? AppColors.textTertiary.withOpacity(0.3)
                : AppColors.textPrimary,
            width: 1.5,
          ),
        );
      case AppButtonVariant.ghost:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        );
    }
  }

  Widget _buildContent(bool isDisabled) {
    if (widget.isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: widget.variant == AppButtonVariant.primary
              ? Colors.white
              : AppColors.textPrimary,
        ),
      );
    }

    final textColor = switch (widget.variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.secondary =>
        isDisabled ? AppColors.textTertiary : AppColors.textPrimary,
      AppButtonVariant.ghost =>
        isDisabled ? AppColors.textTertiary : AppColors.accent,
    };

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: AppTypography.label.copyWith(color: textColor),
          ),
        ],
      );
    }

    return Text(
      widget.label,
      style: AppTypography.label.copyWith(color: textColor),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppIconButton
// ─────────────────────────────────────────────────────────────────────────────

class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final Color? backgroundColor;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.color,
    this.backgroundColor,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) => _controller.forward(),
      onTapCancel: () => _controller.forward(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _controller,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(widget.size / 3),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.size * 0.5,
              color: widget.color ?? AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}