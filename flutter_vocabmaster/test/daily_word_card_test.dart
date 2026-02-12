import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabmaster/widgets/daily_word_card.dart';

void main() {
  Map<String, dynamic> buildWordData() {
    return {
      'word': 'Focus',
      'translation': 'Odak',
      'difficulty': 'easy',
    };
  }

  testWidgets('DailyWordCard shows quick add when word not added', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DailyWordCard(
          wordData: buildWordData(),
          onTap: () {},
          isWordAdded: false,
          isSentenceAdded: false,
          index: 0,
          onQuickAdd: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('Cümlesini Ekle'), findsNothing);
    expect(find.text('Kelime + Cümle Eklendi'), findsNothing);
  });

  testWidgets('DailyWordCard shows add sentence when word added but sentence missing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DailyWordCard(
          wordData: buildWordData(),
          onTap: () {},
          isWordAdded: true,
          isSentenceAdded: false,
          index: 0,
          onAddSentence: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.text('Cümlesini Ekle'), findsOneWidget);
    expect(find.text('Kelime + Cümle Eklendi'), findsNothing);
  });

  testWidgets('DailyWordCard shows added badge when word and sentence added', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DailyWordCard(
          wordData: buildWordData(),
          onTap: () {},
          isWordAdded: true,
          isSentenceAdded: true,
          index: 0,
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.text('Cümlesini Ekle'), findsNothing);
    expect(find.text('Kelime + Cümle Eklendi'), findsOneWidget);
  });
}
