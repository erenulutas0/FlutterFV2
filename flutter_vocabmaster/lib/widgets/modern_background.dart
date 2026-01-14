import 'dart:ui';
import 'package:flutter/material.dart';
import 'modern_colors.dart';
import '../painters/dot_pattern_painter.dart';
import '../painters/diagonal_lines_painter.dart';
import '../painters/grid_pattern_painter.dart';

enum BackgroundVariant { primary, secondary, accent }

class ModernBackground extends StatefulWidget {
  final BackgroundVariant variant;
  final Widget? child;

  const ModernBackground({
    Key? key,
    this.variant = BackgroundVariant.primary,
    this.child,
  }) : super(key: key);

  @override
  State<ModernBackground> createState() => _ModernBackgroundState();
}

class _ModernBackgroundState extends State<ModernBackground>
    with TickerProviderStateMixin {
  late AnimationController _orb1Controller;
  late AnimationController _orb2Controller;
  late Animation<double> _orb1Animation;
  late Animation<double> _orb2Animation;

  @override
  void initState() {
    super.initState();

    // Orb 1 Animation (8 seconds)
    _orb1Controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _orb1Animation = Tween<double>(begin: 0.3, end: 0.5).animate(
      CurvedAnimation(parent: _orb1Controller, curve: Curves.easeInOut),
    );

    // Orb 2 Animation (10 seconds, delayed)
    _orb2Controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _orb2Animation = Tween<double>(begin: 0.2, end: 0.4).animate(
      CurvedAnimation(parent: _orb2Controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _orb1Controller.dispose();
    _orb2Controller.dispose();
    super.dispose();
  }

  List<Color> _getGradientColors() {
    switch (widget.variant) {
      case BackgroundVariant.primary:
        return ModernColors.primaryGradient;
      case BackgroundVariant.secondary:
        return ModernColors.secondaryGradient;
      case BackgroundVariant.accent:
        return ModernColors.accentGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // 1. Base Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getGradientColors(),
                ),
              ),
            ),
          ),

          // 2. Dot Pattern Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: DotPatternPainter(),
            ),
          ),

          // 3. Diagonal Lines Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: DiagonalLinesPainter(),
            ),
          ),

          // 4. Animated Orb 1 (Top Right)
          Positioned(
            top: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _orb1Animation,
              builder: (context, child) {
                return Opacity(
                  opacity: _orb1Animation.value,
                  child: Container(
                    width: 384,
                    height: 384,
                    decoration: const BoxDecoration(
                      color: ModernColors.orb1Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),

          // 5. Animated Orb 2 (Bottom Left)
          Positioned(
            bottom: 0,
            left: 0,
            child: AnimatedBuilder(
              animation: _orb2Animation,
              builder: (context, child) {
                return Opacity(
                  opacity: _orb2Animation.value,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: const BoxDecoration(
                      color: ModernColors.orb2Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),

          // 6. Grid Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: GridPatternPainter(),
            ),
          ),

          // 7. Vignette Effect
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.transparent,
                  Color(0x66020617), // slate-950/40
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),

          // 8. Child Content
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}
