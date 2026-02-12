import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vocabmaster/models/word.dart';
import 'package:vocabmaster/providers/app_state_provider.dart';
import 'package:vocabmaster/widgets/word_of_the_day_modal.dart';
import 'test_helper.dart';

const _ttsChannel = MethodChannel('flutter_tts');

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupTestEnv();
    _ttsChannel.setMockMethodCallHandler((_) async => null);
  });

  tearDownAll(() {
    _ttsChannel.setMockMethodCallHandler(null);
  });

  AppStateProvider _buildAppState({
    required bool wordAdded,
    required bool sentenceAdded,
    required Map<String, dynamic> wordData,
  }) {
    return _TestAppStateProvider(
      wordAdded: wordAdded,
      sentenceAdded: sentenceAdded,
      wordData: wordData,
    );
  }

  testWidgets('Step 6 shows add buttons when word not added', (tester) async {
    final wordData = {
      'word': 'Focus',
      'translation': 'Odak',
      'exampleSentence': 'Stay focused.',
      'exampleTranslation': 'Odakli kal.',
      'difficulty': 'easy',
      'partOfSpeech': 'noun',
      'pronunciation': 'foh-kus',
    };

    final appState = _buildAppState(
      wordAdded: false,
      sentenceAdded: false,
      wordData: wordData,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          home: WordOfTheDayModal(
            wordData: wordData,
            onClose: () {},
            enableAnimations: false,
            enableTts: false,
            initialStep: 5,
          ),
        ),
      ),
    );

    expect(find.text('Kelimeyi Cümlesiyle Ekle'), findsOneWidget);
    expect(find.text('Sadece Kelimeyi Ekle'), findsOneWidget);
    expect(find.text('Kelime ekli'), findsNothing);
  });

  testWidgets('Step 6 shows add sentence when word added but sentence missing', (tester) async {
    final wordData = {
      'word': 'Focus',
      'translation': 'Odak',
      'exampleSentence': 'Stay focused.',
      'exampleTranslation': 'Odakli kal.',
      'difficulty': 'easy',
      'partOfSpeech': 'noun',
      'pronunciation': 'foh-kus',
    };

    final appState = _buildAppState(
      wordAdded: true,
      sentenceAdded: false,
      wordData: wordData,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          home: WordOfTheDayModal(
            wordData: wordData,
            onClose: () {},
            enableAnimations: false,
            enableTts: false,
            initialStep: 5,
          ),
        ),
      ),
    );

    expect(find.text('Kelime ekli'), findsOneWidget);
    expect(find.text('Cümlesini de ekle'), findsOneWidget);
  });

  testWidgets('Step 6 shows completed state when word and sentence added', (tester) async {
    final wordData = {
      'word': 'Focus',
      'translation': 'Odak',
      'exampleSentence': 'Stay focused.',
      'exampleTranslation': 'Odakli kal.',
      'difficulty': 'easy',
      'partOfSpeech': 'noun',
      'pronunciation': 'foh-kus',
    };

    final appState = _buildAppState(
      wordAdded: true,
      sentenceAdded: true,
      wordData: wordData,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          home: WordOfTheDayModal(
            wordData: wordData,
            onClose: () {},
            enableAnimations: false,
            enableTts: false,
            initialStep: 5,
          ),
        ),
      ),
    );

    expect(find.text('Kelime ve cümle ekli'), findsOneWidget);
    expect(find.text('Cümlesini de ekle'), findsNothing);
  });
}

class _TestAppStateProvider extends AppStateProvider {
  final bool wordAdded;
  final bool sentenceAdded;
  final Map<String, dynamic> wordData;

  _TestAppStateProvider({
    required this.wordAdded,
    required this.sentenceAdded,
    required this.wordData,
  });

  @override
  Word? findWordByEnglish(String english) {
    if (!wordAdded) return null;
    return Word(
      id: 1,
      englishWord: wordData['word'] as String,
      turkishMeaning: wordData['translation'] as String,
      learnedDate: DateTime.now(),
      difficulty: 'easy',
      sentences: sentenceAdded
          ? [
              Sentence(
                id: 10,
                sentence: wordData['exampleSentence'] as String,
                translation: wordData['exampleTranslation'] as String,
                wordId: 1,
                difficulty: 'easy',
              )
            ]
          : [],
    );
  }

  @override
  bool hasSentenceForWord(Word word, String sentence) {
    return sentenceAdded;
  }
}
