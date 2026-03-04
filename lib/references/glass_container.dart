// file: lib/references/glass_container.dart
//
// Glass Container — Reference Implementation
//
// A versatile frosted-glass container widget for glassmorphism effects.
//
// Usage:
//   GlassContainer(
//     borderRadius: 20,
//     blur: 24,
//     opacity: 0.15,
//     padding: EdgeInsets.all(20),
//     child: Text('Hello Glass'),
//   )
//
// Works best when there is visual content behind it — on a flat white
// background, the glass effect won't be visible.
//
// Performance Notes:
// - BackdropFilter is expensive. Avoid stacking multiple glass containers.
// - On lower-end devices, consider reducing blur to 12–16 or a solid fallback.
// - ClipRRect adds to the render cost — clip only what you need.
// - For lists of glass cards, consider RepaintBoundary around each card.
//
// ignore_for_file: unused_element, deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GlassContainer
// ─────────────────────────────────────────────────────────────────────────────

/// A frosted-glass container with customizable blur, opacity, and border.
///
/// Use for cards, modals, bottom sheets, and overlays that sit on top
/// of rich backgrounds (gradients, images, or other content).
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final Color? fillColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 24,
    this.opacity = 0.15,
    this.padding = const EdgeInsets.all(16),
    this.fillColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFill = fillColor ?? Colors.white.withOpacity(opacity);
    final effectiveBorder = borderColor ?? Colors.white.withOpacity(0.2);
    final effectiveShadows = shadows ??
        [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: effectiveFill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: effectiveBorder,
              width: borderWidth,
            ),
            boxShadow: effectiveShadows,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AnimatedGlassContainer
// ─────────────────────────────────────────────────────────────────────────────

/// A glass container with an animated shimmer border.
///
/// Usage — dark mode variant:
///   AnimatedGlassContainer(
///     child: content,
///   )
///
/// For dark backgrounds, wrap with a Container that has a dark fill,
/// or pass fillColor: Colors.black.withOpacity(0.2).
class AnimatedGlassContainer extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final Duration shimmerDuration;

  const AnimatedGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.shimmerDuration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedGlassContainer> createState() => _AnimatedGlassContainerState();
}

class _AnimatedGlassContainerState extends State<AnimatedGlassContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.shimmerDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15 + 0.1 * _controller.value),
                  width: 1.0,
                ),
              ),
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: widget.child,
      ),
    );
  }
}
