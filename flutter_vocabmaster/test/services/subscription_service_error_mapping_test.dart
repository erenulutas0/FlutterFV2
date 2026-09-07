import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:vocabmaster/services/subscription_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionService purchase error mapping', () {
    late SubscriptionService service;

    setUp(() {
      service = SubscriptionService();
    });

    test('maps PG-GEMF-02 raw Play error to restore guidance', () {
      final message = service.debugMapRawPlayError(
        'Google Play Billing failed with PG-GEMF-02',
      );

      expect(message, isNotNull);
      expect(message, contains('PG-GEMF-02'));
      expect(message!.toLowerCase(), contains('restore'));
    });

    test('maps BillingResponse.error raw Play error to retry guidance', () {
      final message = service.debugMapRawPlayError(
        'BillingResponse.error: service unavailable',
      );

      expect(message, isNotNull);
      expect(message!.toLowerCase(), contains('try again'));
    });

    test('says already-subscribed in words, never the billing constant', () {
      final message = service.debugMapRawPlayError('ITEM_ALREADY_OWNED');

      expect(message, isNotNull);
      expect(message!.toLowerCase(), contains('already subscribed'));
      // Tapping a plan the account owns used to leave a red banner reading
      // "BillingResponse.itemAlreadyOwned" on screen, and it followed the
      // reader onto other pages.
      expect(message.toLowerCase(), isNot(contains('billingresponse')));
      expect(message.toLowerCase(), isNot(contains('item_already_owned')));
    });

    test('a started restore reports nothing; the restore itself will', () {
      // One tap on an owned plan produced an error dialog, a congratulation
      // and a raw code. The restore this path starts comes back through the
      // purchase stream as `restored` and is reported there, once.
      final List<String> reported = <String>[];
      service.onPurchaseError = reported.add;

      service.debugReportAlreadyOwned(true);

      expect(reported, isEmpty);
    });

    test('speaks only when no restore started, so it cannot go silent', () {
      final List<String> reported = <String>[];
      service.onPurchaseError = reported.add;

      service.debugReportAlreadyOwned(false);

      expect(reported, hasLength(1));
      expect(reported.single.toLowerCase(), contains('already subscribed'));
    });

    test('maps structured IAP PG-GEMF-02 error', () {
      final message = service.debugMapPlayStoreError(
        IAPError(
          source: 'google_play',
          code: 'billing_error',
          message: 'PG-GEMF-02',
        ),
      );

      expect(message, isNotNull);
      expect(message, contains('PG-GEMF-02'));
      expect(message!.toLowerCase(), contains('restore'));
    });

    test('maps verification auth failure to session guidance', () {
      final message = service.debugBuildVerificationErrorMessage(
        401,
        '{"error":"unauthorized"}',
      );

      expect(message.toLowerCase(), contains('session verification failed'));
      expect(message.toLowerCase(), contains('reopen'));
    });

    test('maps backend product-plan mismatch to support guidance', () {
      final message = service.debugBuildVerificationErrorMessage(
        400,
        '{"error":"Unable to map Google product/base plan"}',
      );

      expect(message.toLowerCase(), contains('product plan'));
      expect(message.toLowerCase(), contains('backend mapping'));
    });

    test('maps provider unavailable to retry guidance', () {
      final message = service.debugBuildVerificationErrorMessage(
        503,
        '{"code":"PROVIDER_UNAVAILABLE"}',
      );

      expect(message.toLowerCase(), contains('verification service'));
      expect(message.toLowerCase(), contains('try again'));
    });
  });
}
