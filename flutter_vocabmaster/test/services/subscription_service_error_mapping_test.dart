import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabmaster/l10n/app_localizations.dart';
import 'package:vocabmaster/services/subscription_service.dart';

/// The paywall's sentences, and the language they come out in.
///
/// This service used to hand finished prose to the screen through
/// `LocaleTextService.pick(tr, en)` — two answers for an app that ships seven
/// languages — so on the one screen where money changes hands the Spanish,
/// German, French, Italian and Portuguese app spoke English. These tests pin
/// both halves: the right case is recognised, and the sentence for it exists in
/// every locale.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String say(SubscriptionMessage m, String languageCode) =>
      m.resolve(AppLocalizations(Locale(languageCode)));

  group('SubscriptionService purchase error mapping', () {
    late SubscriptionService service;

    setUp(() {
      service = SubscriptionService();
    });

    test('maps PG-GEMF-02 raw Play error to restore guidance', () {
      final message = service.debugMapRawPlayError(
        'Google Play Billing failed with PG-GEMF-02',
      );

      expect(message?.key, 'subscription.err.playPayment');
      expect(say(message!, 'en'), contains('PG-GEMF-02'));
      expect(say(message, 'en').toLowerCase(), contains('restore'));
    });

    test('maps BillingResponse.error raw Play error to retry guidance', () {
      final message = service.debugMapRawPlayError(
        'BillingResponse.error: service unavailable',
      );

      expect(message?.key, 'subscription.err.playTemporary');
      expect(say(message!, 'en').toLowerCase(), contains('try again'));
      // The billing constant used to be quoted at the buyer inside the
      // sentence. It belongs in the log, not on the paywall.
      expect(say(message, 'en').toLowerCase(),
          isNot(contains('billingresponse')));
    });

    test('says already-subscribed in words, never the billing constant', () {
      final message = service.debugMapRawPlayError('ITEM_ALREADY_OWNED');

      expect(message?.key, 'subscription.err.alreadyOwned');
      expect(say(message!, 'en').toLowerCase(), contains('already subscribed'));
      // Tapping a plan the account owns used to leave a red banner reading
      // "BillingResponse.itemAlreadyOwned" on screen, and it followed the
      // reader onto other pages.
      expect(
          say(message, 'en').toLowerCase(), isNot(contains('billingresponse')));
      expect(say(message, 'en').toLowerCase(),
          isNot(contains('item_already_owned')));
    });

    test('a started restore reports nothing; the restore itself will', () {
      // One tap on an owned plan produced an error dialog, a congratulation
      // and a raw code. The restore this path starts comes back through the
      // purchase stream as `restored` and is reported there, once.
      final List<SubscriptionMessage> reported = <SubscriptionMessage>[];
      service.onPurchaseError = reported.add;

      service.debugReportAlreadyOwned(true);

      expect(reported, isEmpty);
    });

    test('speaks only when no restore started, so it cannot go silent', () {
      final List<SubscriptionMessage> reported = <SubscriptionMessage>[];
      service.onPurchaseError = reported.add;

      service.debugReportAlreadyOwned(false);

      expect(reported, hasLength(1));
      expect(reported.single.key, 'subscription.err.alreadyOwned');
    });

    test('maps structured IAP PG-GEMF-02 error', () {
      final message = service.debugMapPlayStoreError(
        IAPError(
          source: 'google_play',
          code: 'billing_error',
          message: 'PG-GEMF-02',
        ),
      );

      expect(message?.key, 'subscription.err.playPayment');
    });

    test('maps verification auth failure to session guidance', () {
      final message = service.debugBuildVerificationErrorMessage(
        401,
        '{"error":"unauthorized"}',
      );

      expect(message.key, 'subscription.err.sessionVerify');
      expect(say(message, 'en').toLowerCase(), contains('session'));
    });

    test('maps backend product-plan mismatch to support guidance', () {
      final message = service.debugBuildVerificationErrorMessage(
        400,
        '{"error":"Unable to map Google product/base plan"}',
      );

      expect(message.key, 'subscription.err.planMapping');
      expect(say(message, 'en').toLowerCase(), contains('support'));
    });

    test('maps provider unavailable to retry guidance', () {
      final message = service.debugBuildVerificationErrorMessage(
        503,
        '{"code":"PROVIDER_UNAVAILABLE"}',
      );

      expect(message.key, 'subscription.err.providerUnavailable');
      expect(say(message, 'en').toLowerCase(), contains('try again'));
    });

    test('an unrecognised status names the code, never the server prose', () {
      final message = service.debugBuildVerificationErrorMessage(
        502,
        '{"error":"upstream connect error or disconnect/reset before headers"}',
      );

      expect(message.key, 'subscription.err.verifyFailed');
      expect(say(message, 'en'), contains('502'));
      // The server's own English diagnostic used to be pasted into the middle
      // of an otherwise translated sentence.
      expect(say(message, 'en').toLowerCase(), isNot(contains('upstream')));
    });
  });

  group('the paywall speaks the language the app is in', () {
    test('a purchase failure reads differently in each of the seven', () {
      const SubscriptionMessage failure =
          SubscriptionMessage('subscription.err.playPayment');

      final Map<String, String> byLocale = <String, String>{
        for (final Locale locale in AppLocalizations.supportedLocales)
          locale.languageCode: say(failure, locale.languageCode),
      };

      expect(byLocale, hasLength(7));
      expect(byLocale.values.toSet(), hasLength(7),
          reason: 'two locales produced the same sentence, so at least one is '
              'falling back to another language: $byLocale');
      // Named because these are the five that used to read English on the one
      // screen where money changes hands.
      for (final String code in <String>['es', 'de', 'fr', 'it', 'pt']) {
        expect(byLocale[code], isNot(byLocale['en']),
            reason: '$code fell back to English on a purchase failure');
      }
    });

    test('every message this service can send has copy in all seven', () {
      // Read off the service rather than listed by hand: a key added to a new
      // branch and forgotten in six locales is exactly the failure this file
      // exists to catch, and a hand-written list would not see it.
      final RegExp keys = RegExp(r"SubscriptionMessage\(\s*'([^']+)'");
      final String source =
          File('lib/services/subscription_service.dart').readAsStringSync();
      final Set<String> used =
          keys.allMatches(source).map((m) => m.group(1)!).toSet();

      expect(used.length, greaterThan(15),
          reason: 'the scanner found only ${used.length} keys, so it has gone '
              'blind and nothing below is being checked');

      final List<String> missing = <String>[];
      for (final String key in used) {
        for (final Locale locale in AppLocalizations.supportedLocales) {
          final String text = AppLocalizations(locale).t(key);
          // `t` returns the key itself when nothing carries it, so an unknown
          // key renders as its own name on the paywall rather than failing.
          if (text == key) missing.add('${locale.languageCode}: $key');
        }
      }

      expect(missing, isEmpty,
          reason: 'These would render as their own key name on the paywall:\n'
              '${missing.join('\n')}');
    });
  });

  group('a trial the server refused', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('is remembered, so the paywall can stop promising one', () async {
      expect(await SubscriptionService.wasTrialBlocked(), isFalse,
          reason: 'the promise holds until the server says otherwise');

      await SubscriptionService.rememberTrialBlocked('device-limit');

      expect(await SubscriptionService.wasTrialBlocked(), isTrue);
    });

    test('every reason the backend sends counts as a refusal', () async {
      // TrialAbuseProtectionService.evaluate has exactly three ways to say no.
      for (final String reason in <String>[
        'device-limit',
        'ip-limit',
        'protection-unavailable',
      ]) {
        await SubscriptionService.rememberTrialBlocked(reason);
        expect(await SubscriptionService.wasTrialBlocked(), isTrue,
            reason: '"$reason" is a refusal like any other');
      }
    });

    test('does not follow the next account onto a shared phone', () async {
      await SubscriptionService.rememberTrialBlocked('ip-limit');

      // A sign-in that was granted its trial says so by sending nothing.
      await SubscriptionService.rememberTrialBlocked(null);

      expect(await SubscriptionService.wasTrialBlocked(), isFalse);
    });

    test('an all-whitespace reason is not a refusal', () async {
      await SubscriptionService.rememberTrialBlocked('   ');

      expect(await SubscriptionService.wasTrialBlocked(), isFalse,
          reason: 'a blank field is the server saying nothing, not saying no');
    });
  });
}
