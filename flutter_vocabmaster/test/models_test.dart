import 'package:flutter_test/flutter_test.dart';
import 'package:vocabmaster/models/word.dart';

void main() {
  group('Sentence Model', () {
    test('fromJson creates a valid Sentence object', () {
      final json = {
        'id': 1,
        'sentence': 'Hello World',
        'translation': 'Merhaba Dünya',
        'wordId': 100,
        'difficulty': 'easy'
      };

      final sentence = Sentence.fromJson(json);

      expect(sentence.id, 1);
      expect(sentence.sentence, 'Hello World');
      expect(sentence.translation, 'Merhaba Dünya');
      expect(sentence.wordId, 100);
      expect(sentence.difficulty, 'easy');
    });

    test('fromJson handles different number types for ID', () {
      final json = {
        'id': 1.0, // double
        'sentence': 'Test',
        'translation': 'Test',
        'wordId': 5.5, // double
      };

      final sentence = Sentence.fromJson(json);
      expect(sentence.id, 1);
      expect(sentence.wordId, 5);
    });

    test('toJson returns correct map', () {
      final sentence = Sentence(
        id: 1,
        sentence: 'Test',
        translation: 'Test TR',
        wordId: 10,
        difficulty: 'hard',
      );

      final json = sentence.toJson();
      expect(json['id'], 1);
      expect(json['sentence'], 'Test');
      expect(json['difficulty'], 'hard');
    });
  });

  group('Word Model', () {
    test('fromJson creates a valid Word object', () {
      final json = {
        'id': 10,
        'englishWord': 'Example',
        'turkishMeaning': 'Örnek',
        'learnedDate': '2023-01-01',
        'difficulty': 'medium',
        'notes': 'Some notes',
        'sentences': [
          {
            'id': 1,
            'sentence': 'This is an example.',
            'translation': 'Bu bir örnektir.',
            'wordId': 10
          }
        ]
      };

      final word = Word.fromJson(json);

      expect(word.id, 10);
      expect(word.englishWord, 'Example');
      expect(word.turkishMeaning, 'Örnek');
      expect(word.learnedDate.year, 2023);
      expect(word.sentences.length, 1);
      expect(word.sentences.first.sentence, 'This is an example.');
    });

    test('fromJson handles empty sentences list', () {
      final json = {
        'id': 1,
        'englishWord': 'Test',
        'turkishMeaning': 'Test',
        'learnedDate': '2023-01-01',
        'sentences': null
      };

      final word = Word.fromJson(json);
      expect(word.sentences, isEmpty);
    });

    test('toJson returns correct map', () {
      final word = Word(
        id: 1,
        englishWord: 'Apple',
        turkishMeaning: 'Elma',
        learnedDate: DateTime(2023, 1, 1),
        difficulty: 'easy',
        sentences: [],
      );

      final json = word.toJson();
      expect(json['id'], 1);
      expect(json['englishWord'], 'Apple');
      expect(json['learnedDate'], '2023-01-01'); // Assuming standard format
    });
  });
}
