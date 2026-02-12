import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabmaster/providers/app_state_provider.dart';
import 'package:vocabmaster/services/xp_manager.dart';
import '../test_helper.dart';

void main() {
  setUpAll(() {
    setupTestEnv();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await clearDatabase();
    XPManager.resetIdempotency();
  });

  group('AppStateProvider XP Integration', () {
    test('Adding a manual word awards +10 XP and updates user stats', () async {
      final appState = AppStateProvider();

      final word = await appState.addWord(
        english: 'test',
        turkish: 'test',
        addedDate: DateTime(2026, 2, 9),
        difficulty: 'easy',
        source: 'manual',
      );

      expect(word, isNotNull);
      expect(appState.userStats['xp'], 10);
    });

    test('Daily word add gives +10 XP, plus sentence gives +5 XP (total 15)', () async {
      final appState = AppStateProvider();

      final word = await appState.addWord(
        english: 'daily',
        turkish: 'günün kelimesi',
        addedDate: DateTime(2026, 2, 9),
        difficulty: 'medium',
        source: 'daily_word',
      );

      expect(word, isNotNull);
      expect(appState.userStats['xp'], 10);

      await appState.addSentenceToWord(
        wordId: word!.id,
        sentence: 'This is a daily word.',
        translation: 'Bu bir günün kelimesidir.',
        difficulty: 'medium',
      );

      expect(appState.userStats['xp'], 15);
    });
  });
}
