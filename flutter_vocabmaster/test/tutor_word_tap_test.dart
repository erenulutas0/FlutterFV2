import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabmaster/frontend_newest/screens/nf_tutor_page.dart';
import 'package:vocabmaster/l10n/app_localizations.dart';

/// Tapping a word in the conversation.
///
/// Asked for in the first piece of feedback this app ever received, in one
/// sentence: select a word and learn from it. The book reader has had exactly
/// this since it shipped, and the tutor — the screen where a learner meets a
/// word they were not expecting, from a speaker rather than a page — had no way
/// to ask about anything on it. The words were there and inert.
///
/// What has to hold is small and easy to lose: both sides of the conversation
/// answer a tap, the line the word was said in goes with it, and the things
/// that already worked on a bubble still work.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> tappedTokens;
  late List<String> tappedSentences;
  late int played;

  setUp(() {
    tappedTokens = <String>[];
    tappedSentences = <String>[];
    played = 0;
  });

  Widget host(Widget child) => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  Widget turn({
    required String text,
    required bool fromTutor,
    bool hasAudio = true,
    bool tappable = true,
  }) =>
      nfTurnForTest(
        text: text,
        fromTutor: fromTutor,
        hasAudio: hasAudio,
        onPlay: () => played++,
        onWordTapped: tappable
            ? (String token, String sentence) {
                tappedTokens.add(token);
                tappedSentences.add(sentence);
              }
            : null,
      );

  testWidgets('a word the tutor said answers a tap',
      (WidgetTester tester) async {
    const String said = 'The flight was delayed by the weather.';
    await tester.pumpWidget(host(turn(text: said, fromTutor: true)));
    await tester.pumpAndSettle();

    await tester.tapOnText(find.textRange.ofSubstring('delayed'));
    await tester.pump();

    expect(tappedTokens, <String>['delayed']);
    // The sentence travels with the word. A dictionary asked about "delayed"
    // alone answers with a list of senses; asked about "delayed" in this line
    // it answers the question the learner actually has.
    expect(tappedSentences, <String>[said]);
  });

  testWidgets("the learner's own words answer a tap too",
      (WidgetTester tester) async {
    // Their half of the conversation matters as much as the tutor's, and
    // arguably more: this is the word they reached for and were not sure of.
    // It also draws on a filled primary bubble rather than a white one, which
    // is where a shared text widget is most likely to have been wired up for
    // only one of the two.
    const String said = 'I wanted to reserve a table for tonight.';
    await tester.pumpWidget(
      host(turn(text: said, fromTutor: false, hasAudio: false)),
    );
    await tester.pumpAndSettle();

    await tester.tapOnText(find.textRange.ofSubstring('reserve'));
    await tester.pump();

    expect(tappedTokens, <String>['reserve']);
    expect(tappedSentences, <String>[said]);
  });

  testWidgets('a message the app wrote is not a dictionary entry',
      (WidgetTester tester) async {
    // Connection and quota notices are drawn as tutor bubbles because that is
    // where the reply would have been, but nobody said them and they are
    // written in the interface language, not the one being learned. Handing a
    // word from one of those to an English dictionary returns confident
    // nonsense about a word the learner never met.
    await tester.pumpWidget(host(turn(
      text: 'No answer came back. Try saying that again.',
      fromTutor: true,
      hasAudio: false,
    )));
    await tester.pumpAndSettle();

    await tester.tapOnText(find.textRange.ofSubstring('answer'));
    await tester.pump();

    expect(tappedTokens, isEmpty);
  });

  testWidgets('the play control on a bubble still works',
      (WidgetTester tester) async {
    // The tap targets that were already on these bubbles have to survive the
    // new one. Words became gesture recognizers inside the text; the listen
    // button sits directly under it and would be the first casualty of a hit
    // test that swallowed everything in the bubble.
    await tester.pumpWidget(host(turn(
      text: 'Would you like anything else?',
      fromTutor: true,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    expect(played, 1);
    expect(tappedTokens, isEmpty, reason: 'the play tap was read as a word');
  });

  testWidgets('the conversation still scrolls under a finger',
      (WidgetTester tester) async {
    // The other thing tap recognizers inside text are famous for breaking. A
    // learner scrolling back through a conversation drags across the words, and
    // if the recognizers win that gesture the thread locks up and every attempt
    // to scroll opens a dictionary sheet instead.
    final ScrollController scroll = ScrollController();
    addTearDown(scroll.dispose);

    await tester.pumpWidget(host(SizedBox(
      height: 300,
      child: ListView.builder(
        controller: scroll,
        itemCount: 20,
        itemBuilder: (BuildContext context, int i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: turn(
            text: 'Turn number $i of this long conversation.',
            fromTutor: i.isEven,
            hasAudio: false,
          ),
        ),
      ),
    )));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();

    expect(scroll.offset, greaterThan(0), reason: 'the thread would not scroll');
    expect(tappedTokens, isEmpty, reason: 'a scroll opened a word lookup');
  });
}
