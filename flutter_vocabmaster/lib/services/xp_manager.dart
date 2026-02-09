import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'local_database_service.dart';

/// XP Aksiyonları - Tüm XP kazanım türleri ve miktarları
class XPActionType {
  final String id;
  final String name;
  final String description;
  final int xpAmount;
  final String category;
  final bool isRepeatable;

  const XPActionType({
    required this.id,
    required this.name,
    required this.description,
    required this.xpAmount,
    required this.category,
    this.isRepeatable = true,
  });
}

/// Tüm XP aksiyonlarının merkezi tanımı
class XPActionTypes {
  // 📚 Kelime & Cümle
  static const addWord = XPActionType(
    id: 'add_word',
    name: 'Kelime Ekle',
    description: 'Yeni bir kelime eklendi',
    xpAmount: 10,
    category: 'vocabulary',
  );

  static const addSentence = XPActionType(
    id: 'add_sentence',
    name: 'Cümle Ekle',
    description: 'Bir kelimeye cümle eklendi',
    xpAmount: 5,
    category: 'vocabulary',
  );

  static const addPracticeSentence = XPActionType(
    id: 'add_practice_sentence',
    name: 'Pratik Cümlesi Ekle',
    description: 'Bağımsız pratik cümlesi eklendi',
    xpAmount: 5,
    category: 'vocabulary',
  );

  // 📖 Okuma Pratiği
  static const readingEasy = XPActionType(
    id: 'reading_easy',
    name: 'Kolay Okuma',
    description: 'Kolay seviye okuma tamamlandı',
    xpAmount: 10,
    category: 'reading',
  );

  static const readingMedium = XPActionType(
    id: 'reading_medium',
    name: 'Orta Okuma',
    description: 'Orta seviye okuma tamamlandı',
    xpAmount: 15,
    category: 'reading',
  );

  static const readingHard = XPActionType(
    id: 'reading_hard',
    name: 'Zor Okuma',
    description: 'Zor seviye okuma tamamlandı',
    xpAmount: 25,
    category: 'reading',
  );

  // ✍️ Yazma Pratiği
  static const writingComplete = XPActionType(
    id: 'writing_complete',
    name: 'Yazma Egzersizi',
    description: 'Yazma egzersizi tamamlandı',
    xpAmount: 15,
    category: 'writing',
  );

  static const writingPerfect = XPActionType(
    id: 'writing_perfect',
    name: 'Mükemmel Yazım',
    description: 'Hatasız yazma tamamlandı',
    xpAmount: 25,
    category: 'writing',
  );

  // 🗣️ Konuşma Pratiği
  static const speakingComplete = XPActionType(
    id: 'speaking_complete',
    name: 'Konuşma Pratiği',
    description: 'Konuşma pratiği tamamlandı',
    xpAmount: 20,
    category: 'speaking',
  );

  static const speakingExcellent = XPActionType(
    id: 'speaking_excellent',
    name: 'Mükemmel Telaffuz',
    description: 'Yüksek skorla konuşma tamamlandı',
    xpAmount: 30,
    category: 'speaking',
  );

  // 🔄 Çeviri Pratiği
  static const translationComplete = XPActionType(
    id: 'translation_complete',
    name: 'Çeviri Tamamlandı',
    description: 'Çeviri egzersizi tamamlandı',
    xpAmount: 15,
    category: 'translation',
  );

  static const translationPerfect = XPActionType(
    id: 'translation_perfect',
    name: 'Mükemmel Çeviri',
    description: 'Hatasız çeviri tamamlandı',
    xpAmount: 25,
    category: 'translation',
  );

  // 📝 Sınav & Test
  static const examQuestionCorrect = XPActionType(
    id: 'exam_correct',
    name: 'Doğru Cevap',
    description: 'Sınav sorusu doğru cevaplandı',
    xpAmount: 5,
    category: 'exam',
  );

  static const examComplete = XPActionType(
    id: 'exam_complete',
    name: 'Sınav Tamamlandı',
    description: 'Sınav tamamlandı',
    xpAmount: 20,
    category: 'exam',
  );

  static const examPerfect = XPActionType(
    id: 'exam_perfect',
    name: 'Mükemmel Sınav',
    description: '%90+ başarı ile sınav tamamlandı',
    xpAmount: 50,
    category: 'exam',
  );

  // 🔥 Streak & Günlük
  static const dailyGoalComplete = XPActionType(
    id: 'daily_goal',
    name: 'Günlük Hedef',
    description: 'Günlük hedef tamamlandı',
    xpAmount: 25,
    category: 'streak',
    isRepeatable: false,
  );

  static const streakBonus3 = XPActionType(
    id: 'streak_3',
    name: '3 Gün Serisi',
    description: '3 günlük seri bonusu',
    xpAmount: 15,
    category: 'streak',
    isRepeatable: false,
  );

  static const streakBonus7 = XPActionType(
    id: 'streak_7',
    name: '7 Gün Serisi',
    description: '7 günlük seri bonusu',
    xpAmount: 50,
    category: 'streak',
    isRepeatable: false,
  );

  static const streakBonus30 = XPActionType(
    id: 'streak_30',
    name: '30 Gün Serisi',
    description: '30 günlük seri bonusu',
    xpAmount: 200,
    category: 'streak',
    isRepeatable: false,
  );

  // 🤖 AI Chat
  static const aiChatMessage = XPActionType(
    id: 'ai_chat',
    name: 'AI Sohbet',
    description: 'AI ile bir mesajlaşma yapıldı',
    xpAmount: 2,
    category: 'ai',
  );

  static const aiChatSession = XPActionType(
    id: 'ai_session',
    name: 'AI Oturum',
    description: '5+ mesajlık AI sohbeti tamamlandı',
    xpAmount: 15,
    category: 'ai',
  );

  // 📖 Gramer
  static const grammarTopicView = XPActionType(
    id: 'grammar_topic',
    name: 'Gramer Konusu',
    description: 'Bir gramer konusu incelendi',
    xpAmount: 10,
    category: 'grammar',
  );

  // 🎯 Günün Kelimeleri
  static const dailyWordLearn = XPActionType(
    id: 'daily_word',
    name: 'Günün Kelimesi',
    description: 'Günün kelimesi öğrenildi/eklendi',
    xpAmount: 15,
    category: 'daily',
  );

  // 🔍 Hızlı Sözlük
  static const quickDictionaryAdd = XPActionType(
    id: 'quick_dict_add',
    name: 'Hızlı Sözlük',
    description: 'Hızlı sözlükten kelime eklendi',
    xpAmount: 10,
    category: 'dictionary',
  );

  // 🔁 Tekrar
  static const reviewComplete = XPActionType(
    id: 'review_complete',
    name: 'Tekrar Tamamlandı',
    description: 'Kelime tekrarı yapıldı',
    xpAmount: 5,
    category: 'review',
  );

  static const reviewSession = XPActionType(
    id: 'review_session',
    name: 'Tekrar Oturumu',
    description: '10+ kelime tekrar edildi',
    xpAmount: 25,
    category: 'review',
  );
}

/// XP durumu callback'i için typedef
typedef XPCallback = void Function(int totalXP, int addedXP, String? action);

/// Merkezi XP Yöneticisi - Singleton
/// Bu sınıf tüm XP işlemlerini yönetir ve UI güncellemelerini tetikler
class XPManager {
  static final XPManager _instance = XPManager._internal();
  factory XPManager() => _instance;
  XPManager._internal();

  final LocalDatabaseService _localDb = LocalDatabaseService();
  
  // UI güncellemeleri için callback
  XPCallback? _onXPChanged;

  /// Test için tarih mocklama
  DateTime? _mockDate;
  @visibleForTesting
  set mockDate(DateTime? date) => _mockDate = date;
  
  DateTime get _now => _mockDate ?? DateTime.now();
  
  // Cache
  int _cachedTotalXP = 0;
  int _cachedWeeklyXP = 0;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheDuration = Duration(seconds: 5);
  
  // 🆔 İdempotency için transaction takibi (SharedPreferences ile kalıcı)
  // Aynı işlem için birden fazla XP verilmesini engeller
  static Set<String> _processedTransactions = {};
  static bool _transactionsLoaded = false;

  /// XP değişikliği dinleyicisi ayarla
  void setOnXPChanged(XPCallback? callback) {
    _onXPChanged = callback;
  }
  
  /// Transaction geçmişini SharedPreferences'tan yükle
  Future<void> _loadTransactions() async {
    if (_transactionsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final txList = prefs.getStringList('xp_transactions') ?? [];
      _processedTransactions = txList.toSet();
      _transactionsLoaded = true;
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }
  
  /// Transaction'ı SharedPreferences'a kaydet
  Future<void> _saveTransaction(String txId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _processedTransactions.add(txId);
      
      // Son 500 transaction'ı tut (memory optimization)
      if (_processedTransactions.length > 500) {
        final list = _processedTransactions.toList();
        _processedTransactions = list.skip(list.length - 500).toSet();
      }
      
      await prefs.setStringList('xp_transactions', _processedTransactions.toList());
    } catch (e) {
      print('Error saving transaction: $e');
    }
  }

  /// XP ekle ve callback'i tetikle
  /// [transactionId]: Benzersiz işlem ID'si - aynı ID ile tekrar XP verilmez (idempotency)
  /// Returns: Eklenen XP miktarı (0 = zaten işlenmiş veya hata)
  Future<int> addXP(XPActionType action, {String? source, String? transactionId}) async {
    try {
      // 🆔 İdempotency kontrolü - SharedPreferences'tan yükle
      await _loadTransactions();
      
      if (transactionId != null) {
        if (_processedTransactions.contains(transactionId)) {
          print('⚠️ XP işlemi zaten işlenmiş (idempotent): $transactionId');
          return 0;
        }
        
        // Transaction'ı kalıcı olarak kaydet
        await _saveTransaction(transactionId);
      }
      
      // Tekrarlanabilirlik kontrolü (action bazlı)
      if (!action.isRepeatable) {
        final alreadyAwarded = await _checkAlreadyAwarded(action.id);
        if (alreadyAwarded) {
          print('⚠️ XP zaten verilmiş: ${action.name}');
          return 0;
        }
        await _markAsAwarded(action.id);
      }

      // 🔥 Önce mevcut XP değerini al (cache 0 olabileceği için)
      final currentXP = await getTotalXP(forceRefresh: true);
      final newTotalXP = currentXP + action.xpAmount;

      // XP'yi local DB'ye kaydet
      await _localDb.addXp(action.xpAmount);
      
      // Günlük XP kaydı (analitik için)
      await _recordDailyXP(action);
      
      // Cache'i güncelle (doğru değerle)
      _cachedTotalXP = newTotalXP;
      _cachedWeeklyXP += action.xpAmount;
      
      // SharedPreferences'a da kaydet (web için önemli - kalıcılık)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_xp_persistent', newTotalXP);
      
      // Callback'i tetikle
      _onXPChanged?.call(newTotalXP, action.xpAmount, action.name);
      
      print('🎯 XP Kazanıldı: ${action.name} (+${action.xpAmount} XP) Toplam: $newTotalXP ${source != null ? '[$source]' : ''} ${transactionId != null ? 'tx:$transactionId' : ''}');
      return action.xpAmount;
    } catch (e) {
      print('❌ XP ekleme hatası: $e');
      return 0;
    }
  }

  /// Özel miktar ile XP ekle (örn: quiz puanları)
  Future<int> addCustomXP(int amount, String reason) async {
    if (amount <= 0) return 0;
    
    try {
      // 🔥 Önce mevcut XP değerini al (cache 0 olabileceği için)
      final currentXP = await getTotalXP(forceRefresh: true);
      final newTotalXP = currentXP + amount;
      
      await _localDb.addXp(amount);
      
      // Günlük kayıt
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayKey = 'xp_$today';
      final currentDailyXP = prefs.getInt(todayKey) ?? 0;
      await prefs.setInt(todayKey, currentDailyXP + amount);
      
      // Cache'i güncelle (doğru değerle)
      _cachedTotalXP = newTotalXP;
      _cachedWeeklyXP += amount;
      
      // SharedPreferences'a da kaydet (web için kalıcılık)
      await prefs.setInt('total_xp_persistent', newTotalXP);
      
      // Callback'i tetikle
      _onXPChanged?.call(newTotalXP, amount, reason);
      
      print('🎯 XP Kazanıldı: $reason (+$amount XP) Toplam: $newTotalXP');
      return amount;
    } catch (e) {
      print('❌ XP ekleme hatası: $e');
      return 0;
    }
  }

  /// XP düşür (silme işlemleri için)
  Future<void> deductXP(int amount, String reason) async {
    if (amount <= 0) return;
    
    try {
      // 🔥 Önce mevcut XP değerini al (cache 0 olabileceği için)
      final currentXP = await getTotalXP(forceRefresh: true);
      final newTotalXP = (currentXP - amount) > 0 ? (currentXP - amount) : 0;
      
      await _localDb.deductXp(amount);
      
      // Günlük kayıt güncelle (eksiye düşebilir)
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayKey = 'xp_$today';
      final currentDailyXP = prefs.getInt(todayKey) ?? 0;
      await prefs.setInt(todayKey, (currentDailyXP - amount) > 0 ? (currentDailyXP - amount) : 0);
      
      // Cache'i güncelle (doğru değerle)
      _cachedTotalXP = newTotalXP;
      _cachedWeeklyXP = (_cachedWeeklyXP - amount) > 0 ? (_cachedWeeklyXP - amount) : 0;
      
      // SharedPreferences'a da kaydet 
      await prefs.setInt('total_xp_persistent', newTotalXP);
      
      // Callback'i tetikle
      _onXPChanged?.call(newTotalXP, -amount, reason);
      
      print('🗑️ XP Silindi: $reason (-$amount XP) Toplam: $newTotalXP');
    } catch (e) {
      print('❌ XP silme hatası: $e');
    }
  }

  /// Toplam XP getir (cache'li)
  /// Web için SharedPreferences'ı öncelikli kullan (daha güvenilir kalıcılık)
  Future<int> getTotalXP({bool forceRefresh = false}) async {
    if (!forceRefresh && _lastCacheUpdate != null) {
      final elapsed = DateTime.now().difference(_lastCacheUpdate!);
      if (elapsed < _cacheDuration) {
        return _cachedTotalXP;
      }
    }
    
    // Önce SharedPreferences'tan oku (web için daha güvenilir)
    final prefs = await SharedPreferences.getInstance();
    final prefsXP = prefs.getInt('total_xp_persistent') ?? 0;
    
    // Database'den de oku
    final dbXP = await _localDb.getTotalXp();
    
    // En büyük değeri kullan (veri kaybını önle)
    _cachedTotalXP = prefsXP > dbXP ? prefsXP : dbXP;
    
    // Eğer fark varsa senkronize et
    if (prefsXP != _cachedTotalXP) {
      await prefs.setInt('total_xp_persistent', _cachedTotalXP);
    }
    
    _lastCacheUpdate = DateTime.now();
    return _cachedTotalXP;
  }

  /// Bu hafta kazanılan XP
  Future<int> getWeeklyXP({bool forceRefresh = false}) async {
    if (!forceRefresh && _lastCacheUpdate != null) {
      final elapsed = DateTime.now().difference(_lastCacheUpdate!);
      if (elapsed < _cacheDuration) {
        return _cachedWeeklyXP;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    int totalWeeklyXP = 0;
    
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      totalWeeklyXP += prefs.getInt('xp_$dateStr') ?? 0;
    }
    
    _cachedWeeklyXP = totalWeeklyXP;
    return totalWeeklyXP;
  }

  /// Bugün kazanılan XP
  Future<int> getTodayXP() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    return prefs.getInt('xp_$today') ?? 0;
  }

  /// Seviye hesapla
  int calculateLevel(int totalXP) {
    if (totalXP < 100) return 1;
    if (totalXP < 250) return 2;
    if (totalXP < 500) return 3;
    if (totalXP < 1000) return 4;
    if (totalXP < 2000) return 5;
    if (totalXP < 3500) return 6;
    if (totalXP < 5500) return 7;
    if (totalXP < 8000) return 8;
    if (totalXP < 11000) return 9;
    if (totalXP < 15000) return 10;
    
    // 10. seviyeden sonra her 5000 XP = 1 seviye
    return 10 + ((totalXP - 15000) ~/ 5000);
  }

  /// Sonraki seviye için gereken XP
  int xpForNextLevel(int totalXP) {
    final currentLevel = calculateLevel(totalXP);
    final nextLevelXP = _getXPForLevel(currentLevel + 1);
    return nextLevelXP - totalXP;
  }

  /// Seviye ilerleme yüzdesi (0.0 - 1.0)
  double levelProgress(int totalXP) {
    final currentLevel = calculateLevel(totalXP);
    final currentLevelXP = _getXPForLevel(currentLevel);
    final nextLevelXP = _getXPForLevel(currentLevel + 1);
    final xpInCurrentLevel = totalXP - currentLevelXP;
    final xpNeededForLevel = nextLevelXP - currentLevelXP;
    
    return xpInCurrentLevel / xpNeededForLevel;
  }

  int _getXPForLevel(int level) {
    if (level <= 1) return 0;
    if (level == 2) return 100;
    if (level == 3) return 250;
    if (level == 4) return 500;
    if (level == 5) return 1000;
    if (level == 6) return 2000;
    if (level == 7) return 3500;
    if (level == 8) return 5500;
    if (level == 9) return 8000;
    if (level == 10) return 11000;
    if (level == 11) return 15000;
    
    // 11. seviyeden sonra her seviye +5000 XP
    return 15000 + ((level - 11) * 5000);
  }

  /// Günlük XP kaydı
  Future<void> _recordDailyXP(XPActionType action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _now.toIso8601String().split('T')[0];
      
      // Bugünkü toplam XP
      final todayKey = 'xp_$today';
      final currentDailyXP = prefs.getInt(todayKey) ?? 0;
      await prefs.setInt(todayKey, currentDailyXP + action.xpAmount);
      
      // Kategori bazlı XP
      final categoryKey = 'xp_${action.category}_$today';
      final currentCategoryXP = prefs.getInt(categoryKey) ?? 0;
      await prefs.setInt(categoryKey, currentCategoryXP + action.xpAmount);
    } catch (e) {
      // Kayıt opsiyonel, hata sessizce geçilir
    }
  }

  /// Tekrarlanamayan XP kontrolü
  Future<bool> _checkAlreadyAwarded(String actionId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _now.toIso8601String().split('T')[0];
    return prefs.getBool('xp_awarded_${actionId}_$today') ?? false;
  }

  /// Tekrarlanamayan XP'yi işaretle
  Future<void> _markAsAwarded(String actionId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _now.toIso8601String().split('T')[0];
    await prefs.setBool('xp_awarded_${actionId}_$today', true);
  }


  /// Cache'i temizle (yeni veri yüklemeden önce)
  void invalidateCache() {
    _lastCacheUpdate = null;
  }

  /// Streak bonuslarını kontrol et ve gerekirse ver
  Future<int> checkAndAwardStreakBonus(int currentStreak) async {
    int bonusXP = 0;
    
    if (currentStreak == 3) {
      bonusXP += await addXP(XPActionTypes.streakBonus3);
    } else if (currentStreak == 7) {
      bonusXP += await addXP(XPActionTypes.streakBonus7);
    } else if (currentStreak == 30) {
      bonusXP += await addXP(XPActionTypes.streakBonus30);
    }
    
    return bonusXP;
  }


  /// Test amaçlı idempotency durumunu sıfırla
  @visibleForTesting
  static void resetIdempotency() {
    _processedTransactions.clear();
    _transactionsLoaded = false;
  }

  /// Günlük hedef kontrolü
  Future<bool> checkDailyGoal(int learnedToday, int dailyGoal) async {
    if (learnedToday >= dailyGoal) {
      final xp = await addXP(XPActionTypes.dailyGoalComplete);
      return xp > 0;
    }
    return false;
  }
}

