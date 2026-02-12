import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/word.dart';
import '../models/sentence_practice.dart';
import 'local_database_service.dart';
import 'api_service.dart';

/// Offline/Online durumu yönetir ve senkronizasyon işlemlerini gerçekleştirir
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  static bool _forceTestMode = false;
  @visibleForTesting
  static void enableTestMode() {
    _forceTestMode = true;
    _instance._connectivity = _TestConnectivity();
  }

  final LocalDatabaseService _localDb = LocalDatabaseService();
  ApiService _apiService = ApiService();
  Connectivity _connectivity = Connectivity();

  /// Test için bağımlılıkları dışarıdan ver
  @visibleForTesting
  void setDependenciesForTesting({ApiService? apiService, Connectivity? connectivity}) {
    if (apiService != null) _apiService = apiService;
    if (connectivity != null) _connectivity = connectivity;
  }

  /// Test için durumu sıfırla
  @visibleForTesting
  void resetStatusForTesting() {
    _isOnline = true;
    _isSyncing = false;
    _isCheckingConnectivity = false;
    _lastConnectivityCheck = null; // Testler gerçek check'i tetiklesin
  }


  bool _isOnline = true;

  bool _isSyncing = false;
  bool _isCheckingConnectivity = false; // Paralel kontrolleri engelle
  DateTime? _lastConnectivityCheck; // Son kontrol zamanı
  static const Duration _connectivityCacheDuration = Duration(minutes: 2); // 2 dakika cache - daha az kontrol
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final StreamController<bool> _onlineStatusController = StreamController<bool>.broadcast();

  /// Online durumu stream
  Stream<bool> get onlineStatus => _onlineStatusController.stream;
  
  /// Anlık online durumu
  bool get isOnline => _isOnline;

  /// Servisi başlat
  Future<void> initialize() async {
    // İlk durum kontrolü
    await _checkConnectivity(force: true);

    // Bağlantı değişikliklerini dinle
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) async {
      final wasOnline = _isOnline;
      final hasNetwork = !result.contains(ConnectivityResult.none);
      
      // Ağ durumu değiştiyse kontrol et
      if (hasNetwork != _isOnline || !hasNetwork) {
        _isOnline = hasNetwork;
        _onlineStatusController.add(_isOnline);
        
        // Offline'dan online'a geçtiyse senkronize et
        if (!wasOnline && _isOnline) {
          print('📶 Bağlantı geri geldi, senkronizasyon başlatılıyor...');
          await syncWithServer();
        }
      }
    });
  }

  /// Bağlantı durumunu kontrol et (cache'li)
  Future<bool> _checkConnectivity({bool force = false}) async {
    // Eğer zaten kontrol yapılıyorsa bekle
    if (_isCheckingConnectivity) {
      return _isOnline;
    }
    
    // Cache süresi dolmadıysa mevcut durumu döndür
    if (!force && _lastConnectivityCheck != null) {
      final elapsed = DateTime.now().difference(_lastConnectivityCheck!);
      if (elapsed < _connectivityCacheDuration) {
        return _isOnline;
      }
    }
    
    _isCheckingConnectivity = true;
    
    try {
      final result = await _connectivity.checkConnectivity();
      final hasNetwork = !result.contains(ConnectivityResult.none);
      final isTest = _forceTestMode || const bool.fromEnvironment('FLUTTER_TEST');
      
      if (!hasNetwork) {
        _isOnline = false;
        _lastConnectivityCheck = DateTime.now();
        _onlineStatusController.add(_isOnline);
        _isCheckingConnectivity = false;
        return false;
      }

      // Test ortamında gerçek HTTP ping yapma
      if (isTest) {
        _isOnline = true;
        _lastConnectivityCheck = DateTime.now();
        _onlineStatusController.add(_isOnline);
        _isCheckingConnectivity = false;
        return true;
      }
      
      // Gerçek internet erişimi kontrolü (sadece ağ varsa)
      try {
        final baseUrl = await AppConfig.apiBaseUrl;
        final response = await http.get(
          Uri.parse('$baseUrl/words'),
        ).timeout(const Duration(seconds: 5));
        
        _isOnline = response.statusCode == 200;
      } catch (e) {
        // API erişilemeyen durumda offline gibi davran ama sessizce
        _isOnline = false;
      }
      
      _lastConnectivityCheck = DateTime.now();
      _onlineStatusController.add(_isOnline);
      _isCheckingConnectivity = false;
      return _isOnline;
    } catch (e) {
      _isOnline = false;
      _lastConnectivityCheck = DateTime.now();
      _onlineStatusController.add(_isOnline);
      _isCheckingConnectivity = false;
      return false;
    }
  }

  /// Servisi durdur
  void dispose() {
    _connectivitySubscription?.cancel();
    _onlineStatusController.close();
  }

  // ==================== WORDS ====================

  /// Tüm kelimeleri getir - LOCAL FIRST yaklaşımı
  /// Önce local DB'den anında veriler döner, arka planda API sync yapılır
  Future<List<Word>> getAllWords() async {
    // 🚀 LOCAL FIRST: Önce local'den hemen döndür
    final localWords = await _localDb.getAllWords();
    
    if (localWords.isNotEmpty) {
      // Local veri varsa hemen döndür, arka planda sync yap
      _syncWordsInBackground();
      return localWords;
    }
    
    // Local boşsa, connectivity check yap ve API'den çek
    await _checkConnectivity();
    
    if (_isOnline) {
      try {
        final words = await _apiService.getAllWords();
        if (words.isNotEmpty) {
          await _localDb.saveAllWords(words);
        }
        return words;
      } catch (e) {
        print('🔴 API hatası: $e');
        return [];
      }
    }
    
    return [];
  }
  
  /// 🚀 HIZLI: Sadece local veritabanından kelimeleri al (API çağrısı yok)
  Future<List<Word>> getLocalWords() async {
    return await _localDb.getAllWords();
  }
  
  /// 🚀 HIZLI: Sadece local veritabanından practice sentences al (API çağrısı yok)
  Future<List<SentencePractice>> getLocalSentences() async {
    return await _localDb.getAllPracticeSentences();
  }
  
  /// Bekleyen değişiklikleri API'ye gönder
  Future<void> syncPendingChanges() async {
    if (_isSyncing) return;
    _isSyncing = true;
    
    try {
      await _checkConnectivity();
      if (_isOnline) {
        // Sync queue'daki bekleyen işlemleri gönder
        await _processSyncQueue();
        // API'den güncel verileri çek
        _syncWordsInBackground();
        // Not: Sentences API sync henüz implementasyonda değil
      }
    } catch (e) {
      print('🔄 Sync pending changes error: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Sync queue'daki işlemleri işle
  Future<void> _processSyncQueue() async {
    try {
      final queue = await _localDb.getSyncQueue();
      for (var item in queue) {
        try {
          // Her bir işlemi API'ye gönder
          await _processSyncItem(item);
          // Başarılıysa queue'dan sil
          await _localDb.removeSyncQueueItem(item['id']);
        } catch (e) {
          print('Sync item error: $e');
        }
      }
    } catch (e) {
      print('Process sync queue error: $e');
    }
  }
  
  /// Tek bir sync item'ı işle
  Future<void> _processSyncItem(Map<String, dynamic> item) async {
    final action = item['action'];
    final tableName = item['tableName'];
    final data = item['data'] != null ? jsonDecode(item['data']) : {};
    
    switch (action) {
      case 'create':
        if (tableName == 'words') {
          await _apiService.createWord(
            english: data['english'],
            turkish: data['turkish'],
            addedDate: DateTime.parse(data['addedDate']),
            difficulty: data['difficulty'] ?? 'easy',
          );
        } else if (tableName == 'sentences') {
          await _apiService.addSentenceToWord(
            wordId: data['wordId'],
            sentence: data['sentence'],
            translation: data['translation'],
            difficulty: data['difficulty'] ?? 'easy',
          );
        }
        break;
      case 'delete':
        if (tableName == 'words') {
          await _apiService.deleteWord(int.parse(item['itemId']));
        } else if (tableName == 'sentences') {
          await _apiService.deleteSentenceFromWord(
            data['wordId'],
            int.parse(item['itemId']),
          );
        }
        break;
    }
  }

  /// Arka planda API'den kelimeleri sync et (UI'ı bloklamaz)
  void _syncWordsInBackground() {
    if (_forceTestMode || const bool.fromEnvironment('FLUTTER_TEST')) return;
    // Fire and forget - arka planda çalışır
    Future(() async {
      try {
        if (!_isOnline) {
          await _checkConnectivity();
        }
        if (_isOnline) {
          final words = await _apiService.getAllWords();
          if (words.isNotEmpty) {
            await _localDb.saveAllWords(words);
          }
        }
      } catch (e) {
        // Sessizce hata logla
        print('🔄 Background sync error: $e');
      }
    });
  }
  
  /// Kelime oluştur - OPTIMISTIC UPDATE
  /// Önce local'e kaydet (anında görünsün), sonra arka planda API'ye gönder
  Future<Word?> createWord({
    required String english,
    required String turkish,
    required DateTime addedDate,
    String difficulty = 'easy',
  }) async {
    // 🚀 OPTIMISTIC UPDATE: Önce local'e kaydet ve hemen döndür
    final localId = await _localDb.createWordOffline(
      english: english,
      turkish: turkish,
      addedDate: addedDate,
      difficulty: difficulty,
    );
    
    final localWord = Word(
      id: localId,
      englishWord: english,
      turkishMeaning: turkish,
      learnedDate: addedDate,
      difficulty: difficulty,
      sentences: [],
    );
    
    // Test ortamında senkronizasyonu inline yap (deterministik)
    final isTest = _forceTestMode || const bool.fromEnvironment('FLUTTER_TEST');
    if (isTest) {
      final result = await _connectivity.checkConnectivity();
      final hasNetwork = !result.contains(ConnectivityResult.none);
      if (hasNetwork) {
        await _syncWordToAPIWithoutConnectivityCheck(localWord);
      }
    } else {
      // Arka planda API'ye gönder (UI'ı bloklamaz)
      _syncWordToAPIInBackground(localWord);
    }
    
    return localWord;
  }
  
  /// Arka planda kelimeyi API'ye sync et
  void _syncWordToAPIInBackground(Word localWord) {
    Future(() async {
      await _syncWordToAPI(localWord);
    });
  }

  Future<void> _syncWordToAPI(Word localWord) async {
    try {
      await _checkConnectivity();
      if (_isOnline) {
        final serverWord = await _apiService.createWord(
          english: localWord.englishWord,
          turkish: localWord.turkishMeaning,
          addedDate: localWord.learnedDate,
          difficulty: localWord.difficulty,
        );

        // BAŞARILI: Sync queue'dan bu işlemi sil (ID'ler güncellenmeden önce yap)
        final queue = await _localDb.getSyncQueue();
        final item = queue.firstWhere(
          (q) => q['tableName'] == 'words' && q['itemId'] == localWord.id.toString() && q['action'] == 'create',
          orElse: () => <String, dynamic>{},
        );

        if (item.isNotEmpty) {
          await _localDb.removeSyncQueueItem(item['id']);
        }

        // Şimdi yerel veritabanındaki ID'leri güncelle
        await _localDb.updateLocalIdToServerId('words', localWord.id, serverWord.id);
        await _localDb.saveWord(serverWord);
      }
      // else: Offline ise queue'da zaten var (createWordOffline ekledi)
    } catch (e) {
      print('🔄 Background word sync error: $e');
      // Hata durumunda queue'da zaten var, bir şey yapmaya gerek yok
    }
  }

  Future<void> _syncWordToAPIWithoutConnectivityCheck(Word localWord) async {
    try {
      final serverWord = await _apiService.createWord(
        english: localWord.englishWord,
        turkish: localWord.turkishMeaning,
        addedDate: localWord.learnedDate,
        difficulty: localWord.difficulty,
      );

      final queue = await _localDb.getSyncQueue();
      final item = queue.firstWhere(
        (q) => q['tableName'] == 'words' && q['itemId'] == localWord.id.toString() && q['action'] == 'create',
        orElse: () => <String, dynamic>{},
      );

      if (item.isNotEmpty) {
        await _localDb.removeSyncQueueItem(item['id']);
      }

      await _localDb.updateLocalIdToServerId('words', localWord.id, serverWord.id);
      await _localDb.saveWord(serverWord);
    } catch (e) {
      print('🔄 Background word sync error: $e');
    }
  }


  /// Kelime sil - OPTIMISTIC UPDATE 
  /// Önce local'den sil (anında görünsün), sonra arka planda API'ye gönder
  Future<bool> deleteWord(int wordId) async {
    // 🚀 OPTIMISTIC UPDATE: Önce local'den sil ve hemen dön
    await _localDb.deleteWord(wordId);
    
    // Arka planda API'ye gönder
    _deleteWordFromAPIInBackground(wordId);
    
    return true;
  }
  
  /// Arka planda kelimeyi API'den sil
  void _deleteWordFromAPIInBackground(int wordId) {
    if (wordId <= 0) return; // Negatif ID'ler (local-only) için API çağrısı yapma
    
    Future(() async {
      try {
        await _checkConnectivity();
        if (_isOnline) {
          await _apiService.deleteWord(wordId);
        } else {
          await _localDb.addToSyncQueue('delete', 'words', wordId.toString(), {});
        }
      } catch (e) {
        print('🔄 Background word delete error: $e');
        await _localDb.addToSyncQueue('delete', 'words', wordId.toString(), {});
      }
    });
  }

  /// Kelimeye cümle ekle - OPTIMISTIC UPDATE
  /// Önce local'e kaydet (anında görünsün), sonra arka planda API'ye gönder
  Future<Word?> addSentenceToWord({
    required int wordId,
    required String sentence,
    required String translation,
    String difficulty = 'easy',
  }) async {
    // 🚀 OPTIMISTIC UPDATE: Önce local'e kaydet ve hemen döndür
    final sentenceId = await _localDb.addSentenceToWordOffline(
      wordId: wordId,
      sentence: sentence,
      translation: translation,
      difficulty: difficulty,
    );
    
    // Güncel kelimeyi hemen döndür
    final updatedWord = await _getWordWithNewSentence(wordId, sentenceId, sentence, translation, difficulty);
    
    // Arka planda API'ye gönder
    _syncSentenceToAPIInBackground(wordId, sentence, translation, difficulty);
    
    return updatedWord;
  }
  
  /// Arka planda cümleyi API'ye sync et
  void _syncSentenceToAPIInBackground(int wordId, String sentence, String translation, String difficulty) {
    if (wordId <= 0) return;
    if (_forceTestMode || const bool.fromEnvironment('FLUTTER_TEST')) return;
    
    Future(() async {
      try {
        await _checkConnectivity();
        if (_isOnline) {
          final word = await _apiService.addSentenceToWord(
            wordId: wordId,
            sentence: sentence,
            translation: translation,
            difficulty: difficulty,
          );
          await _localDb.saveWord(word);
        }
      } catch (e) {
        print('🔄 Background sentence sync error: $e');
      }
    });
  }
  
  /// Yeni cümle eklenmiş kelimeyi döndür (offline durumlar için helper)
  Future<Word?> _getWordWithNewSentence(int wordId, int sentenceId, String sentence, String translation, String difficulty) async {
    try {
      // Veritabanı zaten cümleyi içeriyor (addSentenceToWordOffline ile eklendi)
      // Güncel kelimeyi veritabanından al ve döndür
      final words = await _localDb.getAllWords();
      final word = words.firstWhere(
        (w) => w.id == wordId, 
        orElse: () => Word(id: -1, englishWord: '', turkishMeaning: '', learnedDate: DateTime.now(), difficulty: 'easy', sentences: [])
      );
      
      if (word.id == -1) return null;
      
      return word; // Cümle zaten veritabanından alındı, tekrar eklemeye gerek yok
    } catch (e) {
      print('Error getting word with new sentence: $e');
      return null;
    }
  }

  /// Kelimeden cümle sil
  Future<bool> deleteSentenceFromWord({
    required int wordId,
    required int sentenceId,
  }) async {
    await _checkConnectivity();
    
    if (_isOnline && wordId > 0 && sentenceId > 0) {
      try {
        // Online: API'den sil
        await _apiService.deleteSentenceFromWord(wordId, sentenceId);
        // Local'den de sil
        await _localDb.deleteSentenceFromWord(wordId, sentenceId);
        return true;
      } catch (e) {
        print('🔴 API hatası, offline silme yapılıyor: $e');
        await _localDb.deleteSentenceFromWord(wordId, sentenceId);
        await _localDb.addToSyncQueue('delete', 'sentences', sentenceId.toString(), {'wordId': wordId});
        return true;
      }
    } else {
      // Offline: Local veritabanından sil ve sync queue'ya ekle
      print('📴 Offline mod: Cümle lokal siliniyor');
      await _localDb.deleteSentenceFromWord(wordId, sentenceId);
      await _localDb.addToSyncQueue('delete', 'sentences', sentenceId.toString(), {'wordId': wordId});
      return true;
    }
  }

  // ==================== PRACTICE SENTENCES ====================

  /// Tüm practice sentences getir - LOCAL FIRST yaklaşımı
  Future<List<SentencePractice>> getAllSentences() async {
    // 🚀 LOCAL FIRST: Önce local'den hemen döndür
    final localSentences = await _localDb.getAllPracticeSentences();
    
    if (localSentences.isNotEmpty) {
      // Local veri varsa hemen döndür, arka planda sync yap
      _syncSentencesInBackground();
      return localSentences;
    }
    
    // Local boşsa, connectivity check yap ve API'den çek
    await _checkConnectivity();
    
    if (_isOnline) {
      try {
        final sentences = await _apiService.getAllSentences();
        if (sentences.isNotEmpty) {
          await _localDb.saveAllPracticeSentences(sentences);
        }
        return sentences;
      } catch (e) {
        print('🔴 API hatası: $e');
        return [];
      }
    }
    
    return [];
  }
  
  /// Arka planda API'den cümleleri sync et
  void _syncSentencesInBackground() {
    if (_forceTestMode || const bool.fromEnvironment('FLUTTER_TEST')) return;
    Future(() async {
      try {
        if (!_isOnline) await _checkConnectivity();
        if (_isOnline) {
          final sentences = await _apiService.getAllSentences();
          if (sentences.isNotEmpty) {
            await _localDb.saveAllPracticeSentences(sentences);
          }
        }
      } catch (e) {
        print('🔄 Background sentences sync error: $e');
      }
    });
  }

  /// Practice sentence oluştur
  Future<SentencePractice?> createSentence({
    required String englishSentence,
    required String turkishTranslation,
    required String difficulty,
  }) async {
    await _checkConnectivity();
    
    if (_isOnline) {
      try {
        final sentence = await _apiService.createSentence(
          englishSentence: englishSentence,
          turkishTranslation: turkishTranslation,
          difficulty: difficulty,
        );
        await _localDb.savePracticeSentence(sentence);
        // XP artık AppStateProvider tarafından yönetiliyor
        return sentence;
      } catch (e) {
        print('🔴 API hatası, offline kayıt yapılıyor: $e');
        final id = await _localDb.createPracticeSentenceOffline(
          englishSentence: englishSentence,
          turkishTranslation: turkishTranslation,
          difficulty: difficulty,
        );
        return SentencePractice(
          id: id,
          englishSentence: englishSentence,
          turkishTranslation: turkishTranslation,
          difficulty: difficulty.toUpperCase(),
          createdDate: DateTime.now(),
          source: 'practice',
        );
      }
    } else {
      print('📴 Offline mod: Cümle lokal kaydediliyor');
      final id = await _localDb.createPracticeSentenceOffline(
        englishSentence: englishSentence,
        turkishTranslation: turkishTranslation,
        difficulty: difficulty,
      );
      return SentencePractice(
        id: id,
        englishSentence: englishSentence,
        turkishTranslation: turkishTranslation,
        difficulty: difficulty.toUpperCase(),
        createdDate: DateTime.now(),
        source: 'practice',
      );
    }
  }

  /// Practice sentence sil
  Future<void> deletePracticeSentence(String id) async {
    await _checkConnectivity();

    // Sadece server ID'leri için API çağrısı yap (temp/local değilse)
    bool isServerId = !id.startsWith('temp_') && !id.startsWith('local_');

    if (_isOnline) {
      if (isServerId) {
        try {
          // 'practice_' prefix'ini kaldır
          final apiId = id.replaceFirst('practice_', '');
          await _apiService.deleteSentence(apiId);
        } catch (e) {
          print('🔴 API hatası, offline silme kuyruğa ekleniyor: $e');
          await _localDb.addToSyncQueue('delete', 'practice_sentences', id, {});
        }
      }
      // Local DB'den her durumda sil
      await _localDb.deletePracticeSentence(id);
    } else {
      await _localDb.deletePracticeSentence(id);
      if (isServerId) {
        await _localDb.addToSyncQueue('delete', 'practice_sentences', id, {});
      }
    }
  }

  // ==================== DATES ====================

  /// Benzersiz tarihleri getir
  Future<List<String>> getAllDistinctDates() async {
    await _checkConnectivity();
    
    if (_isOnline) {
      try {
        return await _apiService.getAllDistinctDates();
      } catch (e) {
        return await _localDb.getAllDistinctDates();
      }
    } else {
      return await _localDb.getAllDistinctDates();
    }
  }

  /// Tarihe göre kelimeleri getir
  Future<List<Word>> getWordsByDate(DateTime date) async {
    await _checkConnectivity();
    
    if (_isOnline) {
      try {
        final words = await _apiService.getWordsByDate(date);
        return words;
      } catch (e) {
        return await _localDb.getWordsByDate(date);
      }
    } else {
      return await _localDb.getWordsByDate(date);
    }
  }

  // ==================== XP ====================

  /// Toplam XP getir (local + pending)
  Future<int> getTotalXp() async {
    return await _localDb.getTotalXp();
  }

  /// Pending XP getir
  Future<int> getPendingXp() async {
    return await _localDb.getPendingXp();
  }

  /// XP ekle (ve local DB'ye kaydet)
  Future<void> addXp(int amount) async {
    await _localDb.addXp(amount);
  }

  // ==================== SYNC ====================

  /// Sunucu ile senkronize et
  Future<bool> syncWithServer() async {
    if (_isSyncing) {
      print('⏳ Senkronizasyon zaten devam ediyor...');
      return false;
    }

    if (!_isOnline) {
      print('📴 Offline - senkronizasyon atlanıyor');
      return false;
    }

    _isSyncing = true;
    print('🔄 Senkronizasyon başlatıldı...');

    try {
      // 1. Bekleyen işlemleri gönder
      final pendingItems = await _localDb.getPendingSyncItems();
      print('📝 ${pendingItems.length} bekleyen işlem bulundu');

      for (var item in pendingItems) {
        try {
          await _processSyncItem(item);
          await _localDb.markSyncItemCompleted(item['id'] as int);
        } catch (e) {
          print('🔴 Sync item hatası: $e');
          // Hatalı item'ları atla, sonra tekrar dene
        }
      }

      // 2. Sunucudan güncel verileri al
      final serverWords = await _apiService.getAllWords();
      if (serverWords.isNotEmpty) {
        await _localDb.saveAllWords(serverWords);
      }

      final serverSentences = await _apiService.getAllSentences();
      if (serverSentences.isNotEmpty) {
        await _localDb.saveAllPracticeSentences(serverSentences);
      }

      // 3. XP'yi senkronize et (server XP + pending XP)
      // Not: Gerçek uygulamada server'dan XP almak gerekir
      // Şimdilik local XP'yi koruyoruz
      await _localDb.markXpSynced();

      print('✅ Senkronizasyon tamamlandı');
      _isSyncing = false;
      return true;
    } catch (e) {
      print('🔴 Senkronizasyon hatası: $e');
      _isSyncing = false;
      return false;
    }
  }

  /// İlk veri yüklemesi (uygulama başlangıcında)
  Future<void> initialDataLoad() async {
    await _checkConnectivity();
    
    if (_isOnline) {
      try {
        // Online: Sunucudan al ve local'e kaydet
        final words = await _apiService.getAllWords();
        if (words.isNotEmpty) {
          await _localDb.saveAllWords(words);
        }

        final sentences = await _apiService.getAllSentences();
        if (sentences.isNotEmpty) {
          await _localDb.saveAllPracticeSentences(sentences);
        }

        print('✅ İlk veri yüklemesi tamamlandı: ${words.length} kelime, ${sentences.length} cümle');
      } catch (e) {
        print('🔴 İlk veri yüklemesi hatası: $e');
      }
    }
  }
}

class _TestConnectivity implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return [ConnectivityResult.none];
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return const Stream<List<ConnectivityResult>>.empty();
  }

  @override
  Future<void> deleteService() async {}

  @override
  Future<String?> getWifiBSSID() async => null;

  @override
  Future<String?> getWifiIP() async => null;

  @override
  Future<String?> getWifiName() async => null;
}
