import 'dart:ui';
import 'package:flutter/material.dart';

class NeonButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isCyan; // true for cyan, false for blue
  final VoidCallback onTap;

  const NeonButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.isCyan,
    required this.onTap,
  }) : super(key: key);

  @override
  _NeonButtonState createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Color definitions based on button type
    final primaryColor = widget.isCyan 
      ? const Color(0x3306B6D4)  // cyan-500/20
      : const Color(0x333B82F6); // blue-500/20
      
    final secondaryColor = widget.isCyan 
      ? const Color(0x333B82F6)  // blue-500/20
      : const Color(0x3306B6D4); // cyan-500/20
      
    final borderColor = widget.isCyan 
      ? const Color(0xFF22D3EE)  // cyan-400
      : const Color(0xFF60A5FA); // blue-400
      
    final glowColor = widget.isCyan 
      ? const Color(0xFF22D3EE)  // cyan-400
      : const Color(0xFF3B82F6); // blue-500
      
    final textColor = widget.isCyan 
      ? const Color(0xFF67E8F9)  // cyan-300
      : const Color(0xFF93C5FD); // blue-300

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isHovered 
              ? borderColor 
              : borderColor.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered 
                ? glowColor.withOpacity(0.6)
                : glowColor.withOpacity(0.3),
              blurRadius: _isHovered ? 25 : 15,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Stack(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    splashColor: glowColor.withOpacity(0.2),
                    highlightColor: glowColor.withOpacity(0.1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.icon,
                            size: 16,
                            color: _isHovered ? Colors.white : textColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: _isHovered ? Colors.white : textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Gradient sweep overlay
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isHovered ? 1.0 : 0.0,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            glowColor.withOpacity(0.0),
                            glowColor.withOpacity(0.2),
                            glowColor.withOpacity(0.0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
