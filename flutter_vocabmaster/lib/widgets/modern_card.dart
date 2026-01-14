import 'dart:ui';
import 'package:flutter/material.dart';
import 'modern_background.dart';
import 'modern_colors.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BackgroundVariant variant;
  final bool showBorder;
  final bool showGlow;
  final BorderRadius? borderRadius;

  const ModernCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.variant = BackgroundVariant.primary,
    this.showBorder = true,
    this.showGlow = false,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: const Color(0x1A06B6D4), // cyan-500/10
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: ModernBackground(
                variant: variant,
              ),
            ),

            // Backdrop Filter (Glassmorphism)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
              ),
            ),

            // Border
            if (showBorder)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius ?? BorderRadius.circular(24),
                    border: Border.all(
                      color: ModernColors.borderColor,
                      width: 1,
                    ),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: padding ?? const EdgeInsets.all(24),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
