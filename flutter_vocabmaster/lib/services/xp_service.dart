import 'package:shared_preferences/shared_preferences.dart';
import 'local_database_service.dart';

/// XP Kazanım Türleri ve Puanları
/// Merkezi XP yönetimi için tek kaynak
class XPAction {
  final String id;
  final String name;
  final String description;
  final int xpAmount;
  final String category;

  const XPAction({
    required this.id,
    required this.name,
    required this.description,
    required this.xpAmount,
    required this.category,
  });
}

/// Tüm XP kazanım aksiyonları
class XPActions {
  // 📚 Kelime & Cümle
  static const addWord = XPAction(
    id: 'add_word',
    name: 'Kelime Ekle',
    description: 'Yeni bir kelime eklendi',
    xpAmount: 10,
    category: 'vocabulary',
  );
  
  static const addSentence = XPAction(
    id: 'add_sentence',
    name: 'Cümle Ekle',
    description: 'Bir kelimeye cümle eklendi',
    xpAmount: 5,
    category: 'vocabulary',
  );
  
  static const addPracticeSentence = XPAction(
    id: 'add_practice_sentence',
    name: 'Pratik Cümlesi Ekle',
    description: 'Bağımsız pratik cümlesi eklendi',
    xpAmount: 5,
    category: 'vocabulary',
  );
  
  // 📖 Okuma Pratiği
  static const completeReadingEasy = XPAction(
    id: 'reading_easy',
    name: 'Kolay Okuma',
    description: 'Kolay seviye okuma tamamlandı',
    xpAmount: 10,
    category: 'reading',
  );
  
  static const completeReadingMedium = XPAction(
    id: 'reading_medium',
    name: 'Orta Okuma',
    description: 'Orta seviye okuma tamamlandı',
    xpAmount: 15,
    category: 'reading',
  );
  
  static const completeReadingHard = XPAction(
    id: 'reading_hard',
    name: 'Zor Okuma',
    description: 'Zor seviye okuma tamamlandı',
    xpAmount: 25,
    category: 'reading',
  );
  
  // ✍️ Yazma Pratiği
  static const completeWriting = XPAction(
    id: 'writing_complete',
    name: 'Yazma Egzersizi',
    description: 'Yazma egzersizi tamamlandı',
    xpAmount: 15,
    category: 'writing',
  );
  
  static const writingPerfect = XPAction(
    id: 'writing_perfect',
    name: 'Mükemmel Yazım',
    description: 'Hatasız yazma tamamlandı',
    xpAmount: 25,
    category: 'writing',
  );
  
  // 🗣️ Konuşma Pratiği
  static const completeSpeaking = XPAction(
    id: 'speaking_complete',
    name: 'Konuşma Pratiği',
    description: 'Konuşma pratiği tamamlandı',
    xpAmount: 20,
    category: 'speaking',
  );
  
  static const speakingExcellent = XPAction(
    id: 'speaking_excellent',
    name: 'Mükemmel Telaffuz',
    description: 'Yüksek skorla konuşma tamamlandı',
    xpAmount: 30,
    category: 'speaking',
  );
  
  // 🔄 Çeviri Pratiği
  static const completeTranslation = XPAction(
    id: 'translation_complete',
    name: 'Çeviri Tamamlandı',
    description: 'Çeviri egzersizi tamamlandı',
    xpAmount: 15,
    category: 'translation',
  );
  
  static const translationPerfect = XPAction(
    id: 'translation_perfect',
    name: 'Mükemmel Çeviri',
    description: 'Hatasız çeviri tamamlandı',
    xpAmount: 25,
    category: 'translation',
  );
  
  // 📝 Sınav & Test
  static const examQuestionCorrect = XPAction(
    id: 'exam_correct',
    name: 'Doğru Cevap',
    description: 'Sınav sorusu doğru cevaplandı',
    xpAmount: 5,
    category: 'exam',
  );
  
  static const examComplete = XPAction(
    id: 'exam_complete',
    name: 'Sınav Tamamlandı',
    description: 'Sınav tamamlandı',
    xpAmount: 20,
    category: 'exam',
  );
  
  static const examPerfect = XPAction(
    id: 'exam_perfect',
    name: 'Mükemmel Sınav',
    description: '%90+ başarı ile sınav tamamlandı',
    xpAmount: 50,
    category: 'exam',
  );
  
  // 🔥 Streak & Günlük
  static const dailyGoalComplete = XPAction(
    id: 'daily_goal',
    name: 'Günlük Hedef',
    description: 'Günlük hedef tamamlandı',
    xpAmount: 25,
    category: 'streak',
  );
  
  static const streakBonus3Days = XPAction(
    id: 'streak_3',
    name: '3 Gün Serisi',
    description: '3 günlük seri bonusu',
    xpAmount: 15,
    category: 'streak',
  );
  
  static const streakBonus7Days = XPAction(
    id: 'streak_7',
    name: '7 Gün Serisi',
    description: '7 günlük seri bonusu',
    xpAmount: 50,
    category: 'streak',
  );
  
  static const streakBonus30Days = XPAction(
    id: 'streak_30',
    name: '30 Gün Serisi',
    description: '30 günlük seri bonusu',
    xpAmount: 200,
    category: 'streak',
  );
  
  // 🤖 AI Chat
  static const aiChatMessage = XPAction(
    id: 'ai_chat',
    name: 'AI Sohbet',
    description: 'AI ile bir mesajlaşma yapıldı',
    xpAmount: 5,
    category: 'ai',
  );
  
  static const aiChatSession = XPAction(
    id: 'ai_session',
    name: 'AI Oturum',
    description: '5+ mesajlık AI sohbeti tamamlandı',
    xpAmount: 20,
    category: 'ai',
  );
  
  // 📖 Gramer
  static const grammarTopicComplete = XPAction(
    id: 'grammar_topic',
    name: 'Gramer Konusu',
    description: 'Bir gramer konusu incelendi',
    xpAmount: 10,
    category: 'grammar',
  );
  
  // 🎯 Günün Kelimeleri
  static const dailyWordLearn = XPAction(
    id: 'daily_word',
    name: 'Günün Kelimesi',
    description: 'Günün kelimesi öğrenildi',
    xpAmount: 15,
    category: 'daily',
  );
  
  static const dailyWordQuiz = XPAction(
    id: 'daily_word_quiz',
    name: 'Günün Kelimesi Quiz',
    description: 'Günün kelimesi quizi tamamlandı',
    xpAmount: 10,
    category: 'daily',
  );
  
  // 🔍 Hızlı Sözlük
  static const quickDictionaryAdd = XPAction(
    id: 'quick_dict_add',
    name: 'Hızlı Sözlük',
    description: 'Hızlı sözlükten kelime eklendi',
    xpAmount: 10,
    category: 'dictionary',
  );
  
  // 🔁 Tekrar
  static const reviewComplete = XPAction(
    id: 'review_complete',
    name: 'Tekrar Tamamlandı',
    description: 'Kelime tekrarı yapıldı',
    xpAmount: 5,
    category: 'review',
  );
  
  static const reviewSessionComplete = XPAction(
    id: 'review_session',
    name: 'Tekrar Oturumu',
    description: '10+ kelime tekrar edildi',
    xpAmount: 25,
    category: 'review',
  );
}

/// XP Servisinin ana yönetim sınıfı
class XPService {
  static final XPService _instance = XPService._internal();
  factory XPService() => _instance;
  XPService._internal();
  
  final LocalDatabaseService _localDb = LocalDatabaseService();
  
  // ═══════════════════════════════════════════════════════════════
  // XP KAYIT
  // ═══════════════════════════════════════════════════════════════
  
  /// XP kazanımını kaydet ve miktarı döndür
  /// Bu fonksiyon sadece veritabanına yazar, UI güncellemesi AppStateProvider'da yapılmalı
  Future<int> recordXP(XPAction action) async {
    try {
      await _localDb.addXp(action.xpAmount);
      
      // XP geçmişine kaydet (opsiyonel, analitik için)
      await _recordXPHistory(action);
      
      print('🎯 XP Kazanıldı: ${action.name} (+${action.xpAmount} XP)');
      return action.xpAmount;
    } catch (e) {
      print('❌ XP kayıt hatası: $e');
      return 0;
    }
  }
  
  /// Özel miktar ile XP ekle (örn: quiz puanları)
  Future<int> recordCustomXP(int amount, String reason) async {
    if (amount <= 0) return 0;
    
    try {
      await _localDb.addXp(amount);
      print('🎯 XP Kazanıldı: $reason (+$amount XP)');
      return amount;
    } catch (e) {
      print('❌ XP kayıt hatası: $e');
      return 0;
    }
  }
  
  /// XP geçmişini kaydet (opsiyonel özellik için hazırlık)
  Future<void> _recordXPHistory(XPAction action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Bugünkü XP toplamını kaydet
      final todayKey = 'xp_$today';
      final currentDailyXP = prefs.getInt(todayKey) ?? 0;
      await prefs.setInt(todayKey, currentDailyXP + action.xpAmount);
      
      // Kategori bazlı XP (son 7 gün)
      final categoryKey = 'xp_${action.category}_$today';
      final currentCategoryXP = prefs.getInt(categoryKey) ?? 0;
      await prefs.setInt(categoryKey, currentCategoryXP + action.xpAmount);
    } catch (e) {
      // Geçmiş kaydı opsiyonel, hata sessizce geçilir
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // XP SORGULAMA
  // ═══════════════════════════════════════════════════════════════
  
  /// Toplam XP
  Future<int> getTotalXP() async {
    return await _localDb.getTotalXp();
  }
  
  /// Bugün kazanılan XP
  Future<int> getTodayXP() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    return prefs.getInt('xp_$today') ?? 0;
  }
  
  /// Bu hafta kazanılan XP
  Future<int> getWeeklyXP() async {
    final prefs = await SharedPreferences.getInstance();
    int totalWeeklyXP = 0;
    
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      totalWeeklyXP += prefs.getInt('xp_$dateStr') ?? 0;
    }
    
    return totalWeeklyXP;
  }
  
  /// Seviye hesapla (her 100 XP = 1 seviye)
  int calculateLevel(int totalXP) {
    return (totalXP / 100).floor() + 1;
  }
  
  /// Sonraki seviyeye kalan XP
  int xpToNextLevel(int totalXP) {
    final currentLevel = calculateLevel(totalXP);
    final xpForNextLevel = currentLevel * 100;
    return xpForNextLevel - totalXP;
  }
  
  /// Seviye ilerleme yüzdesi (0.0 - 1.0)
  double levelProgress(int totalXP) {
    final currentLevel = calculateLevel(totalXP);
    final xpForCurrentLevel = (currentLevel - 1) * 100;
    final xpInCurrentLevel = totalXP - xpForCurrentLevel;
    return xpInCurrentLevel / 100.0;
  }
  
  // ═══════════════════════════════════════════════════════════════
  // STREAK BONUS KONTROLÜ
  // ═══════════════════════════════════════════════════════════════
  
  /// Streak bonuslarını kontrol et ve gerekirse ver
  Future<int> checkAndAwardStreakBonus(int currentStreak) async {
    final prefs = await SharedPreferences.getInstance();
    int bonusXP = 0;
    
    // 3 gün kontrolü
    if (currentStreak == 3) {
      final got3 = prefs.getBool('streak_bonus_3') ?? false;
      if (!got3) {
        bonusXP += await recordXP(XPActions.streakBonus3Days);
        await prefs.setBool('streak_bonus_3', true);
      }
    }
    
    // 7 gün kontrolü
    if (currentStreak == 7) {
      final got7 = prefs.getBool('streak_bonus_7') ?? false;
      if (!got7) {
        bonusXP += await recordXP(XPActions.streakBonus7Days);
        await prefs.setBool('streak_bonus_7', true);
      }
    }
    
    // 30 gün kontrolü
    if (currentStreak == 30) {
      final got30 = prefs.getBool('streak_bonus_30') ?? false;
      if (!got30) {
        bonusXP += await recordXP(XPActions.streakBonus30Days);
        await prefs.setBool('streak_bonus_30', true);
      }
    }
    
    return bonusXP;
  }
  
  /// Günlük hedef tamamlandı mı kontrol et
  Future<bool> checkDailyGoal(int learnedToday, int dailyGoal) async {
    if (learnedToday >= dailyGoal) {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final dailyGoalKey = 'daily_goal_$today';
      
      final alreadyAwarded = prefs.getBool(dailyGoalKey) ?? false;
      if (!alreadyAwarded) {
        await recordXP(XPActions.dailyGoalComplete);
        await prefs.setBool(dailyGoalKey, true);
        return true;
      }
    }
    return false;
  }
}
