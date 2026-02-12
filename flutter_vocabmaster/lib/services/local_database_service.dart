import 'dart:async';
import 'dart:isolate';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word.dart';
import '../models/sentence_practice.dart';

/// Yerel SQLite veritabanı yönetimi
/// Offline modu destekler ve senkronizasyon için pending işlemleri takip eder
class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _database;
  String? _dbPath;
  static bool _forceTestMode = false;

  @visibleForTesting
  static void enableTestMode() {
    _forceTestMode = true;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final isTest = _forceTestMode || const bool.fromEnvironment('FLUTTER_TEST');
    final dbName = isTest
        ? 'vocabmaster_offline_test_${Isolate.current.hashCode}.db'
        : 'vocabmaster_offline.db';
    final path = join(dbPath, dbName);
    _dbPath = path;

    return await openDatabase(
      path,
      version: 2,
      singleInstance: !isTest,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS xp_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            actionId TEXT NOT NULL,
            actionName TEXT NOT NULL,
            amount INTEGER NOT NULL,
            source TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  @visibleForTesting
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Words tablosu
    await db.execute('''
      CREATE TABLE words (
        id INTEGER PRIMARY KEY,
        localId INTEGER,
        englishWord TEXT NOT NULL,
        turkishMeaning TEXT NOT NULL,
        learnedDate TEXT NOT NULL,
        notes TEXT,
        difficulty TEXT DEFAULT 'easy',
        syncStatus TEXT DEFAULT 'synced',
        createdAt TEXT NOT NULL
      )
    ''');

    // Sentences tablosu (kelimelere ait)
    await db.execute('''
      CREATE TABLE sentences (
        id INTEGER PRIMARY KEY,
        localId INTEGER,
        wordId INTEGER,
        localWordId INTEGER,
        sentence TEXT NOT NULL,
        translation TEXT NOT NULL,
        difficulty TEXT,
        syncStatus TEXT DEFAULT 'synced',
        createdAt TEXT NOT NULL,
        FOREIGN KEY (wordId) REFERENCES words(id)
      )
    ''');

    // Practice sentences tablosu (bağımsız cümleler)
    await db.execute('''
      CREATE TABLE practice_sentences (
        id TEXT PRIMARY KEY,
        localId INTEGER,
        englishSentence TEXT NOT NULL,
        turkishTranslation TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        createdDate TEXT NOT NULL,
        source TEXT DEFAULT 'practice',
        syncStatus TEXT DEFAULT 'synced',
        createdAt TEXT NOT NULL
      )
    ''');

    // XP ve kullanıcı istatistikleri tablosu
    await db.execute('''
      CREATE TABLE user_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        totalXp INTEGER DEFAULT 0,
        lastSyncedXp INTEGER DEFAULT 0,
        pendingXp INTEGER DEFAULT 0,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Pending sync queue tablosu
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        tableName TEXT NOT NULL,
        itemId TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        status TEXT DEFAULT 'pending'
      )
    ''');

    // XP geçmişi tablosu
    await db.execute('''
      CREATE TABLE xp_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actionId TEXT NOT NULL,
        actionName TEXT NOT NULL,
        amount INTEGER NOT NULL,
        source TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // İlk kullanıcı stats kaydı
    await db.insert('user_stats', {
      'totalXp': 0,
      'lastSyncedXp': 0,
      'pendingXp': 0,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Yeni tablolar ekle
      await _onCreate(db, newVersion);
    }
    // XP history tablosu eksikse ekle (korumalı)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS xp_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actionId TEXT NOT NULL,
        actionName TEXT NOT NULL,
        amount INTEGER NOT NULL,
        source TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // ==================== WORDS ====================

  /// Tüm kelimeleri getir (yerel)
  Future<List<Word>> getAllWords() async {
    final db = await database;
    final List<Map<String, dynamic>> wordMaps = await db.query('words', orderBy: 'learnedDate DESC');
    
    List<Word> words = [];
    for (var wordMap in wordMaps) {
      final rawWordId = wordMap['id'];
      final rawLocalId = wordMap['localId'];
      final intWordId = (rawWordId is int) ? rawWordId : (rawWordId is num) ? rawWordId.toInt() : 0;
      final intLocalId = (rawLocalId is int) ? rawLocalId : (rawLocalId is num) ? rawLocalId.toInt() : intWordId;
      final sentences = await db.query(
        'sentences',
        where: 'wordId = ? OR localWordId = ?',
        whereArgs: [intWordId, intLocalId],
      );
      
      words.add(Word(
        id: intWordId != 0 ? intWordId : intLocalId,
        englishWord: wordMap['englishWord'] ?? '',
        turkishMeaning: wordMap['turkishMeaning'] ?? '',
        learnedDate: DateTime.parse(wordMap['learnedDate']),
        notes: wordMap['notes'],
        difficulty: wordMap['difficulty'] ?? 'easy',
        sentences: sentences.map((s) => Sentence(
          id: s['id'] as int? ?? s['localId'] as int? ?? 0,
          sentence: s['sentence'] as String? ?? '',
          translation: s['translation'] as String? ?? '',
          wordId: wordMap['id'] ?? wordMap['localId'] ?? 0,
          difficulty: s['difficulty'] as String?,
        )).toList(),
      ));
    }
    
    return words;
  }

  /// Kelime kaydet (online'dan gelen)
  Future<void> saveWord(Word word) async {
    final db = await database;
    
    await db.insert('words', {
      'id': word.id,
      'englishWord': word.englishWord,
      'turkishMeaning': word.turkishMeaning,
      'learnedDate': word.learnedDate.toIso8601String().split('T')[0],
      'notes': word.notes,
      'difficulty': word.difficulty,
      'syncStatus': 'synced',
      'createdAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Sentences kaydet
    for (var sentence in word.sentences) {
      await db.insert('sentences', {
        'id': sentence.id,
        'wordId': word.id,
        'sentence': sentence.sentence,
        'translation': sentence.translation,
        'difficulty': sentence.difficulty,
        'syncStatus': 'synced',
        'createdAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Tüm kelimeleri kaydet (bulk)
  Future<void> saveAllWords(List<Word> words) async {
    final db = await database;
    final batch = db.batch();

    for (var word in words) {
      batch.insert('words', {
        'id': word.id,
        'englishWord': word.englishWord,
        'turkishMeaning': word.turkishMeaning,
        'learnedDate': word.learnedDate.toIso8601String().split('T')[0],
        'notes': word.notes,
        'difficulty': word.difficulty,
        'syncStatus': 'synced',
        'createdAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      for (var sentence in word.sentences) {
        batch.insert('sentences', {
          'id': sentence.id,
          'wordId': word.id,
          'sentence': sentence.sentence,
          'translation': sentence.translation,
          'difficulty': sentence.difficulty,
          'syncStatus': 'synced',
          'createdAt': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    await batch.commit(noResult: true);
  }

  /// Yeni kelime ekle (offline)
  Future<int> createWordOffline({
    required String english,
    required String turkish,
    required DateTime addedDate,
    String difficulty = 'easy',
  }) async {
    final db = await database;
    
    // Negatif local ID kullan (sync sonrası gerçek ID alınacak)
    final localId = -DateTime.now().millisecondsSinceEpoch;
    
    await db.insert('words', {
      'id': localId,
      'localId': localId,
      'englishWord': english,
      'turkishMeaning': turkish,
      'learnedDate': addedDate.toIso8601String().split('T')[0],
      'notes': '',
      'difficulty': difficulty,
      'syncStatus': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Sync queue'ya ekle
    await addToSyncQueue('create', 'words', localId.toString(), {
      'english': english,
      'turkish': turkish,
      'addedDate': addedDate.toIso8601String(),
      'difficulty': difficulty,
    });

    // NOT: XP ekleme işlemi AppStateProvider/XPManager üzerinden yapılıyor
    // Burada eklenirse çift XP sorunu oluşur

    return localId;
  }

  /// Kelime sil (cascade: cümleleri de siler)
  Future<void> deleteWord(int id) async {
    final db = await database;
    
    // Önce cümleleri sil
    await db.delete(
      'sentences',
      where: 'wordId = ? OR localWordId = ?',
      whereArgs: [id, id],
    );
    
    // Sonra kelimeyi sil
    await db.delete(
      'words',
      where: 'id = ? OR localId = ?',
      whereArgs: [id, id],
    );
    
    // NOT: XP düşürme işlemi AppStateProvider/XPManager üzerinden yapılıyor
    // Burada yapılırsa UI senkronizasyonu bozulur
  }

  /// Kelimeye cümle ekle (offline)
  Future<int> addSentenceToWordOffline({
    required int wordId,
    required String sentence,
    required String translation,
    String difficulty = 'easy',
  }) async {
    final db = await database;
    
    final localId = -DateTime.now().millisecondsSinceEpoch;
    
    await db.insert('sentences', {
      'id': localId,
      'localId': localId,
      'wordId': wordId > 0 ? wordId : null,
      'localWordId': wordId < 0 ? wordId : null,
      'sentence': sentence,
      'translation': translation,
      'difficulty': difficulty,
      'syncStatus': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Sync queue'ya ekle
    await addToSyncQueue('create', 'sentences', localId.toString(), {
      'wordId': wordId,
      'sentence': sentence,
      'translation': translation,
      'difficulty': difficulty,
    });

    // NOT: XP ekleme işlemi AppStateProvider/XPManager üzerinden yapılıyor

    return localId;
  }

  /// Kelimeden cümle sil (local DB)
  Future<void> deleteSentenceFromWord(int wordId, int sentenceId) async {
    final db = await database;
    
    // Hem id hem de localId ile silmeyi dene
    await db.delete(
      'sentences',
      where: '(id = ? OR localId = ?) AND (wordId = ? OR localWordId = ?)',
      whereArgs: [sentenceId, sentenceId, wordId, wordId],
    );
    
    // NOT: XP düşürme işlemi AppStateProvider/XPManager üzerinden yapılıyor
  }

  // ==================== PRACTICE SENTENCES ====================

  /// Tüm practice sentences getir
  Future<List<SentencePractice>> getAllPracticeSentences() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'practice_sentences',
      orderBy: 'createdDate DESC',
    );
    
    return maps.map((map) => SentencePractice(
      id: map['id'] ?? 'local_${map['localId']}',
      englishSentence: map['englishSentence'] ?? '',
      turkishTranslation: map['turkishTranslation'] ?? '',
      difficulty: map['difficulty'] ?? 'EASY',
      createdDate: DateTime.parse(map['createdDate']),
      source: map['source'] ?? 'practice',
    )).toList();
  }

  /// Practice sentence kaydet (online'dan gelen)
  Future<void> savePracticeSentence(SentencePractice sentence) async {
    final db = await database;
    
    await db.insert('practice_sentences', {
      'id': sentence.id,
      'englishSentence': sentence.englishSentence,
      'turkishTranslation': sentence.turkishTranslation,
      'difficulty': sentence.difficulty,
      'createdDate': sentence.createdDate?.toIso8601String().split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0],
      'source': sentence.source,
      'syncStatus': 'synced',
      'createdAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Tüm practice sentences kaydet (bulk)
  Future<void> saveAllPracticeSentences(List<SentencePractice> sentences) async {
    final db = await database;
    final batch = db.batch();

    for (var sentence in sentences) {
      batch.insert('practice_sentences', {
        'id': sentence.id,
        'englishSentence': sentence.englishSentence,
        'turkishTranslation': sentence.turkishTranslation,
        'difficulty': sentence.difficulty,
        'createdDate': sentence.createdDate?.toIso8601String().split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0],
        'source': sentence.source,
        'syncStatus': 'synced',
        'createdAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Practice sentence oluştur (offline)
  Future<String> createPracticeSentenceOffline({
    required String englishSentence,
    required String turkishTranslation,
    required String difficulty,
  }) async {
    final db = await database;
    
    final localId = DateTime.now().millisecondsSinceEpoch;
    final id = 'local_$localId';
    
    await db.insert('practice_sentences', {
      'id': id,
      'localId': localId,
      'englishSentence': englishSentence,
      'turkishTranslation': turkishTranslation,
      'difficulty': difficulty.toUpperCase(),
      'createdDate': DateTime.now().toIso8601String().split('T')[0],
      'source': 'practice',
      'syncStatus': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Sync queue'ya ekle
    await _addToSyncQueue('create', 'practice_sentences', id, {
      'englishSentence': englishSentence,
      'turkishTranslation': turkishTranslation,
      'difficulty': difficulty.toUpperCase(),
    });

    // NOT: XP ekleme işlemi AppStateProvider/XPManager üzerinden yapılıyor

    return id;
  }

  /// Practice sentence sil
  Future<void> deletePracticeSentence(String id) async {
    final db = await database;
    await db.delete('practice_sentences', where: 'id = ?', whereArgs: [id]);
    
    // NOT: XP düşürme işlemi AppStateProvider/XPManager üzerinden yapılıyor
  }

  // ==================== XP MANAGEMENT ====================


  /// XP ekle
  Future<void> addXp(int amount) async {
    final db = await database;

    
    // Check if update affects any rows
    final changes = await db.rawUpdate('''
      UPDATE user_stats 
      SET totalXp = totalXp + ?,
          pendingXp = pendingXp + ?,
          lastUpdated = ?
    ''', [amount, amount, DateTime.now().toIso8601String()]);
    
    // If table is empty, insert first row
    if (changes == 0) {
      await db.insert('user_stats', {
        'totalXp': amount,
        'lastSyncedXp': 0,
        'pendingXp': amount,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }
  }

  /// XP düşür (silme işlemlerinde)
  Future<void> deductXp(int amount) async {
    final db = await database;
    
    // XP'yi düşür ama 0'ın altına düşürme
    await db.rawUpdate('''
      UPDATE user_stats 
      SET totalXp = MAX(0, totalXp - ?),
          pendingXp = pendingXp - ?,
          lastUpdated = ?
    ''', [amount, amount, DateTime.now().toIso8601String()]);
  }

  /// Toplam XP getir
  Future<int> getTotalXp() async {
    final db = await database;
    final result = await db.query('user_stats', limit: 1);
    if (result.isNotEmpty) {
      return result.first['totalXp'] as int? ?? 0;
    }
    return 0;
  }

  /// Pending XP getir (sync edilecek)
  Future<int> getPendingXp() async {
    final db = await database;
    final result = await db.query('user_stats', limit: 1);
    if (result.isNotEmpty) {
      return result.first['pendingXp'] as int? ?? 0;
    }
    return 0;
  }

  /// XP sync edildi olarak işaretle
  Future<void> markXpSynced() async {
    final db = await database;
    final totalXp = await getTotalXp();
    await db.update('user_stats', {
      'lastSyncedXp': totalXp,
      'pendingXp': 0,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  /// Online XP ile senkronize et
  Future<void> syncXpFromServer(int serverXp) async {
    final db = await database;
    final pendingXp = await getPendingXp();
    
    // Server XP + pending XP (offline'da kazanılan)
    final newTotalXp = serverXp + pendingXp;
    
    await db.update('user_stats', {
      'totalXp': newTotalXp,
      'lastSyncedXp': serverXp,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  // ==================== SYNC QUEUE ====================

  Future<void> _addToSyncQueue(String action, String tableName, String itemId, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('sync_queue', {
      'action': action,
      'tableName': tableName,
      'itemId': itemId,
      'data': jsonEncode(data), // JSON olarak saklanabilir
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'pending',
    });
  }

  /// Bekleyen sync işlemlerini getir
  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'createdAt ASC',
    );
  }

  /// Sync işlemi tamamlandı olarak işaretle
  Future<void> markSyncItemCompleted(int id) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'status': 'completed'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Pending items update after sync (lokalden sunucuya eşleşme)
  Future<void> updateLocalIdToServerId(String tableName, int localId, int serverId) async {
    final db = await database;
    
    if (tableName == 'words') {
      await db.update(
        'words',
        {'id': serverId, 'syncStatus': 'synced'},
        where: 'localId = ?',
        whereArgs: [localId],
      );
      // Bağlı cümleleri de güncelle
      await db.update(
        'sentences',
        {'wordId': serverId},
        where: 'localWordId = ?',
        whereArgs: [localId],
      );
      // Update pending sync items
      await db.update(
        'sync_queue',
        {'itemId': serverId.toString()},
        where: 'tableName = ? AND itemId = ? AND status = ?',
        whereArgs: [tableName, localId.toString(), 'pending'],
      );
    } else if (tableName == 'sentences') {
      await db.update(
        'sentences',
        {'id': serverId, 'syncStatus': 'synced'},
        where: 'localId = ?',
        whereArgs: [localId],
      );
      // Update pending sync items
      await db.update(
        'sync_queue',
        {'itemId': serverId.toString()},
        where: 'tableName = ? AND itemId = ? AND status = ?',
        whereArgs: [tableName, localId.toString(), 'pending'],
      );
    }
  }

  // ==================== UTILITIES ====================

  /// Son senkronizasyon tarihleri tablosundan unique tarihleri getir
  Future<List<String>> getAllDistinctDates() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT learnedDate FROM words ORDER BY learnedDate DESC
    ''');
    return result.map((r) => r['learnedDate'] as String).toList();
  }

  /// Tarihe göre kelimeleri getir
  Future<List<Word>> getWordsByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    
    final List<Map<String, dynamic>> wordMaps = await db.query(
      'words',
      where: 'learnedDate = ?',
      whereArgs: [dateStr],
    );
    
    List<Word> words = [];
    for (var wordMap in wordMaps) {
      final sentences = await db.query(
        'sentences',
        where: 'wordId = ? OR localWordId = ?',
        whereArgs: [wordMap['id'], wordMap['localId']],
      );
      
      words.add(Word(
        id: wordMap['id'] ?? wordMap['localId'] ?? 0,
        englishWord: wordMap['englishWord'] ?? '',
        turkishMeaning: wordMap['turkishMeaning'] ?? '',
        learnedDate: DateTime.parse(wordMap['learnedDate']),
        notes: wordMap['notes'],
        difficulty: wordMap['difficulty'] ?? 'easy',
        sentences: sentences.map((s) => Sentence(
          id: s['id'] as int? ?? s['localId'] as int? ?? 0,
          sentence: s['sentence'] as String? ?? '',
          translation: s['translation'] as String? ?? '',
          wordId: wordMap['id'] ?? wordMap['localId'] ?? 0,
          difficulty: s['difficulty'] as String?,
        )).toList(),
      ));
    }
    
    return words;
  }

  /// Veritabanını temizle
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('words');
    await db.delete('sentences');
    await db.delete('practice_sentences');
    await db.delete('sync_queue');
    await db.delete('xp_history');
    // user_stats'ı sıfırla
    await db.update('user_stats', {
      'totalXp': 0,
      'lastSyncedXp': 0,
      'pendingXp': 0,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }
  
  // ==================== SYNC QUEUE ====================
  
  /// Sync queue'daki tüm bekleyen işlemleri getir
  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'createdAt ASC');
  }
  
  /// Sync queue'dan bir item'ı sil
  Future<void> removeSyncQueueItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }
  
  /// Sync queue'ya item ekle
  Future<int> addToSyncQueue(String action, String tableName, String itemId, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('sync_queue', {
      'action': action,
      'tableName': tableName,
      'itemId': itemId,
      'data': data.isNotEmpty ? jsonEncode(data) : null,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // ==================== XP HISTORY ====================

  Future<void> addXpHistory({
    required String actionId,
    required String actionName,
    required int amount,
    String? source,
  }) async {
    final db = await database;
    await db.insert('xp_history', {
      'actionId': actionId,
      'actionName': actionName,
      'amount': amount,
      'source': source,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getXpHistory({int limit = 200}) async {
    final db = await database;
    return await db.query(
      'xp_history',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
  }

}
