import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabmaster/frontend_newest/nf_frontend_preference.dart';
import 'package:vocabmaster/frontend_newest/screens/nf_tutor_page.dart';
import 'package:vocabmaster/frontend_newest/theme/nf_theme_scope.dart';
import 'package:vocabmaster/frontend_newest/theme/nf_tokens.dart';
import 'package:vocabmaster/frontend_newest/widgets/nf_card.dart';
import 'package:vocabmaster/l10n/app_localizations.dart';
import 'package:vocabmaster/models/tutor_correction.dart';
import 'package:vocabmaster/services/api_service.dart';
import 'package:vocabmaster/services/auth_service.dart';

/// The line that says WHY, under the correction.
///
/// A correction card is two sentences with as little as one word between them
/// — "I am boring" struck through, "I'm bored" under it. To anybody who can
/// already see the difference it is redundant, and to everybody else, which is
/// the entire audience of a language app, it is a card that says "wrong" and
/// then declines to say what. The model writes that missing clause itself, in
/// the language the learner reads, and the server sends it through as a third
/// field.
///
/// Two things can go wrong with it and they cost different amounts. A note
/// that is absent is the ordinary case — most turns get none, and every
/// correction saved before the field existed has none — so it must cost
/// nothing at all. A note that is junk is free-form model output landing
/// unread on the screen, so it must cost only itself: the correction is the
/// reason the card is there and survives whatever the explanation does.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Off the wire
  // ---------------------------------------------------------------------------

  group('what the server now sends', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      await AuthService().saveSession('t', 'r', <String, dynamic>{
        'id': 4,
        'userId': 4,
        'email': 'learner@test.local',
        'displayName': 'Learner',
        'userTag': '#00004',
        'role': 'USER',
      });
    });

    ApiService serving(Map<String, Object?> body) => ApiService(
          baseUrl: 'http://localhost:8080/api',
          client: MockClient((http.Request request) async => http.Response(
                json.encode(body),
                200,
                headers: <String, String>{'content-type': 'application/json'},
              )),
        );

    test('the note reaches the reply, in the language it was written in', () async {
      // The whole point of the field: the explanation is composed in the
      // learner's own language and nothing between the model and the screen
      // translates, normalises or re-cases it. Turkish here because that is
      // where a well-meaning normalisation would show up first.
      final TutorReply reply = await serving(<String, Object?>{
        'response': 'Oh no, what is boring?',
        'correction': <String, Object?>{
          'said': 'I am boring',
          'better': "I'm bored",
          'note': "boring = sıkıcı; sen 'sıkılmış' demek istedin",
        },
      }).chatbotChatTurn(message: 'I am boring');

      expect(reply.correction!.note, "boring = sıkıcı; sen 'sıkılmış' demek istedin");
    });

    test('a correction with no note is still a correction', () async {
      // Every server older than this field, and every turn where the model had
      // nothing short to say. The card that has always worked must keep
      // working, note or no note.
      final TutorReply reply = await serving(<String, Object?>{
        'response': 'Where did you go?',
        'correction': <String, Object?>{
          'said': 'I go to Paris yesterday',
          'better': 'I went to Paris yesterday',
        },
      }).chatbotChatTurn(message: 'I go to Paris yesterday');

      expect(reply.correction!.better, 'I went to Paris yesterday');
      expect(reply.correction!.note, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  group('reading the note', () {
    TutorCorrection? parse(Object? note) => TutorCorrection.fromJson(
          <String, Object?>{
            'said': 'I am boring',
            'better': "I'm bored",
            if (note != null) 'note': note,
          },
        );

    test('surrounding space is not part of the explanation', () {
      // Model output arrives with newlines around it about as often as not,
      // and a leading one is a blank first line inside the card.
      expect(parse('  boring means sıkıcı\n')!.note, 'boring means sıkıcı');
    });

    test('a note of nothing but space is absent, not blank', () {
      // Absent and empty have to stay different states. An empty string is
      // still a note as far as the card is concerned, and it draws as a gap
      // under the correction that looks exactly like a card that failed.
      expect(parse('   ')!.note, isNull);
      expect(parse('\n\t ')!.note, isNull);
    });

    test('a note the model would not stop writing costs only the note', () {
      // Asked for a clause, a model that decides to teach the whole of the
      // -ing/-ed distinction instead pushes the corrected line off a phone.
      // Dropping the note is the cheap failure; dropping the correction, or
      // the card, would take the fix away from the learner along with the
      // explanation of it.
      const String essay =
          'Bu cümlede "boring" sıfatı kişinin kendisini değil karşısındakini '
          'tanımlar, bu yüzden burada "bored" kullanılır; İngilizcede -ing ve '
          '-ed sıfatları arasındaki fark tam olarak budur.';
      expect(essay.length, greaterThan(160),
          reason: 'this note is no longer long enough to be the case under test');

      final TutorCorrection? kept = parse(essay);
      expect(kept, isNotNull, reason: 'the correction was thrown out with the note');
      expect(kept!.said, 'I am boring');
      expect(kept.better, "I'm bored");
      expect(kept.note, isNull);
    });

    test('a note the length it was asked for is kept', () {
      // The other side of the cap. A guard that eats ordinary explanations is
      // the same bug as no guard at all, so the boundary is pinned from both
      // directions rather than left to be discovered on a phone.
      expect(parse('x' * 160)!.note, 'x' * 160);
      expect(parse('x' * 161)!.note, isNull);
    });

    test('a note that is not text is simply absent', () {
      // Nothing here trusts the shape of what arrived. Stringifying whatever
      // turned up would put "42" or "{why: because}" under a correction in
      // place of the sentence that was meant to explain it -- and unlike said
      // and better, there is nothing to lose by refusing: the correction is
      // already complete without a note.
      expect(parse(42)!.note, isNull);
      expect(parse(<String, Object?>{'why': 'because'})!.note, isNull);
      expect(parse(<String>['boring = sıkıcı'])!.note, isNull);
      expect(
        TutorCorrection.fromJson(<String, Object?>{
          'said': 'I am boring',
          'better': "I'm bored",
          'note': null,
        })!.note,
        isNull,
        reason: 'an explicit null is the same as no key at all',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // The guards that were there before the note
  // ---------------------------------------------------------------------------

  group('a note changes none of the existing rules', () {
    test('a correction that corrects nothing is still not a correction', () {
      // A good explanation attached to two identical sentences is still a card
      // telling somebody they were wrong and showing them their own words.
      expect(
        TutorCorrection.fromJson(<String, Object?>{
          'said': 'I went to school.',
          'better': 'I went to school',
          'note': 'noktalama farkı önemsizdir',
        }),
        isNull,
      );
    });

    test('a half-built correction is still dropped, note or not', () {
      expect(
        TutorCorrection.fromJson(<String, Object?>{
          'said': 'I am boring',
          'better': '   ',
          'note': 'boring = sıkıcı',
        }),
        isNull,
      );
      expect(
        TutorCorrection.fromJson(<String, Object?>{
          'better': "I'm bored",
          'note': 'boring = sıkıcı',
        }),
        isNull,
      );
    });

    test('isAbout still judges the correction, not the explanation', () {
      // The note is written in another language and shares no words with the
      // transcript, so a check that let it in would reject every real
      // correction that carried one.
      const TutorCorrection fix = TutorCorrection(
        said: 'I am boring',
        better: "I'm bored",
        note: 'boring = sıkıcı; sen sıkılmış demek istedin',
      );
      expect(fix.isAbout('I am boring'), isTrue);
      expect(fix.isAbout('Can I have a coffee please'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // On the card
  // ---------------------------------------------------------------------------

  group('the card', () {
    testWidgets('draws the note under the corrected line, and quieter',
        (WidgetTester tester) async {
      const String why = 'boring = sıkıcı; sen sıkılmış demek istedin';
      await _pumpCard(
        tester,
        const TutorCorrection(
          said: 'I am boring',
          better: "I'm bored",
          note: why,
        ),
      );

      expect(find.text(why), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(why)).dy,
        greaterThan(tester.getTopLeft(find.text("I'm bored")).dy),
        reason: 'the explanation is above the sentence it explains',
      );

      // Quieter than the line it belongs to. The corrected sentence is the
      // thing to take away and reuse; this is read once. If they ever match,
      // the card has two headlines and no answer.
      final TextStyle note = tester.widget<Text>(find.text(why)).style!;
      final TextStyle better = tester.widget<Text>(find.text("I'm bored")).style!;
      expect(note.fontSize, lessThan(better.fontSize!));
      expect(note.color, NfTokens.light.inkMuted);
      expect(note.color, isNot(better.color));
    });

    testWidgets('a full-length note wraps instead of being cut',
        (WidgetTester tester) async {
      // The card is a bubble-width column on a phone, and a note is allowed to
      // run to 160 characters, so multi-line is the normal case rather than
      // the edge one. Half a reason is not a shorter reason.
      const String why =
          'İngilizcede -ing sıfatı bir şeyin nasıl olduğunu, -ed sıfatı ise '
          'kişinin nasıl hissettiğini anlatır.';
      await _pumpCard(
        tester,
        const TutorCorrection(
          said: 'I am boring',
          better: "I'm bored",
          note: why,
        ),
      );

      final Text drawn = tester.widget<Text>(find.text(why));
      expect(drawn.maxLines, isNull, reason: 'the note is capped to a line count');
      expect(drawn.overflow, isNot(TextOverflow.ellipsis));
      expect(
        tester.getSize(find.text(why)).height,
        greaterThan(30),
        reason: 'the note laid out on a single line, so it is being clipped '
            'rather than wrapped',
      );
      expect(tester.takeException(), isNull, reason: 'the note overflowed the card');
    });

    testWidgets('no note leaves nothing behind', (WidgetTester tester) async {
      // The ordinary case, and the one that regresses silently: an empty Text
      // and its gap under the correction is not a missing feature, it is a
      // card that looks broken on every turn that had nothing to explain.
      final Size withNote = await _pumpCard(
        tester,
        const TutorCorrection(
          said: 'I am boring',
          better: "I'm bored",
          note: 'boring = sıkıcı',
        ),
      );
      expect(find.byType(Text), findsNWidgets(4));

      final Size without = await _pumpCard(
        tester,
        const TutorCorrection(said: 'I am boring', better: "I'm bored"),
      );
      expect(find.byType(Text), findsNWidgets(3),
          reason: 'something is still being drawn where the note would be');
      expect(without.height, lessThan(withNote.height),
          reason: 'the card kept the note\'s height without the note in it');
    });
  });
}

/// The correction card alone, at the width a speech bubble gets on a phone.
///
/// Returns the card's size, which is how the absent-note case is checked: the
/// question there is not whether a widget is present but whether the card grew
/// a gap.
Future<Size> _pumpCard(WidgetTester tester, TutorCorrection correction) async {
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
  return tester.getSize(find.byType(NfCard));
}
