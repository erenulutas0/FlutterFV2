import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabmaster/models/word.dart';
import 'package:vocabmaster/models/word_meaning.dart';
import 'package:vocabmaster/providers/app_state_provider.dart';
import 'package:vocabmaster/services/local_database_service.dart';

import '../test_helper.dart';

/// A word created straight on the server has to be written into the local
/// cache, because that cache is what the app actually reads.
///
/// `OfflineSyncService.getAllWords` returns the local rows the moment there are
/// any and syncs behind them, so a server-only word stays invisible until some
/// later sync lands. On a real phone that meant saving "bank" with two
/// meanings, being told "Kelime bugüne eklendi!", opening the word list and
/// finding nothing there.
void main() {
  setUpAll(setupTestEnv);

  late LocalDatabaseService db;

  setUp(() async {
    await clearDatabase();
    db = LocalDatabaseService();
  });

  /// The day is credited in the background, after the save has returned -- so read it
  /// once it lands rather than straight after the call.
  Future<String?> creditedDay({int attempts = 40}) async {
    for (int i = 0; i < attempts; i++) {
      final prefs = await SharedPreferences.getInstance();
      final String? day = prefs.getString('last_activity_date');
      if (day != null) return day;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    return null;
  }

  Word bank() => Word(
        id: 4242,
        englishWord: 'bank',
        turkishMeaning: 'banka, kıyı',
        learnedDate: DateTime(2026, 8, 24),
        difficulty: 'medium',
        meanings: const <WordMeaning>[
          WordMeaning(id: 1, translation: 'banka', position: 0),
          WordMeaning(id: 2, translation: 'kıyı', position: 1),
        ],
      );

  test('a server-created word lands in the cache the app reads', () async {
    expect(await db.getAllWords(), isEmpty);

    await AppStateProvider().adoptServerWord(bank());

    final cached = await db.getAllWords();
    expect(cached.map((Word w) => w.englishWord), <String>['bank']);
  });

  test('it also lands in the list on screen, without waiting for a sync',
      () async {
    final provider = AppStateProvider();
    expect(provider.allWords, isEmpty);

    await provider.adoptServerWord(bank());

    expect(provider.allWords.single.englishWord, 'bank');
  });

  test('a new word kept from a book or a conversation counts as the day',
      () async {
    // The streak guard reads last_activity_date and cancels itself when there is
    // none. Words saved from the tutor, the reader and the dictionary all arrive here,
    // and none of them wrote it -- so on a phone that learned that way, the one reminder
    // that protects a streak was never armed. Seen on build 471: no errors, no alarm.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final provider = AppStateProvider()..mockDate = DateTime(2026, 9, 10, 15);

    await provider.adoptServerWord(bank());

    expect(await creditedDay(), '2026-09-10');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('current_streak'), 1);
  });

  test('re-adopting a word to add a meaning is an edit, not the day', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final provider = AppStateProvider()..mockDate = DateTime(2026, 9, 10, 15);
    await provider.adoptServerWord(bank());
    // Let the first save's credit land before clearing, or it lands afterwards and
    // looks like the edit was counted.
    expect(await creditedDay(), '2026-09-10');

    // Two days on, the same word comes back from the server with a meaning added.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    provider.mockDate = DateTime(2026, 9, 12, 15);
    await provider.adoptServerWord(bank());

    // Long enough for a wrongly-credited edit to have written its day.
    expect(await creditedDay(attempts: 8), isNull,
        reason: 'editing a word already in the deck was counted as practising');
  });

  test('adopting the same word twice does not duplicate it', () async {
    final provider = AppStateProvider();
    await provider.adoptServerWord(bank());
    await provider.adoptServerWord(bank());

    expect(provider.allWords.length, 1);
    expect((await db.getAllWords()).length, 1);
  });
}
