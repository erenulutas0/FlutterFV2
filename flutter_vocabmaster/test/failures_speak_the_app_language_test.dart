import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabmaster/frontend_newest/screens/nf_subscription_page.dart';
import 'package:vocabmaster/l10n/app_localizations.dart';
import 'package:vocabmaster/services/ai_error_message_formatter.dart';
import 'package:vocabmaster/services/api_service.dart';
import 'package:vocabmaster/services/local_reminder_service.dart';
import 'package:vocabmaster/services/locale_text_service.dart';

/// Four places where the app stopped being translated.
///
/// The app ships seven interface languages and its screens are fully localised.
/// The strings that never made it into the key table are almost all in the two
/// places that matter most — where money changes hands, and where something has
/// gone wrong — because those are written last and read by someone least able
/// to cope with a second language.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => LocaleTextService.setAppLocale(const Locale('en')));
  tearDown(() => LocaleTextService.setAppLocale(const Locale('en')));

  group('the two quota reasons nothing recognised', () {
    // AiTokenQuotaService blocks on these when a free account exhausts the
    // ceiling shared by every non-paying user on one device or one address.
    // The formatter knew six reasons and printed the server's raw string for
    // anything else -- and the server's string for these two is the Turkish
    // sentence "Günlük AI hakkınız bitti. Lütfen daha sonra tekrar deneyin."
    const String serverPhrase = 'Günlük AI hakkınız bitti';

    ApiQuotaExceededException blocked(String reason) =>
        ApiQuotaExceededException(
          message: '$serverPhrase. Lütfen daha sonra tekrar deneyin.',
          reason: reason,
        );

    for (final String reason in <String>[
      'non-paid-device-token-quota',
      'non-paid-ip-token-quota',
    ]) {
      test('$reason is named, not echoed', () {
        for (final Locale locale in AppLocalizations.supportedLocales) {
          LocaleTextService.setAppLocale(locale);
          final String text = AiErrorMessageFormatter.forQuota(blocked(reason));

          expect(text, isNot(contains(serverPhrase)),
              reason: 'the server sentence reached the ${locale.languageCode} '
                  'screen verbatim');
          expect(text, isNotEmpty);
        }
      });
    }

    test('each reads differently in each of the seven languages', () {
      for (final String reason in <String>[
        'non-paid-device-token-quota',
        'non-paid-ip-token-quota',
      ]) {
        final Map<String, String> byLocale = <String, String>{};
        for (final Locale locale in AppLocalizations.supportedLocales) {
          LocaleTextService.setAppLocale(locale);
          byLocale[locale.languageCode] =
              AiErrorMessageFormatter.forQuota(blocked(reason));
        }
        expect(byLocale.values.toSet(), hasLength(7),
            reason: 'a locale is falling back to another language for '
                '$reason: $byLocale');
      }
    });

    test('the device and the network are told apart', () {
      // Two different facts. Telling somebody on a shared office connection
      // that their phone is the problem sends them to reinstall the app.
      expect(
        AiErrorMessageFormatter.forQuota(blocked('non-paid-device-token-quota')),
        isNot(AiErrorMessageFormatter.forQuota(
            blocked('non-paid-ip-token-quota'))),
      );
    });

    test('neither blames the learner for their own allowance', () {
      // The shared ceiling is not the learner's daily quota, and the sentence
      // for that one must not be reused here: somebody who has asked for
      // nothing all day would read that they had used everything up.
      final String own = AiErrorMessageFormatter.forQuota(
        ApiQuotaExceededException(message: '', reason: 'daily-token-quota'),
      );
      for (final String reason in <String>[
        'non-paid-device-token-quota',
        'non-paid-ip-token-quota',
      ]) {
        expect(AiErrorMessageFormatter.forQuota(blocked(reason)), isNot(own));
      }
    });
  });

  group('a dead session', () {
    test('never shows the word Spring sends', () {
      // Spring's entry point answers an expired JWT with {"error":"Unauthorized"}
      // and nothing else, and the handler printed `message` straight into a red
      // snackbar: a single English word, in every one of the seven languages,
      // moments before the learner was signed out.
      for (final Locale locale in AppLocalizations.supportedLocales) {
        LocaleTextService.setAppLocale(locale);
        final String text = AiErrorMessageFormatter.forUnauthorized(
          ApiUnauthorizedException(message: 'Unauthorized', statusCode: 401),
        );

        expect(text, isNot('Unauthorized'));
        expect(text.toLowerCase(), isNot(contains('unauthorized')));
      }
    });

    test('reads in the app language, not English or Turkish', () {
      final Map<String, String> byLocale = <String, String>{};
      for (final Locale locale in AppLocalizations.supportedLocales) {
        LocaleTextService.setAppLocale(locale);
        byLocale[locale.languageCode] = AiErrorMessageFormatter.forUnauthorized(
          ApiUnauthorizedException(message: 'Unauthorized', statusCode: 401),
        );
      }

      expect(byLocale.values.toSet(), hasLength(7), reason: '$byLocale');
      expect(byLocale['de'], isNot(byLocale['en']));
      expect(byLocale['de'], isNot(byLocale['tr']));
    });

    test('the client-side missing-token case says the same thing', () {
      // ApiService._protectedHeaders threw the literal Turkish sentence
      // 'Oturum bulunamadi. Lutfen yeniden giris yapin.', and the same line
      // showed it verbatim. Both are "you are signed out"; both are answered
      // by the reader's own language now.
      LocaleTextService.setAppLocale(const Locale('de'));
      final String german = AiErrorMessageFormatter.forUnauthorized(
        ApiUnauthorizedException(
          message: 'No auth context: token or user id is missing.',
          reason: 'missing-auth-context',
        ),
      );

      expect(german, isNot(contains('Oturum')));
      expect(german, isNot(contains('auth context')));
      expect(german, AppLocalizations(const Locale('de'))
          .t('common.err.sessionExpired'));
    });

    test('a template fills with the session line rather than stripping', () {
      LocaleTextService.setAppLocale(const Locale('es'));
      final String filled = AiErrorMessageFormatter.intoTemplate(
        'No se pudo cargar: {error}',
        ApiUnauthorizedException(message: 'Unauthorized', statusCode: 401),
      );

      expect(filled, startsWith('No se pudo cargar: '));
      expect(filled, isNot(contains('{error}')));
    });
  });

  group('notification copy', () {
    // All four local reminders default to ON and are armed automatically at
    // startup, so a German learner who never opened the notification settings
    // still got English push copy from a German app: the scheduler chose
    // between a Turkish and an English literal.
    const List<String> keys = <String>[
      'notif.push.daily.body',
      'notif.push.streak.title',
      'notif.push.streak.body',
      'notif.push.streak.body.one',
      'notif.push.trial.title',
      'notif.push.trial.body',
      'notif.push.trial.body.one',
      'notif.push.recall.title',
      'notif.push.recall.meaning',
      'notif.push.recall.review',
    ];

    test('exists in all seven languages', () {
      final List<String> offenders = <String>[];
      for (final String key in keys) {
        final Set<String> seen = <String>{};
        for (final Locale locale in AppLocalizations.supportedLocales) {
          LocaleTextService.setAppLocale(locale);
          final String text = LocalReminderService.copy(key);
          // `t` answers with the key itself when nothing carries it, so a
          // missing translation is delivered to the phone rather than failing.
          if (text == key) {
            offenders.add('${locale.languageCode}: $key is missing');
            continue;
          }
          if (!seen.add(text)) {
            offenders.add('${locale.languageCode}: $key repeats another '
                'language, so it is falling back');
          }
        }
      }

      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('a scheduled reminder carries the number it was armed with', () {
      LocaleTextService.setAppLocale(const Locale('fr'));
      final String body =
          LocalReminderService.copy('notif.push.streak.body', args: {'n': '12'});

      expect(body, contains('12'));
      expect(body, isNot(contains('{n}')));
    });

    test('the word being recalled is named, in every language', () {
      for (final Locale locale in AppLocalizations.supportedLocales) {
        LocaleTextService.setAppLocale(locale);
        final String body = LocalReminderService.copy(
          'notif.push.recall.meaning',
          args: {'word': 'elaborate'},
        );

        expect(body, contains('elaborate'),
            reason: '${locale.languageCode} lost the word, which is the whole '
                'point of this notification');
      }
    });
  });

  group('the paywall trial note', () {
    Future<void> show(WidgetTester tester,
        {required bool blocked, Locale locale = const Locale('de')}) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: PaywallTrialNote(trialWasBlocked: blocked)),
        ),
      );
      await tester.pump();
    }

    final Finder note = find.byKey(const ValueKey<String>('paywall-trial-note'));

    testWidgets('is shown to the accounts that really got a trial',
        (tester) async {
      await show(tester, blocked: false);

      expect(note, findsOneWidget);
      expect(
        tester.widget<Text>(note).data,
        AppLocalizations(const Locale('de')).t('subscription.trialNote'),
      );
    });

    testWidgets('is gone when the server refused this account its trial',
        (tester) async {
      // The claim is "New accounts start with a 7-day trial quota". For an
      // account the server refused, that is false at the moment it is read --
      // and it was shown to exactly that reader, because nothing in the app
      // looked at trialBlockedReason.
      await show(tester, blocked: true);

      expect(note, findsNothing);
      expect(
        find.textContaining('7'),
        findsNothing,
        reason: 'no trace of the promise may survive',
      );
    });
  });
}
