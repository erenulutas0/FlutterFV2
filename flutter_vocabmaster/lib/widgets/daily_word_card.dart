import 'dart:ui';
import 'package:flutter/material.dart';

class DailyWordCard extends StatefulWidget {
  final Map<String, dynamic> wordData;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd; // New callback
  final int index;

  const DailyWordCard({
    Key? key,
    required this.wordData,
    required this.onTap,
    required this.onQuickAdd, // Required
    required this.index,
  }) : super(key: key);

  @override
  State<DailyWordCard> createState() => _DailyWordCardState();
}

class _DailyWordCardState extends State<DailyWordCard> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _tapController;

  @override
  void initState() {
    super.initState();
    // Pulse Animation (Word)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    // Stagger start based on index
    Future.delayed(Duration(milliseconds: 200 * widget.index), () {
      if (mounted) _pulseController.repeat(reverse: true);
    });

    // Rotation Animation (Sparkle)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Tap Animation
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors based on difficulty
    final difficulty = (widget.wordData['difficulty'] as String? ?? 'Medium').toLowerCase();
    Color badgeColor;
    Color badgeBgColor;
    Color badgeBorderColor;

    switch (difficulty) {
      case 'easy':
        badgeColor = const Color(0xFF4ADE80); // Green-400
        badgeBgColor = const Color(0x3322C55E); // Green-500 alpha
        badgeBorderColor = const Color(0x4D4ADE80);
        break;
      case 'hard':
        badgeColor = const Color(0xFFF87171); // Red-400
        badgeBgColor = const Color(0x33EF4444); // Red-500 alpha
        badgeBorderColor = const Color(0x4DF87171);
        break;
      case 'medium':
      default:
        badgeColor = const Color(0xFFFACC15); // Yellow-400
        badgeBgColor = const Color(0x33EAB308); // Yellow-500 alpha
        badgeBorderColor = const Color(0x4DFACC15);
        break;
    }

    return AnimatedBuilder(
      animation: _tapController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - _tapController.value,
          child: GestureDetector(
            onTapDown: (_) => _tapController.forward(),
            onTapUp: (_) {
               _tapController.reverse();
               widget.onTap();
            },
            onTapCancel: () => _tapController.reverse(),
            child: Container(
              width: 140,
              height: 180,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x3306B6D4), Color(0x333B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0x4D22D3EE), width: 1),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x3306B6D4),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Stack(
                children: [
                   ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Difficulty Badge
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeBgColor,
                                  border: Border.all(color: badgeBorderColor),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  difficulty.toUpperCase(),
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Word with Pulse Animation
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (_pulseController.value * 0.1),
                                  child: child,
                                );
                              },
                              child: Text(
                                widget.wordData['word'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Translation
                            Text(
                              widget.wordData['translation'] ?? '',
                              style: const TextStyle(
                                color: Color(0xB3FFFFFF),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Sparkles Icon with Rotation
                            RotationTransition(
                              turns: _rotationController,
                              child: const Icon(
                                Icons.auto_awesome, 
                                color: Color(0xFF22D3EE), 
                                size: 16
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Quick Add Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: widget.onQuickAdd, // Handle in parent to stop propagation if needed, but here structure is separate
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
