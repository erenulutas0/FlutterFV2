import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/offline_sync_service.dart';
import '../services/user_data_service.dart';
import '../services/auth_service.dart';
import '../services/xp_service.dart';
import '../services/xp_manager.dart';
import '../services/local_database_service.dart';
import '../models/word.dart';
import '../models/sentence_view_model.dart';
import '../services/groq_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global App State Provider - Uygulama genelinde veriyi merkezi tutar
/// Bu sayede sayfalar arası geçişte veri tekrar yüklenmez
class AppStateProvider extends ChangeNotifier {
  final OfflineSyncService _offlineSyncService = OfflineSyncService();
  final UserDataService _userDataService = UserDataService();
  final AuthService _authService = AuthService();
  final XPManager _xpManager = XPManager();

  AppStateProvider() {
    // XP değişikliklerini dinle ve UI'ı güncelle
    _xpManager.setOnXPChanged((totalXP, addedXP, action) {
      _userStats['xp'] = totalXP;
      _userStats['level'] = _xpManager.calculateLevel(totalXP);
      _userStats['xpToNextLevel'] = _xpManager.xpForNextLevel(totalXP);
      notifyListeners();
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // LOADING STATES
  // ═══════════════════════════════════════════════════════════════
  bool _isInitialized = false;
  bool _isLoadingWords = false;
  bool _isLoadingSentences = false;
  bool _isLoadingDailyWords = false;

  bool get isInitialized => _isInitialized;
  bool get isLoadingWords => _isLoadingWords;
  bool get isLoadingSentences => _isLoadingSentences;
  bool get isLoadingDailyWords => _isLoadingDailyWords;

  // ═══════════════════════════════════════════════════════════════
  // USER DATA
  // ═══════════════════════════════════════════════════════════════
  String _userName = 'Kullanıcı';
  Map<String, dynamic>? _userInfo; // Full user info from auth
  Map<String, dynamic> _userStats = {
    'name': 'Kullanıcı',
    'level': 1,
    'xp': 0,
    'xpToNextLevel': 100,
    'totalWords': 0,
    'streak': 0,
    'weeklyXP': 0,
    'dailyGoal': 5,
    'learnedToday': 0,
  };
  List<Map<String, dynamic>> _weeklyActivity = [];
  
  // Profile
  String? _profileImageType;
  String? _profileImagePath;
  String _avatarSeed = '';

  String get userName => _userName;
  Map<String, dynamic>? get userInfo => _userInfo;
  Map<String, dynamic> get userStats => _userStats;
  List<Map<String, dynamic>> get weeklyActivity => _weeklyActivity;
  String? get profileImageType => _profileImageType;
  String? get profileImagePath => _profileImagePath;
  String get avatarSeed => _avatarSeed;

  // ═══════════════════════════════════════════════════════════════
  // MATCHMAKING STATE
  // ═══════════════════════════════════════════════════════════════
  bool _isMatchmaking = false;
  bool get isMatchmaking => _isMatchmaking;

  void toggleMatchmaking() {
    _isMatchmaking = !_isMatchmaking;
    notifyListeners();
  }

  void startMatchmaking() {
    _isMatchmaking = true;
    notifyListeners();
  }

  void stopMatchmaking() {
    _isMatchmaking = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // WORDS & SENTENCES
  // ═══════════════════════════════════════════════════════════════
  List<Word> _allWords = [];
  List<SentenceViewModel> _allSentences = [];
  List<Map<String, dynamic>> _dailyWords = [];

  List<Word> get allWords => _allWords;
  List<SentenceViewModel> get allSentences => _allSentences;
  List<Map<String, dynamic>> get dailyWords => _dailyWords;

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION - Uygulama açılışında çağrılır (HIZLI)
  // ═══════════════════════════════════════════════════════════════
  Future<void> initialize() async {
    if (_isInitialized) return; // Tekrar çağrılmasın
    
    // 🚀 ADIM 1: Önce LOCAL verileri anında yükle (çok hızlı)
    // Bu kullanıcının hemen bir şeyler görmesini sağlar
    await Future.wait([
      _loadWordsFromLocal(),
      _loadSentencesFromLocal(),
    ]);
    
    // 🎯 ADIM 2: User data'yı hemen yükle (totalWords için kelimeler lazım)
    await _loadUserData();
    
    _isInitialized = true;
    notifyListeners();
    
    // 🔄 ADIM 3: Arka planda API sync ve günün kelimeleri (UI'ı bloklamaz)
    _loadDataInBackground();
  }
  
  /// Arka planda API sync ve günün kelimeleri yükle
  void _loadDataInBackground() {
    Future(() async {
      // Günün kelimeleri (cache varsa hızlı, yoksa AI API'den çeker)
      await _loadDailyWords();
      
      // Arka planda API ile sync (local veri zaten var)
      await _offlineSyncService.syncPendingChanges();
    });
  }
  
  /// Sadece LOCAL veritabanından kelimeleri yükle (çok hızlı)
  Future<void> _loadWordsFromLocal() async {
    _isLoadingWords = true;
    try {
      final words = await _offlineSyncService.getLocalWords();
      words.sort((a, b) => b.learnedDate.compareTo(a.learnedDate));
      _allWords = words;
      _isLoadingWords = false;
      notifyListeners();
    } catch (e) {
      print('Error loading words from local: $e');
      _isLoadingWords = false;
    }
  }
  
  /// Sadece LOCAL veritabanından cümleleri yükle (çok hızlı)
  Future<void> _loadSentencesFromLocal() async {
    _isLoadingSentences = true;
    try {
      final words = _allWords.isNotEmpty ? _allWords : await _offlineSyncService.getLocalWords();
      final practiceSentences = await _offlineSyncService.getLocalSentences();
      
      final List<SentenceViewModel> viewModels = [];
      final Set<int> seenIds = {};

      // Word Sentences
      for (var word in words) {
        for (var s in word.sentences) {
          if (seenIds.contains(s.id)) continue;
          seenIds.add(s.id);
          viewModels.add(SentenceViewModel(
            id: s.id,
            sentence: s.sentence,
            translation: s.translation,
            difficulty: s.difficulty ?? 'easy',
            word: word,
            isPractice: false,
            date: word.learnedDate,
          ));
        }
      }

      // Practice Sentences
      for (var s in practiceSentences) {
        if (s.source != 'practice' && s.numericId != 0 && seenIds.contains(s.numericId)) continue;
        viewModels.add(SentenceViewModel(
          id: s.id,
          sentence: s.englishSentence,
          translation: s.turkishTranslation,
          difficulty: s.difficulty,
          word: null,
          isPractice: true,
          date: s.createdDate ?? DateTime.now(),
        ));
      }

      viewModels.sort((a, b) => b.date.compareTo(a.date));
      _allSentences = viewModels;
      _isLoadingSentences = false;
      notifyListeners();
    } catch (e) {
      print('Error loading sentences from local: $e');
      _isLoadingSentences = false;
    }
  }


  // ═══════════════════════════════════════════════════════════════
  // USER DATA LOADING
  // ═══════════════════════════════════════════════════════════════
  Future<void> _loadUserData() async {
    try {
      final authUser = await _authService.getUser();
      final displayName = authUser?['displayName'] ?? 'Kullanıcı';
      
      // Profile settings
      final prefs = await SharedPreferences.getInstance();
      final type = prefs.getString('profile_image_type') ?? 'avatar';
      final path = prefs.getString('profile_image_path');
      final seed = prefs.getString('profile_avatar_seed') ?? displayName;
      
      // ═══════════════════════════════════════════════════════════════
      // GERÇEK VERİTABANI DEĞERLERİNİ KULLAN
      // ═══════════════════════════════════════════════════════════════
      
      // Toplam kelime sayısı = veritabanındaki gerçek kelime sayısı
      final actualTotalWords = _allWords.length;
      
      // XP'yi XPManager'dan al (veritabanından)
      final xpFromManager = await _xpManager.getTotalXP(forceRefresh: true);
      final weeklyXPFromManager = await _xpManager.getWeeklyXP(forceRefresh: true);
      
      // ═══════════════════════════════════════════════════════════════
      // STREAK HESAPLAMASI (SharedPreferences'tan)
      // ═══════════════════════════════════════════════════════════════
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final lastActivityDate = prefs.getString('last_activity_date');
      int currentStreak = prefs.getInt('current_streak') ?? 0;
      
      // Bugün aktivite var mı kontrol et
      if (lastActivityDate != null && lastActivityDate != todayStr) {
        final lastDate = DateTime.parse(lastActivityDate);
        final today = DateTime.parse(todayStr);
        final diffDays = today.difference(lastDate).inDays;
        
        if (diffDays > 1) {
          // Seri kırıldı
          currentStreak = 0;
          await prefs.setInt('current_streak', 0);
        }
      }
      
      // Bugünkü öğrenilen kelime sayısı SharedPreferences'tan
      final learnedTodayKey = 'learned_today_$todayStr';
      
      // DOĞRU HESAPLAMA: Veritabanındaki kelimelerden bugünün kelimelerini say
      final actualLearnedToday = _allWords.where((w) {
        final dateStr = w.learnedDate.toIso8601String().split('T')[0];
        return dateStr == todayStr;
      }).length;
      
      // SharedPreferences'ı güncelle
      await prefs.setInt(learnedTodayKey, actualLearnedToday);
      
      final persistedLearnedToday = actualLearnedToday;
      
      // ═══════════════════════════════════════════════════════════════
      // HAFTALIK AKTİVİTE HESAPLAMASI
      // ═══════════════════════════════════════════════════════════════
      final weeklyActivity = await _calculateWeeklyActivityFromPrefs(prefs);
      
      // ═══════════════════════════════════════════════════════════════
      // STATS OLUŞTURMA
      // ═══════════════════════════════════════════════════════════════
      final level = _xpManager.calculateLevel(xpFromManager);
      
      _userStats = {
        'name': displayName,
        'totalWords': actualTotalWords,
        'streak': currentStreak,
        'xp': xpFromManager,
        'weeklyXP': weeklyXPFromManager,
        'level': level,
        'xpToNextLevel': _xpManager.xpForNextLevel(xpFromManager),
        'dailyGoal': 5,
        'learnedToday': persistedLearnedToday,
        'isOnline': _offlineSyncService.isOnline,
      };
      
      _userName = displayName;
      _userInfo = authUser;
      _weeklyActivity = weeklyActivity;
      _profileImageType = type;
      _profileImagePath = path;
      _avatarSeed = seed;
      
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
  
  /// SharedPreferences'tan haftalık aktiviteyi hesapla
  Future<List<Map<String, dynamic>>> _calculateWeeklyActivityFromPrefs(SharedPreferences prefs) async {
    final now = DateTime.now();
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    
    // Bu haftanın başlangıcını bul (Pazartesi)
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    List<Map<String, dynamic>> weeklyActivity = [];
    
    for (int i = 0; i < 7; i++) {
      final dayDate = weekStart.add(Duration(days: i));
      final dayStr = dayDate.toIso8601String().split('T')[0];
      final learnedKey = 'learned_today_$dayStr';
      final dayCount = prefs.getInt(learnedKey) ?? 0;
      
      weeklyActivity.add({
        'day': days[i],
        'count': dayCount,
        'learned': dayCount > 0,
      });
    }
    
    return weeklyActivity;
  }

  /// Kullanıcı verisini yenile (XP kazanınca vs.)
  Future<void> refreshUserData() async {
    await _loadUserData();
  }

  /// Profil bilgilerini güncelle
  void updateProfileImage({String? type, String? path, String? seed}) {
    if (type != null) _profileImageType = type;
    if (path != null) _profileImagePath = path;
    if (seed != null) _avatarSeed = seed;
    notifyListeners();
  }

  /// Login sonrası kullanıcı verisini direkt set et (Flicker önlemek için)
  void setUser(Map<String, dynamic> user) {
    _userName = user['displayName'] ?? 'Kullanıcı';
    _userInfo = user;
    
    // Basit istatistikleri varsayılan olarak set et, detaylar sonra yüklenir
    _userStats['name'] = _userName;
    if (user['userTag'] != null) _userStats['userTag'] = user['userTag'];
    
    _isInitialized = true; // Veri var kabul et
    notifyListeners();
    
    // Arka planda tam veriyi de çek
    _loadUserData(); 
  }

  // ═══════════════════════════════════════════════════════════════
  // WORDS LOADING
  // ═══════════════════════════════════════════════════════════════
  Future<void> _loadWords() async {
    _isLoadingWords = true;
    // İlk açılışta liste boşsa spinner gösterme, direkt yükle
    
    try {
      final words = await _offlineSyncService.getAllWords();
      // En son eklenen en üstte olacak şekilde sırala
      words.sort((a, b) => b.learnedDate.compareTo(a.learnedDate));
      
      _allWords = words;
      _isLoadingWords = false;
      notifyListeners();
    } catch (e) {
      print('Error loading words: $e');
      _isLoadingWords = false;
      notifyListeners();
    }
  }

  /// Kelimeleri yenile (yeni kelime eklendikten sonra)
  Future<void> refreshWords() async {
    await _loadWords();
  }

  /// Kelime ekle - ve listeyi güncelle
  /// XP, toplam kelime ve günlük hedef otomatik güncellenir
  /// source: 'daily_word' | 'quick_dictionary' | 'manual' gibi kaynak bilgisi
  Future<Word?> addWord({
    required String english,
    required String turkish,
    required DateTime addedDate,
    required String difficulty,
    String? source,
  }) async {
    // 🆔 Transaction ID oluştur ÖNCE - içerik tabanlı (kelime+tarih)
    // Bu sayede aynı kelime aynı gün tekrar eklenirse XP verilmez
    final dateStr = addedDate.toIso8601String().split('T')[0];
    final txId = 'word_${english.toLowerCase().hashCode}_$dateStr';
    
    try {
      final newWord = await _offlineSyncService.createWord(
        english: english,
        turkish: turkish,
        addedDate: addedDate,
        difficulty: difficulty,
      );
      if (newWord != null) {
        _allWords.insert(0, newWord); // Başa ekle
        
        // 🎯 Anlık istatistik güncellemesi (streak, weeklyActivity dahil)
        await incrementLearnedToday(); // totalWords ve learnedToday artırır + streak günceller
        
        // XP ekle - kaynağa göre farklı XP türü (transactionId ile)
        if (source == 'daily_word') {
          await addXPForAction(XPActionTypes.dailyWordLearn, source: 'Günün Kelimesi', transactionId: txId);
        } else if (source == 'quick_dictionary') {
          await addXPForAction(XPActionTypes.quickDictionaryAdd, source: 'Hızlı Sözlük', transactionId: txId);
        } else {
          await addXPForAction(XPActionTypes.addWord, source: source, transactionId: txId);
        }
        
        notifyListeners();
      }
      return newWord;
    } catch (e) {
      print('Error adding word: $e');
      return null;
    }
  }


  /// Kelime sil
  Future<bool> deleteWord(int wordId) async {
    try {
      // 🔥 Önce silinecek kelimenin cümle sayısını al (XP hesaplaması için)
      final wordToDelete = _allWords.firstWhere((w) => w.id == wordId, orElse: () => Word(id: -1, englishWord: '', turkishMeaning: '', learnedDate: DateTime.now(), difficulty: 'easy', sentences: []));
      final sentenceCount = wordToDelete.sentences.length;
      
      await _offlineSyncService.deleteWord(wordId);
      
      // Kelimeyi listeden kaldır
      _allWords.removeWhere((w) => w.id == wordId);
      
      // İstatistikleri güncelle (Kelime sayısı ve bugün öğrenilenler)
      _userStats['totalWords'] = _allWords.length;
      
      // Eğer bugünün kelimesi silindiyse, learnedToday'i güncelle
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final learnedTodayCount = _allWords.where((w) {
         final dStr = w.learnedDate.toIso8601String().split('T')[0];
         return dStr == todayStr;
      }).length;
      
      _userStats['learnedToday'] = learnedTodayCount;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('learned_today_$todayStr', learnedTodayCount);
      
      // 🔥 XP düşür: kelime (10 XP) + her cümle (5 XP)
      // XPManager.deductXP hem local DB hem SharedPreferences'i günceller
      final xpToDeduct = 10 + (sentenceCount * 5);
      await _xpManager.deductXP(xpToDeduct, 'Kelime silindi: ${wordToDelete.englishWord}');
      
      // UI state'i de güncelle (XPManager callback'i bu işi yapacak ama yine de yapalım)
      final newTotalXp = await _xpManager.getTotalXP(forceRefresh: true);
      _userStats['xp'] = newTotalXp;
      _userStats['level'] = _xpManager.calculateLevel(newTotalXp);
      _userStats['xpToNextLevel'] = _xpManager.xpForNextLevel(newTotalXp);
      
      // Map referansını değiştir (UI güncellemesi için)
      _userStats = Map<String, dynamic>.from(_userStats);
      
      // 🔥 Silinen kelimenin cümlelerini de listeden kaldır
      _allSentences.removeWhere((s) => s.word?.id == wordId);
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting word: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SENTENCES LOADING
  // ═══════════════════════════════════════════════════════════════
  Future<void> _loadSentences() async {
    _isLoadingSentences = true;
    notifyListeners();
    
    try {
      // 🚀 Optimizasyon: Kelimeler zaten yüklüyse onları kullan
      List<Word> words = _allWords;
      if (words.isEmpty) {
        // Kelimeler henüz yüklenmemişse yükle
        words = await _offlineSyncService.getAllWords();
      }
      
      // Practice sentences'ı paralel olarak yükle
      final practiceSentences = await _offlineSyncService.getAllSentences();

      final List<SentenceViewModel> viewModels = [];
      final Set<int> seenIds = {};

      // Word Sentences - mevcut kelimelerden
      for (var word in words) {
        for (var s in word.sentences) {
          if (seenIds.contains(s.id)) continue;
          seenIds.add(s.id);
          
          viewModels.add(SentenceViewModel(
            id: s.id,
            sentence: s.sentence,
            translation: s.translation,
            difficulty: s.difficulty ?? 'easy',
            word: word,
            isPractice: false,
            date: word.learnedDate,
          ));
        }
      }

      // Practice Sentences
      for (var s in practiceSentences) {
        if (s.source != 'practice' && s.numericId != 0 && seenIds.contains(s.numericId)) continue;
        
        viewModels.add(SentenceViewModel(
          id: s.id,
          sentence: s.englishSentence,
          translation: s.turkishTranslation,
          difficulty: s.difficulty,
          word: null,
          isPractice: true,
          date: s.createdDate ?? DateTime.now(),
        ));
      }

      // Sort: Newest first
      viewModels.sort((a, b) => b.date.compareTo(a.date));

      _allSentences = viewModels;
      _isLoadingSentences = false;
      notifyListeners();
    } catch (e) {
      print('Error loading sentences: $e');
      _isLoadingSentences = false;
      notifyListeners();
    }
  }

  /// Cümleleri yenile
  Future<void> refreshSentences() async {
    await _loadSentences();
  }
  
  /// Kelimeye cümle ekle ve listeyi güncelle
  /// XP otomatik eklenir, cümle listesi anında güncellenir
  Future<Word?> addSentenceToWord({
    required int wordId,
    required String sentence,
    required String translation,
    String difficulty = 'easy',
  }) async {
    // 🆔 Transaction ID oluştur ÖNCE - içerik tabanlı (cümle hash + kelime ID)
    final txId = 'sentence_${wordId}_${sentence.toLowerCase().hashCode}';
    
    try {
      final updatedWord = await _offlineSyncService.addSentenceToWord(
        wordId: wordId,
        sentence: sentence,
        translation: translation,
        difficulty: difficulty,
      );
      
      if (updatedWord != null) {
        // Kelime listesini güncelle
        final index = _allWords.indexWhere((w) => w.id == wordId);
        if (index != -1) {
          _allWords[index] = updatedWord;
        }
        
        // XP ekle (cümle başına 5 XP) - içerik tabanlı txId ile
        await addXPForAction(XPActionTypes.addSentence, source: 'Cümle Ekleme', transactionId: txId);
        
        // Cümle listesini ANLINDA güncelle (UI hemen görsün)
        // 🔥 Önce aynı cümle var mı kontrol et (çift eklemeyi engelle)
        if (updatedWord.sentences.isNotEmpty) {
          final newSentence = updatedWord.sentences.last;
          
          // Aynı cümle zaten listede var mı?
          final alreadyExists = _allSentences.any((s) => 
            s.sentence == newSentence.sentence && 
            s.translation == newSentence.translation &&
            s.word?.id == wordId
          );
          
          if (!alreadyExists) {
            _allSentences.insert(0, SentenceViewModel(
              id: newSentence.id,
              sentence: newSentence.sentence,
              translation: newSentence.translation,
              difficulty: newSentence.difficulty ?? 'easy',
              word: updatedWord,
              isPractice: false,
              date: DateTime.now(),
            ));
          }
        }
        
        notifyListeners();
      }
      return updatedWord;
    } catch (e) {
      print('Error adding sentence: $e');
      return null;
    }
  }
  
  /// Bağımsız pratik cümlesi ekle (kelimeye bağlı olmayan)
  /// XP otomatik eklenir, cümle listesi anında güncellenir
  Future<bool> addPracticeSentence({
    required String englishSentence,
    required String turkishTranslation,
    String difficulty = 'medium',
  }) async {
    // 🆔 Transaction ID oluştur ÖNCE - içerik tabanlı
    final txId = 'practice_${englishSentence.toLowerCase().hashCode}';
    
    try {
      final newSentence = await _offlineSyncService.createSentence(
        englishSentence: englishSentence,
        turkishTranslation: turkishTranslation,
        difficulty: difficulty,
      );
      
      if (newSentence != null) {
        // 🔥 Önce aynı cümle var mı kontrol et (çift eklemeyi engelle)
        final alreadyExists = _allSentences.any((s) => 
          s.sentence == englishSentence && 
          s.translation == turkishTranslation &&
          s.isPractice == true
        );
        
        if (!alreadyExists) {
          // Cümle listesini ANLINDA güncelle (UI hemen görsün)
          _allSentences.insert(0, SentenceViewModel(
            id: newSentence.id,
            sentence: newSentence.englishSentence,
            translation: newSentence.turkishTranslation,
            difficulty: difficulty,
            word: null,
            isPractice: true,
            date: DateTime.now(),
          ));
        }
        
        // XP ekle (pratik cümlesi başına 5 XP) - içerik tabanlı txId ile
        await addXPForAction(XPActionTypes.addPracticeSentence, source: 'Pratik Cümlesi', transactionId: txId);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding practice sentence: $e');
      return false;
    }
  }

  /// Kelimeye bağlı cümleyi sil (UI anında güncellenir)
  Future<bool> deleteSentenceFromWord({required int wordId, required int sentenceId}) async {
    try {
      await _offlineSyncService.deleteSentenceFromWord(wordId: wordId, sentenceId: sentenceId);
      
      // 🔥 UI'dan anında kaldır
      _allSentences.removeWhere((s) => s.id == sentenceId);
      
      // Kelime içindeki cümleyi de güncelle
      final wordIndex = _allWords.indexWhere((w) => w.id == wordId);
      if (wordIndex != -1) {
        final word = _allWords[wordIndex];
        final updatedSentences = word.sentences.where((s) => s.id != sentenceId).toList();
        _allWords[wordIndex] = Word(
          id: word.id,
          englishWord: word.englishWord,
          turkishMeaning: word.turkishMeaning,
          learnedDate: word.learnedDate,
          difficulty: word.difficulty,
          notes: word.notes,
          sentences: updatedSentences,
        );
      }
      
      // 🔥 XP düşür: cümle başına 5 XP
      // XPManager.deductXP hem local DB hem SharedPreferences'i günceller
      await _xpManager.deductXP(5, 'Cümle silindi');
      
      // UI state'i de güncelle
      final newTotalXp = await _xpManager.getTotalXP(forceRefresh: true);
      _userStats['xp'] = newTotalXp;
      _userStats['level'] = _xpManager.calculateLevel(newTotalXp);
      _userStats['xpToNextLevel'] = _xpManager.xpForNextLevel(newTotalXp);
      
      // Map referansını değiştir (UI güncellemesi için)
      _userStats = Map<String, dynamic>.from(_userStats);
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting sentence: $e');
      return false;
    }
  }
  
  /// Pratik cümlesini sil (UI anında güncellenir)
  Future<bool> deletePracticeSentence(dynamic sentenceId) async {
    try {
      await _offlineSyncService.deletePracticeSentence(sentenceId.toString());
      
      // 🔥 UI'dan anında kaldır
      _allSentences.removeWhere((s) => s.id.toString() == sentenceId.toString() && s.isPractice);
      
      // 🔥 XP düşür: pratik cümlesi başına 5 XP
      // XPManager.deductXP hem local DB hem SharedPreferences'i günceller
      await _xpManager.deductXP(5, 'Pratik cümlesi silindi');
      
      // UI state'i de güncelle
      final newTotalXp = await _xpManager.getTotalXP(forceRefresh: true);
      _userStats['xp'] = newTotalXp;
      _userStats['level'] = _xpManager.calculateLevel(newTotalXp);
      _userStats['xpToNextLevel'] = _xpManager.xpForNextLevel(newTotalXp);
      
      // Map referansını değiştir (UI güncellemesi için)
      _userStats = Map<String, dynamic>.from(_userStats);
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting practice sentence: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DAILY WORDS (Günün Kelimeleri - AI Generated)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _loadDailyWords() async {
    _isLoadingDailyWords = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDate = prefs.getString('daily_words_date');
      final todayDate = DateTime.now().toIso8601String().split('T')[0];
      final cachedJson = prefs.getString('daily_words_cache');

      if (lastDate == todayDate && cachedJson != null) {
        // Cache'den yükle
        final List<dynamic> decoded = jsonDecode(cachedJson);
        _dailyWords = decoded.cast<Map<String, dynamic>>();
        _isLoadingDailyWords = false;
        notifyListeners();
        return;
      }

      // Yeni veri getir
      final words = await GroqService.getDailyWords();
      
      if (words.isNotEmpty) {
        _dailyWords = words;
        // Cache'e kaydet
        await prefs.setString('daily_words_date', todayDate);
        await prefs.setString('daily_words_cache', jsonEncode(words));
      }
      
      _isLoadingDailyWords = false;
      notifyListeners();
    } catch (e) {
      print('Error loading daily words: $e');
      _isLoadingDailyWords = false;
      notifyListeners();
    }
  }

  /// Günün kelimelerini yenile
  Future<void> refreshDailyWords() async {
    await _loadDailyWords();
  }

  // ═══════════════════════════════════════════════════════════════
  // XP & STATS UPDATES
  // ═══════════════════════════════════════════════════════════════
  
  /// Kullanıcı istatistiklerini manuel güncelle
  void updateUserStats(Map<String, dynamic> newStats) {
    if (newStats.isEmpty) return;
    
    newStats.forEach((key, value) {
      if (value != null) {
        _userStats[key] = value;
      }
    });
    
    notifyListeners();
  }

  /// Haftalık aktivite verisini güncelle
  void updateWeeklyActivity(List<Map<String, dynamic>> activity) {
    _weeklyActivity = activity;
    notifyListeners();
  }
  
  /// XP ekle ve state'i güncelle (eskiyi korumak için backward compatible)
  /// Öncelik: Spesifik action type methodlarını kullanın
  Future<int> addXP(int amount, {String? reason}) async {
    try {
      final added = await _xpManager.addCustomXP(amount, reason ?? 'custom');
      
      // WeeklyXP'yi de güncelle
      _userStats['weeklyXP'] = (_userStats['weeklyXP'] ?? 0) + added;
      
      // Level kontrolü
      final totalXP = _userStats['xp'] ?? 0;
      _userStats['level'] = _xpManager.calculateLevel(totalXP);
      _userStats['xpToNextLevel'] = _xpManager.xpForNextLevel(totalXP);
      
      notifyListeners();
      return added;
    } catch (e) {
      print('Error adding XP: $e');
      return 0;
    }
  }

  /// XP Manager'ı direkt kullanarak spesifik aksiyon için XP ekle
  /// [transactionId]: Opsiyonel benzersiz işlem ID'si - idempotency için
  Future<int> addXPForAction(XPActionType action, {String? source, String? transactionId}) async {
    try {
      final added = await _xpManager.addXP(action, source: source, transactionId: transactionId);
      return added;

    } catch (e) {
      print('Error adding XP for action: $e');
      return 0;
    }
  }

  /// Bugün öğrenilen kelime sayısını artır ve kalıcı olarak kaydet
  Future<void> incrementLearnedToday() async {
    _userStats['learnedToday'] = (_userStats['learnedToday'] ?? 0) + 1;
    // totalWords = veritabanındaki gerçek kelime sayısı
    _userStats['totalWords'] = _allWords.length;
    
    // SharedPreferences'a kaydet
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _now.toIso8601String().split('T')[0];
    final learnedTodayKey = 'learned_today_$todayStr';
    await prefs.setInt(learnedTodayKey, _userStats['learnedToday']);
    
    // Streak güncelle
    await _updateStreak();
    
    // Haftalık aktiviteyi güncelle
    _updateWeeklyActivityForToday();
    
    notifyListeners();
    
    // Günlük hedef kontrolü
    await _checkDailyGoal();
  }

  
  /// Test için tarih mocklama
  @visibleForTesting
  DateTime? mockDate;

  DateTime get _now => mockDate ?? DateTime.now();

  /// Streak'i güncelle ve kaydet
  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _now.toIso8601String().split('T')[0];
    final lastActivityDate = prefs.getString('last_activity_date');
    
    int currentStreak = prefs.getInt('current_streak') ?? 0;
    
    if (lastActivityDate == null) {
      // İlk aktivite
      currentStreak = 1;
    } else if (lastActivityDate != todayStr) {
      final lastDate = DateTime.parse(lastActivityDate);
      final today = DateTime.parse(todayStr);
      final diffDays = today.difference(lastDate).inDays;
      
      if (diffDays == 1) {
        // Ardışık gün, streak artır
        currentStreak += 1;
      } else if (diffDays > 1) {
        // Seri kırıldı, yeniden başla
        currentStreak = 1;
      }
      // diffDays == 0 ise aynı gün, streak değişmez
    }
    
    // Kaydet
    await prefs.setString('last_activity_date', todayStr);
    await prefs.setInt('current_streak', currentStreak);
    
    _userStats['streak'] = currentStreak;
    
    // Streak bonuslarını kontrol et
    await _xpManager.checkAndAwardStreakBonus(currentStreak);
  }

  /// Günlük hedef kontrolü
  Future<void> _checkDailyGoal() async {
    final learnedToday = _userStats['learnedToday'] ?? 0;
    final dailyGoal = _userStats['dailyGoal'] ?? 5;
    
    if (learnedToday >= dailyGoal) {
      await _xpManager.checkDailyGoal(learnedToday, dailyGoal);
    }
  }

  /// Streak bonuslarını kontrol et
  Future<void> checkStreakBonus() async {
    final streak = _userStats['streak'] ?? 0;
    await _xpManager.checkAndAwardStreakBonus(streak);
  }
  
  /// Bugünkü haftalık aktiviteyi güncelle
  void _updateWeeklyActivityForToday() {
    final today = _now;
    final dayIndex = today.weekday - 1; // 0 = Pazartesi, 6 = Pazar
    
    if (_weeklyActivity.isEmpty) {
      // Haftalık aktivite listesi oluştur
      final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      _weeklyActivity = List.generate(7, (i) => <String, dynamic>{
        'day': days[i],
        'count': 0,
        'learned': false,
      });
    }
    
    if (dayIndex >= 0 && dayIndex < _weeklyActivity.length) {
      final currentCount = _weeklyActivity[dayIndex]['count'] ?? 0;
      _weeklyActivity[dayIndex] = {
        ..._weeklyActivity[dayIndex],
        'count': currentCount + 1,
        'learned': true,
      };
    }
  }

  /// XP Manager getter (diğer servisler için)
  XPManager get xpManager => _xpManager;
}
