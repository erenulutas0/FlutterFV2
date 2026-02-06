import 'package:flutter/material.dart';

/// Grammar konu modeli
class GrammarTopic {
  final String id;
  final String title;
  final String titleTr;
  final String level; // 'core', 'advanced', 'exam', 'bonus'
  final IconData icon;
  final Color color;
  final List<GrammarSubtopic> subtopics;

  const GrammarTopic({
    required this.id,
    required this.title,
    required this.titleTr,
    required this.level,
    required this.icon,
    required this.color,
    required this.subtopics,
  });
}

/// Grammar alt konu modeli
class GrammarSubtopic {
  final String id;
  final String title;
  final String titleTr;
  final String explanation; // Türkçe açıklama
  final String formula; // Yapı/formül
  final List<GrammarExample> examples;
  final List<String> commonMistakes;
  final String? examTip;
  final String? comparison; // Karışabilecek konularla karşılaştırma
  final List<String>? keyPoints; // Can alıcı noktalar

  const GrammarSubtopic({
    required this.id,
    required this.title,
    required this.titleTr,
    required this.explanation,
    required this.formula,
    required this.examples,
    this.commonMistakes = const [],
    this.examTip,
    this.comparison,
    this.keyPoints,
  });
}

/// Örnek cümle modeli
class GrammarExample {
  final String english;
  final String turkish;
  final bool isCorrect;
  final String? note;

  const GrammarExample({
    required this.english,
    required this.turkish,
    this.isCorrect = true,
    this.note,
  });
}

/// Seviye renkleri
class GrammarLevelColors {
  static const Color core = Color(0xFF22c55e);
  static const Color advanced = Color(0xFFf59e0b);
  static const Color exam = Color(0xFFef4444);
  static const Color bonus = Color(0xFF8b5cf6);
  
  static Color getColor(String level) {
    switch (level) {
      case 'core': return core;
      case 'advanced': return advanced;
      case 'exam': return exam;
      case 'bonus': return bonus;
      default: return core;
    }
  }
  
  static String getLabel(String level) {
    switch (level) {
      case 'core': return 'Temel';
      case 'advanced': return 'İleri';
      case 'exam': return 'Sınav';
      case 'bonus': return 'Bonus';
      default: return level;
    }
  }
}
