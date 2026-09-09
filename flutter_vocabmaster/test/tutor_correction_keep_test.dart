import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabmaster/frontend_newest/screens/nf_tutor_page.dart';
import 'package:vocabmaster/l10n/app_localizations.dart';
import 'package:vocabmaster/models/tutor_correction.dart';
import 'package:vocabmaster/models/word.dart';
import 'package:vocabmaster/models/word_origins.dart';
import 'package:vocabmaster/services/api_service.dart';
import 'package:vocabmaster/services/auth_service.dart';

/// Keeping a correction instead of watching it scroll away.
///
/// The card already teaches: their sentence struck through, the right one under
/// it, and a line in their own language saying why. Then the conversation moves
/// on and it is gone. Two days later the same learner makes the same mistake,
/// and nothing anywhere in the app remembers that they were ever told — the
/// deck is the part that remembers, and the one screen producing something
/// worth remembering had no way into it.
///
/// The failures worth pinning are the quiet ones: a phrase saved twice costs a
/// review every day for a sentence they already know, a phrase that never
/// arrives is indistinguishable from one that did, and a save that fails
/// silently is the worst of the three.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String base = 'http://localhost:8080/api';

  late List<Map<String, Object?>> created;
  late List<Word> adopted;

  setUp(() async {
    created = <Map<String, Object?>>[];
    adopted = <Word>[];
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

  /// Accepts word creations and records what was asked for. [failFirst] refuses
  /// the first one, so the retry path can be driven.
  ApiService serving({bool failFirst = false}) => ApiService(
        baseUrl: base,
        client: MockClient((http.Request request) async {
          if (request.method == 'POST' && request.url.path.endsWith('/words')) {
            final Map<String, Object?> body =
                Map<String, Object?>.from(json.decode(request.body) as Map);
            created.add(body);
            if (failFirst && created.length == 1) {
              return http.Response('{"message":"nope"}', 500,
                  headers: <String, String>{
                    'content-type': 'application/json'
                  });
            }
            return http.Response(
              json.encode(<String, Object?>{
                'id': 91,
                'englishWord': body['englishWord'],
                'turkishMeaning': body['turkishMeaning'],
                'learnedDate': '2026-09-09',
              }),
              201,
              headers: <String, String>{'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 200,
              headers: <String, String>{'content-type': 'application/json'});
        }),
      );

  Future<void> pump(
    WidgetTester tester,
    TutorCorrection correction, {
    required ApiService api,
    bool alreadySaved = false,
  }) async {
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
            child: nfCorrectionCardForTest(
              correction,
              api: api,
              alreadySaved: alreadySaved,
              onSaved: adopted.add,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  const TutorCorrection bored = TutorCorrection(
    said: 'I am boring',
    better: "I'm bored",
    note: 'boring describes the thing, bored describes you',
  );

  testWidgets('one tap keeps the corrected phrase, filed as speaking',
      (WidgetTester tester) async {
    await pump(tester, bored, api: serving());

    await tester.tap(find.text('Keep this phrase'));
    await tester.pumpAndSettle();

    expect(created, hasLength(1));
    // The corrected line is what goes in the deck. Keeping their mistake would
    // build a deck of sentences to unlearn.
    expect(created.single['englishWord'], "I'm bored");
    // The explanation is already written in the learner's own language and is
    // the only sentence anywhere that says why the correction was needed, so it
    // is what the deck stores as the meaning.
    expect(created.single['turkishMeaning'],
        'boring describes the thing, bored describes you');
    // Said rather than guessed. Without this the server infers provenance and
    // files a phrase kept from a conversation as if it had been typed into the
    // dictionary box.
    expect(created.single['origin'], WordOrigins.tutor);
  });

  testWidgets('the deck is told, not just the server',
      (WidgetTester tester) async {
    // The silent failure this shares with the reader: the phrase reaches the
    // server, the card says so, and the Words screen the learner opens next has
    // never heard of it — which reads exactly like a save that failed.
    await pump(tester, bored, api: serving());

    await tester.tap(find.text('Keep this phrase'));
    await tester.pumpAndSettle();

    expect(adopted, hasLength(1));
    expect(adopted.single.id, 91);
  });

  testWidgets('it says so, and will not do it twice',
      (WidgetTester tester) async {
    // A card stays on screen for the rest of the conversation and can be
    // scrolled past any number of times. Nothing on the server refuses a second
    // copy, so without this the deck fills with one sentence and charges a
    // review for every copy.
    await pump(tester, bored, api: serving());

    await tester.tap(find.text('Keep this phrase'));
    await tester.pumpAndSettle();

    expect(find.text('Kept in your deck'), findsOneWidget);
    expect(find.text('Keep this phrase'), findsNothing);

    await tester.tap(find.text('Kept in your deck'));
    await tester.pumpAndSettle();

    expect(created, hasLength(1), reason: 'the phrase was saved a second time');
  });

  testWidgets('a phrase already in the deck offers nothing to do',
      (WidgetTester tester) async {
    // "Kept" and "already there" are not the same news: one is the result of
    // the tap, the other is why the tap does nothing.
    await pump(tester, bored, api: serving(), alreadySaved: true);

    expect(find.text('Already in your deck'), findsOneWidget);
    expect(find.text('Keep this phrase'), findsNothing);

    await tester.tap(find.text('Already in your deck'));
    await tester.pumpAndSettle();

    expect(created, isEmpty);
    expect(adopted, isEmpty);
  });

  testWidgets('a correction with no explanation still keeps something readable',
      (WidgetTester tester) async {
    // Most corrections carry a note and every one saved before that field
    // existed carries none. A deck entry with an empty meaning is a review card
    // with no answer on it, and the wrong sentence on its own would be worse
    // still: a card that asks the learner to produce their own mistake.
    await pump(
      tester,
      const TutorCorrection(
        said: 'I go to Paris yesterday',
        better: 'I went to Paris yesterday',
      ),
      api: serving(),
    );

    await tester.tap(find.text('Keep this phrase'));
    await tester.pumpAndSettle();

    expect(created.single['englishWord'], 'I went to Paris yesterday');
    expect(created.single['turkishMeaning'],
        'Instead of: I go to Paris yesterday');
  });

  testWidgets('a save that fails says so and can be tried again',
      (WidgetTester tester) async {
    // The honest middle state. Swallowing the failure leaves the learner
    // believing the phrase is in their deck; showing the raw exception puts
    // "Exception: Error creating word: 500" under a correction in front of
    // somebody reading Spanish.
    await pump(tester, bored, api: serving(failFirst: true));

    await tester.tap(find.text('Keep this phrase'));
    await tester.pumpAndSettle();

    expect(adopted, isEmpty);
    expect(find.textContaining('Exception'), findsNothing,
        reason: 'a Dart exception was printed at the learner');
    expect(find.text('Keep this phrase'), findsOneWidget,
        reason: 'the failed save left nothing to try again with');

    await tester.tap(find.text('Keep this phrase'));
    await tester.pumpAndSettle();

    expect(created, hasLength(2));
    expect(adopted, hasLength(1));
    expect(find.text('Kept in your deck'), findsOneWidget);
  });
}
