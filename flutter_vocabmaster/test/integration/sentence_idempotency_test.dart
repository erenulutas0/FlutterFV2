import 'package:flutter_test/flutter_test.dart';
import 'package:vocabmaster/providers/app_state_provider.dart';
import 'package:vocabmaster/services/xp_manager.dart';
import 'package:vocabmaster/services/local_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helper.dart';

void main() {
  late AppStateProvider appState;
  late XPManager xpManager;

  setUpAll(() {
    setupTestEnv();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await clearDatabase();

    xpManager = XPManager();
    xpManager.invalidateCache();
    XPManager.resetIdempotency();

    appState = AppStateProvider();
  });

  test('Adding the same sentence twice only grants XP once', () async {
    final word = await appState.addWord(
      english: 'Focus',
      turkish: 'Odak',
      addedDate: DateTime.now(),
      difficulty: 'easy',
    );

    await appState.addSentenceToWord(
      wordId: word!.id,
      sentence: 'Stay focused.',
      translation: 'Odakli kal.',
      difficulty: 'easy',
    );

    await appState.addSentenceToWord(
      wordId: word.id,
      sentence: 'Stay focused.',
      translation: 'Odakli kal.',
      difficulty: 'easy',
    );

    final totalXP = await xpManager.getTotalXP(forceRefresh: true);
    expect(totalXP, 15);

    final history = await LocalDatabaseService().getXpHistory(limit: 50);
    final sentenceAdds = history.where((h) => h['actionId'] == 'add_sentence').length;
    expect(sentenceAdds, 1);
  });
}
