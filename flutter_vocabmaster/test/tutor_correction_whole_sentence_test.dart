import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabmaster/frontend_newest/nf_frontend_preference.dart';
import 'package:vocabmaster/frontend_newest/screens/nf_tutor_page.dart';
import 'package:vocabmaster/frontend_newest/services/nf_tutor_sessions.dart';
import 'package:vocabmaster/frontend_newest/theme/nf_theme_scope.dart';
import 'package:vocabmaster/l10n/app_localizations.dart';
import 'package:vocabmaster/models/tutor_correction.dart';
import 'package:vocabmaster/services/api_service.dart';
import 'package:vocabmaster/services/auth_service.dart';

/// A correction card that leads with the whole sentence, fixed.
///
/// A tester at B2 said "This is complicating more. Why don't you explain what is steamed milk
/// and latte more simpler..." -- five mistakes -- and the card showed one, "more simpler" ->
/// "simpler". He read that, fairly, as the other four being fine. The card now shows the
/// learner's whole message the way a native speaker would say it, then the most important
/// changes, each with its reason.
///
/// Everything that only ever read one correction -- the deck, the recall line, saved
/// conversations -- still reads the main one, and a server from before this still draws the
/// card it always drew.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String transcript =
      'This is complicating more. Explain what is steamed milk and latte more simpler.';
  const String whole =
      'This is getting more complicated. Explain what steamed milk and a latte are, more simply.';

  const TutorCorrection full = TutorCorrection(
    said: 'This is complicating more',
    better: 'This is getting more complicated',
    note: 'n1',
    sentence: whole,
    more: <TutorCorrection>[
      TutorCorrection(
          said: 'what is steamed milk and latte',
          better: 'what steamed milk and a latte are',
          note: 'n2'),
      TutorCorrection(said: 'more simpler', better: 'more simply', note: 'n3'),
    ],
  );

  Map<String, Object?> change(String said, String better, [String? note]) =>
      <String, Object?>{'said': said, 'better': better, if (note != null) 'note': note};

  group('off the wire', () {
    test('every change and the whole sentence are read, the most important first', () {
      final TutorCorrection? read = TutorCorrection.fromResponse(<String, Object?>{
        'response': 'Sure!',
        'correction': change('This is complicating more', 'This is getting more complicated', 'n1'),
        'corrections': <Object?>[
          change('This is complicating more', 'This is getting more complicated', 'n1'),
          change('what is steamed milk and latte', 'what steamed milk and a latte are', 'n2'),
          change('more simpler', 'more simply', 'n3'),
        ],
        'correctedSentence': '  $whole  ',
      });

      expect(read, isNotNull);
      expect(read!.better, 'This is getting more complicated');
      expect(read.note, 'n1');
      expect(read.more.map((TutorCorrection c) => c.better).toList(),
          <String>['what steamed milk and a latte are', 'more simply']);
      expect(read.sentence, whole);
      expect(read.changes, hasLength(3));
      expect(read.showsSentence, isTrue);
    });

    test('an older server is read exactly as before', () {
      final TutorCorrection? read = TutorCorrection.fromResponse(<String, Object?>{
        'response': 'Where did you go?',
        'correction': change('I go yesterday', 'I went yesterday'),
      });

      expect(read!.better, 'I went yesterday');
      expect(read.more, isEmpty);
      expect(read.sentence, isNull);
      expect(read.showsSentence, isFalse);
    });

    test('a card holds three changes at most, each only once', () {
      final TutorCorrection? read = TutorCorrection.fromResponse(<String, Object?>{
        'corrections': <Object?>[
          change('I goes', 'I go'),
          change('I goes', 'I go'),
          change('she go', 'she goes'),
          change('they was', 'they were'),
          change('he have', 'he has'),
        ],
      });

      expect(read!.changes.map((TutorCorrection c) => c.better).toList(),
          <String>['I go', 'she goes', 'they were']);
    });

    test('a broken change costs only itself', () {
      final TutorCorrection? read = TutorCorrection.fromResponse(<String, Object?>{
        'corrections': <Object?>[
          change('I go to school', 'I go to school.'),
          change('I go', 'I went'),
        ],
      });

      expect(read!.better, 'I went');
      expect(read.more, isEmpty);
    });

    test('a sentence that is not text, or runs on, is absent', () {
      TutorCorrection? withSentence(Object? sentence) =>
          TutorCorrection.fromResponse(<String, Object?>{
            'corrections': <Object?>[change('I go', 'I went')],
            'correctedSentence': sentence,
          });

      expect(withSentence(42)!.sentence, isNull);
      expect(withSentence('x' * 401)!.sentence, isNull);
      expect(withSentence('   ')!.sentence, isNull);
    });

    test('nothing usable is no correction at all', () {
      expect(TutorCorrection.fromResponse(<String, Object?>{'corrections': <Object?>[]}),
          isNull);
      expect(
          TutorCorrection.fromResponse(<String, Object?>{
            'corrections': <Object?>[change('a', 'a')],
            'correctedSentence': whole,
          }),
          isNull,
          reason: 'a sentence with nothing explained cannot lead a card');
      expect(TutorCorrection.fromResponse('not a map'), isNull);
    });
  });

  group('about what was actually said', () {
    test('a change about some other sentence is dropped, and the rest kept', () {
      final TutorCorrection? kept = const TutorCorrection(
        said: 'This is complicating more',
        better: 'This is getting more complicated',
        more: <TutorCorrection>[
          TutorCorrection(said: 'more simpler', better: 'more simply'),
          TutorCorrection(said: 'the cat sat on the mat', better: 'the cat sits on the mat'),
        ],
      ).about(transcript);

      expect(kept!.more.map((TutorCorrection c) => c.said).toList(), <String>['more simpler']);
    });

    test('a whole sentence that is some other sentence is dropped', () {
      final TutorCorrection? kept = const TutorCorrection(
        said: 'This is complicating more',
        better: 'This is getting more complicated',
        sentence: 'I love going to the beach every summer with my family.',
      ).about(transcript);

      expect(kept!.sentence, isNull);
      expect(full.about(transcript)!.sentence, whole,
          reason: 'the right sentence shares most of its words with what was said');
    });

    test('if the main change is invented, nothing is shown', () {
      expect(
          const TutorCorrection(said: 'I have a dog', better: 'I have got a dog', sentence: whole)
              .about(transcript),
          isNull);
    });
  });

  group('reopened from history', () {
    test('the whole sentence and the other changes survive being saved', () {
      const NfSavedTurn turn = NfSavedTurn(text: transcript, fromTutor: false, correction: full);

      final NfSavedTurn? back = NfSavedTurn.fromJson(json.decode(json.encode(turn.toJson())));

      expect(back!.correction!.sentence, whole);
      expect(back.correction!.more.map((TutorCorrection c) => c.note).toList(),
          <String>['n2', 'n3']);
      expect(back.correction!.better, 'This is getting more complicated');
    });

    test('a conversation saved before them reads as it always did', () {
      final NfSavedTurn? back = NfSavedTurn.fromJson(<String, Object?>{
        't': 'I go home',
        'm': false,
        'c': <String, Object?>{'said': 'I go', 'better': 'I went'},
      });

      expect(back!.correction!.better, 'I went');
      expect(back.correction!.sentence, isNull);
      expect(back.correction!.more, isEmpty);
    });
  });

  group('the card', () {
    testWidgets('leads with the whole sentence, then every change with its reason',
        (WidgetTester tester) async {
      await _pumpCard(tester, full);

      expect(find.text(whole), findsOneWidget);
      expect(find.textContaining('more simpler', findRichText: true), findsOneWidget);
      for (final String why in <String>['n1', 'n2', 'n3']) {
        expect(find.text(why), findsOneWidget, reason: 'the reason for $why is missing');
      }
      expect(
        tester.getTopLeft(find.text(whole)).dy,
        lessThan(tester.getTopLeft(find.textContaining('more simpler', findRichText: true)).dy),
        reason: 'the whole sentence is the thing to read, so it comes first',
      );
    });

    testWidgets('a change that is the whole sentence draws the card it always did',
        (WidgetTester tester) async {
      await _pumpCard(
        tester,
        const TutorCorrection(
          said: 'I go to Paris yesterday',
          better: 'I went to Paris yesterday',
          note: 'n1',
          sentence: 'I went to Paris yesterday.',
        ),
      );

      // Label, what they said, the corrected line, the note, and the keep control:
      // exactly the card from before this existed.
      expect(find.byType(Text), findsNWidgets(5));
      expect(find.text('I went to Paris yesterday.'), findsNothing);
    });

    testWidgets('without a whole sentence the other changes are still listed',
        (WidgetTester tester) async {
      await _pumpCard(
        tester,
        const TutorCorrection(
          said: 'I go',
          better: 'I went',
          more: <TutorCorrection>[
            TutorCorrection(said: 'to home', better: 'home', note: 'n2'),
          ],
        ),
      );

      expect(find.text('I go'), findsOneWidget);
      expect(find.textContaining('to home', findRichText: true), findsOneWidget);
      expect(find.text('n2'), findsOneWidget);
    });
  });

  group('keeping it', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      await AuthService().saveSession('t', 'r', <String, dynamic>{
        'id': 4,
        'userId': 4,
        'email': 'speaker@test.local',
        'displayName': 'Speaker',
        'userTag': '#00004',
        'role': 'USER',
      });
    });

    testWidgets('the example kept with the phrase is the whole corrected sentence',
        (WidgetTester tester) async {
      // The span applied to the line can only fix the one mistake it names; the model's
      // sentence fixes all of them, so it is the better example to review against.
      final List<Map<String, Object?>> examples = <Map<String, Object?>>[];
      final ApiService api = ApiService(
        baseUrl: 'http://localhost:8080/api',
        client: MockClient((http.Request request) async {
          const Map<String, String> json_ = <String, String>{'content-type': 'application/json'};
          if (request.method == 'POST' && request.url.path.endsWith('/words/91/sentences')) {
            examples.add(Map<String, Object?>.from(json.decode(request.body) as Map));
            return http.Response('{"id":91}', 201, headers: json_);
          }
          if (request.method == 'POST' && request.url.path.endsWith('/words')) {
            final Map<String, Object?> body =
                Map<String, Object?>.from(json.decode(request.body) as Map);
            return http.Response(
              json.encode(<String, Object?>{
                'id': 91,
                'englishWord': body['englishWord'],
                'turkishMeaning': body['turkishMeaning'],
                'learnedDate': '2026-09-10',
                'meanings': <Map<String, Object?>>[
                  <String, Object?>{'id': 501, 'translation': body['turkishMeaning'], 'position': 0},
                ],
              }),
              201,
              headers: json_,
            );
          }
          return http.Response('{}', 200, headers: json_);
        }),
      );

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 260,
              child: nfCorrectionCardForTest(full, api: api, saidInFull: transcript),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep this phrase'));
      await tester.pumpAndSettle();

      expect(examples.single['sentence'], whole);
    });
  });
}

/// The correction card alone, at the width a speech bubble gets on a phone.
Future<void> _pumpCard(WidgetTester tester, TutorCorrection correction) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<NfFrontendPreference>(
      create: (_) => NfFrontendPreference(),
      child: MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: NfThemeScope(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 260,
              child: nfCorrectionCardForTest(correction),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
