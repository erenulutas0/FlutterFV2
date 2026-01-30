import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/offline_sync_service.dart';
import '../services/user_data_service.dart';
import '../services/auth_service.dart';
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
  // INITIALIZATION - Uygulama açılışında çağrılır
  // ═══════════════════════════════════════════════════════════════
  Future<void> initialize() async {
    if (_isInitialized) return; // Tekrar çağrılmasın
    
    // Paralel yükle
    await Future.wait([
      _loadUserData(),
      _loadWords(),
      _loadSentences(),
      _loadDailyWords(),
    ]);
    
    _isInitialized = true;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // USER DATA LOADING
  // ═══════════════════════════════════════════════════════════════
  Future<void> _loadUserData() async {
    try {
      final authUser = await _authService.getUser();
      final displayName = authUser?['displayName'] ?? 'Kullanıcı';
      
      final stats = await _userDataService.getAllStats();
      final weekly = await _userDataService.getWeeklyActivity();
      
      // Profile settings
      final prefs = await SharedPreferences.getInstance();
      final type = prefs.getString('profile_image_type') ?? 'avatar';
      final path = prefs.getString('profile_image_path');
      final seed = prefs.getString('profile_avatar_seed') ?? displayName;

      _userName = displayName;
      _userInfo = authUser; // Store full user info
      _userStats = stats;
      _weeklyActivity = weekly;
      _profileImageType = type;
      _profileImagePath = path;
      _avatarSeed = seed;
      
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
    }
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
  Future<Word?> addWord({
    required String english,
    required String turkish,
    required DateTime addedDate,
    required String difficulty,
  }) async {
    try {
      final newWord = await _offlineSyncService.createWord(
        english: english,
        turkish: turkish,
        addedDate: addedDate,
        difficulty: difficulty,
      );
      if (newWord != null) {
        _allWords.insert(0, newWord); // Başa ekle
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
      await _offlineSyncService.deleteWord(wordId);
      _allWords.removeWhere((w) => w.id == wordId);
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
    
    try {
      final words = await _offlineSyncService.getAllWords();
      final practiceSentences = await _offlineSyncService.getAllSentences();

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
  
  /// XP ekle ve state'i güncelle
  Future<void> addXP(int amount) async {
    try {
      _userStats['xp'] = (_userStats['xp'] ?? 0) + amount;
      _userStats['weeklyXP'] = (_userStats['weeklyXP'] ?? 0) + amount;
      notifyListeners();
      
      // Arka planda gerçek veriyi kaydet
      // await _userDataService.addXP(amount);
    } catch (e) {
      print('Error adding XP: $e');
    }
  }

  /// Bugün öğrenilen kelime sayısını artır
  void incrementLearnedToday() {
    _userStats['learnedToday'] = (_userStats['learnedToday'] ?? 0) + 1;
    _userStats['totalWords'] = (_userStats['totalWords'] ?? 0) + 1;
    notifyListeners();
  }
}
