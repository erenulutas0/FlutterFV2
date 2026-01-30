import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const cyan400 = Color(0xFF22D3EE);
  static const cyan500 = Color(0xFF06B6D4);
  static const blue400 = Color(0xFF60A5FA);
  static const blue500 = Color(0xFF3B82F6);
  static const blue900 = Color(0xFF1E3A8A);
  static const blue950 = Color(0xFF172554);
  static const indigo950 = Color(0xFF1E1B4B);
  
  // Neutral colors
  static const slate900 = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  
  // Helper methods for opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  // Predefined opacity variants
  static final cyan400_50 = cyan400.withOpacity(0.5);
  static final cyan400_70 = cyan400.withOpacity(0.7);
  static final cyan500_20 = cyan500.withOpacity(0.2);
  static final cyan500_30 = cyan500.withOpacity(0.3);
  static final blue500_20 = blue500.withOpacity(0.2);
  static final slate900_30 = slate900.withOpacity(0.3);
  static final slate900_50 = slate900.withOpacity(0.5);
  static final slate900_60 = slate900.withOpacity(0.6);
  
  // Gradients
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [blue950, indigo950, blue900],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan500, blue500],
  );
}
