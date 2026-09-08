import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import 'auth_service.dart';

/// One thing the purchase flow has to say, named rather than written out.
///
/// This service used to hand finished sentences to the paywall through
/// `LocaleTextService.pick(tr, en)` — Turkish when the app is `tr`, English
/// otherwise. Every message the paywall DISPLAYS comes from here, so on the one
/// screen where money changes hands the Spanish, German, French, Italian and
/// Portuguese app spoke English: the confirmation dialog, the restore line and
/// every purchase failure. The worst of them handed the buyer a Play Console
/// debugging instruction naming the product id and the base plan.
///
/// A key rather than a sentence, because a service has no BuildContext and the
/// screen that shows the message does. [args] fills the `{placeholders}` the
/// key's own text declares.
@immutable
class SubscriptionMessage {
  const SubscriptionMessage(this.key, {this.args = const <String, String>{}});

  final String key;
  final Map<String, String> args;

  String resolve(AppLocalizations l10n) {
    var text = l10n.t(key);
    for (final MapEntry<String, String> arg in args.entries) {
      text = text.replaceAll('{${arg.key}}', arg.value);
    }
    return text;
  }

  /// The key, so an analytics `reason` is a stable identifier rather than a
  /// sentence that changes with the reader's language.
  @override
  String toString() => key;

  @override
  bool operator ==(Object other) =>
      other is SubscriptionMessage &&
      other.key == key &&
      mapEquals(other.args, args);

  @override
  int get hashCode => Object.hash(key, Object.hashAllUnordered(args.entries));
}

/// A failure the purchase flow can name, thrown where the old code threw an
/// `Exception` carrying a Turkish sentence.
class SubscriptionMessageException implements Exception {
  const SubscriptionMessageException(this.message);

  final SubscriptionMessage message;

  @override
  String toString() => message.key;
}

class SubscriptionPlan {
  final int id;
  final String name;
  final double price;
  final String currency;
  final int durationDays;
  final String? features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.durationDays,
    this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      currency: json['currency'],
      durationDays: json['durationDays'],
      features: json['features'],
    );
  }

  String get googlePlayProductId {
    switch (name) {
      case 'PRO_MONTHLY':
        return 'pro_monthly_subscription';
      case 'PRO_ANNUAL':
        return 'pro_annual_subscription';
      case 'PREMIUM':
        return 'premium_monthly';
      case 'PREMIUM_PLUS':
        return 'premium_plus_monthly';
      default:
        return '';
    }
  }

  String get appleProductId {
    switch (name) {
      case 'PRO_MONTHLY':
        return 'com.vocabmaster.pro.monthly';
      case 'PRO_ANNUAL':
        return 'com.vocabmaster.pro.annual';
      case 'PREMIUM':
        return 'com.vocabmaster.pro.monthly';
      case 'PREMIUM_PLUS':
        return 'com.vocabmaster.pro.annual';
      default:
        return '';
    }
  }
}

class SubscriptionService {
  final AuthService _authService = AuthService();
  InAppPurchase get _inAppPurchase => InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Function(SubscriptionMessage message)? onPurchaseSuccess;
  Function(SubscriptionMessage error)? onPurchaseError;
  SubscriptionMessage? _lastVerificationError;
  DateTime? _lastRestoreAttemptAt;

  /// Where the server's refusal of a new account's 7-day trial is kept.
  ///
  /// The backend decides at sign-up — a device that has already claimed one, an
  /// address that has, or a Redis blip while it was checking — and says so once,
  /// as `trialBlockedReason` in the login response. Nothing asks again, and the
  /// account simply lands on the free tier. Until this key existed the paywall
  /// had no way to know, so it went on offering "New accounts start with a
  /// 7-day trial quota" to the one reader for whom that had just been refused.
  static const String trialBlockedReasonKey =
      'subscription:trial_blocked_reason';

  /// Records what the login response said about this account's trial.
  ///
  /// Called on every successful sign-in, with null when the trial was granted,
  /// so a second account on the same phone cannot inherit the first one's
  /// verdict.
  static Future<void> rememberTrialBlocked(String? reason) async {
    final prefs = await SharedPreferences.getInstance();
    final String trimmed = (reason ?? '').trim();
    if (trimmed.isEmpty) {
      await prefs.remove(trialBlockedReasonKey);
      return;
    }
    await prefs.setString(trialBlockedReasonKey, trimmed);
  }

  /// Whether this account was refused the trial, and so must not be promised one.
  static Future<bool> wasTrialBlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(trialBlockedReasonKey) ?? '').trim().isNotEmpty;
  }

  void initializePurchaseStream() {
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('IAP Error: $error'),
    );
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<bool> isIAPAvailable() async {
    return await _inAppPurchase.isAvailable();
  }

  Future<void> restorePurchases() async {
    await syncOwnedPurchases(force: true);
  }

  Future<bool> syncOwnedPurchases({bool force = false}) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }

    final available = await isIAPAvailable();
    if (!available) {
      return false;
    }

    final now = DateTime.now();
    final lastAttemptAt = _lastRestoreAttemptAt;
    if (!force &&
        lastAttemptAt != null &&
        now.difference(lastAttemptAt) < const Duration(seconds: 10)) {
      return false;
    }

    _lastRestoreAttemptAt = now;
    await _inAppPurchase.restorePurchases();
    return true;
  }

  Future<List<ProductDetails>> getStoreProducts() async {
    final Set<String> productIds = {
      'pro_monthly_subscription',
      'pro_annual_subscription',
      'premium_monthly',
      'premium_plus_monthly',
    };

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }
    debugPrint(
      'Store products found: ${response.productDetails.map((p) => p.id).toList()}',
    );

    return response.productDetails;
  }

  Future<bool> purchaseWithIAP(SubscriptionPlan plan) async {
    try {
      final available = await isIAPAvailable();
      if (!available) {
        onPurchaseError?.call(
          const SubscriptionMessage('subscription.err.iapUnavailable'),
        );
        return false;
      }

      await _refreshPurchaseSessionIfPossible();

      final String productId =
          Platform.isIOS ? plan.appleProductId : plan.googlePlayProductId;

      if (productId.isEmpty) {
        onPurchaseError?.call(
          const SubscriptionMessage('subscription.err.planUnavailable'),
        );
        return false;
      }

      final products = await getStoreProducts();
      final product = products.where((p) => p.id == productId).firstOrNull;

      if (product == null) {
        // The buyer used to be handed the console instruction that belongs in
        // this log line: "Store product not found: pro_annual_subscription.
        // Check that the Play Console product/base plan is active and
        // available to this tester." Nothing in that sentence is actionable by
        // the person reading it, and it was English in five of the seven
        // languages the app ships.
        debugPrint(
          'Store product missing for plan ${plan.name}: $productId. Check that '
          'the Play Console product/base plan is active and released to this '
          'account.',
        );
        onPurchaseError?.call(
          const SubscriptionMessage('subscription.err.planUnavailable'),
        );
        return false;
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      if (!started) {
        onPurchaseError?.call(
          const SubscriptionMessage('subscription.err.purchaseNotStarted'),
        );
      }
      return started;
    } catch (e) {
      final lower = e.toString().toLowerCase();
      if (lower.contains('already') && lower.contains('owned')) {
        try {
          _reportAlreadyOwned(await syncOwnedPurchases(force: true));
          return false;
        } catch (_) {
          _reportAlreadyOwned(false);
          return false;
        }
      }
      final mapped = _mapRawPlayError(e.toString());
      if (mapped != null) {
        onPurchaseError?.call(mapped);
        return false;
      }
      // Deliberately without the exception text. Pasting it here is what put
      // "BillingResponse.itemAlreadyOwned" on screen in red, under a dialog
      // that had already said the same thing in words.
      debugPrint('Purchase could not be started: $e');
      onPurchaseError?.call(
        const SubscriptionMessage('subscription.err.purchaseNotStarted'),
      );
      return false;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('Purchase pending...');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        final alreadyOwned = _isAlreadyOwnedError(purchaseDetails.error);
        if (alreadyOwned) {
          try {
            _reportAlreadyOwned(await syncOwnedPurchases(force: true));
          } catch (_) {
            _reportAlreadyOwned(false);
          }
        } else {
          // The plugin's own `error.message` used to be the second fallback
          // here. It is a Play SDK string — English at best, a billing
          // constant at worst — so an unrecognised billing failure now says
          // the one true thing we know instead, and the raw code goes to the
          // log where it is useful.
          final mapped = _mapPlayStoreError(purchaseDetails.error);
          if (mapped == null) {
            debugPrint(
              'Unmapped Play purchase error: code=${purchaseDetails.error?.code} '
              'message=${purchaseDetails.error?.message}',
            );
          }
          onPurchaseError?.call(
            mapped ??
                const SubscriptionMessage('subscription.err.purchaseGeneric'),
          );
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        final verified = await _verifyPurchaseWithBackend(purchaseDetails);

        if (verified) {
          _lastVerificationError = null;
          // A restore is not a purchase, and saying "activated" for one is what
          // congratulated the buyer of a plan they already had.
          onPurchaseSuccess?.call(
            purchaseDetails.status == PurchaseStatus.restored
                ? const SubscriptionMessage('subscription.success.restored')
                : const SubscriptionMessage('subscription.success.activated'),
          );
        } else {
          onPurchaseError?.call(
            _lastVerificationError ??
                const SubscriptionMessage('subscription.err.notVerified'),
          );
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<bool> _verifyPurchaseWithBackend(
      PurchaseDetails purchaseDetails) async {
    try {
      await _refreshPurchaseSessionIfPossible();

      final apiUrl = await AppConfig.apiBaseUrl;
      var userId = await _resolveUserIdForPurchase();
      var token = await _authService.getToken();
      final purchaseToken =
          purchaseDetails.verificationData.serverVerificationData.trim();

      if (userId == null || userId <= 0) {
        final refreshed = await _authService.refreshSession();
        if (refreshed) {
          userId = await _resolveUserIdForPurchase();
          token = await _authService.getToken();
        }
        if (userId == null || userId <= 0) {
          _lastVerificationError =
              const SubscriptionMessage('subscription.err.noIdentity');
          debugPrint('Backend verification failed: missing userId');
          return false;
        }
      }

      if (token == null || token.isEmpty) {
        final refreshed = await _authService.refreshSession();
        if (refreshed) {
          token = await _authService.getToken();
        }
        if (token == null || token.isEmpty) {
          _lastVerificationError =
              const SubscriptionMessage('subscription.err.sessionRefresh');
          debugPrint('Backend verification failed: missing token');
          return false;
        }
      }
      if (purchaseToken.isEmpty) {
        _lastVerificationError =
            const SubscriptionMessage('subscription.err.tokenMissing');
        debugPrint(
          'Backend verification failed: empty purchase token product=${purchaseDetails.productID}',
        );
        return false;
      }

      final endpoint = Platform.isIOS
          ? '$apiUrl/subscription/verify/apple'
          : '$apiUrl/subscription/verify/google';

      final productId = purchaseDetails.productID;
      String planName = 'PRO_MONTHLY';
      if (productId == 'pro_annual_subscription') {
        planName = 'PRO_ANNUAL';
      } else if (productId == 'premium_monthly') {
        planName = 'PREMIUM';
      } else if (productId == 'premium_plus_monthly') {
        planName = 'PREMIUM_PLUS';
      }

      Future<http.Response> sendVerificationRequest(String bearerToken) {
        return http.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'X-User-Id': userId.toString(),
            'Authorization': 'Bearer $bearerToken',
          },
          body: json.encode({
            'planName': planName,
            'purchaseToken': purchaseToken,
            'productId': purchaseDetails.productID,
          }),
        );
      }

      var response = await sendVerificationRequest(token);
      if (response.statusCode == 401 || response.statusCode == 403) {
        final refreshed = await _authService.refreshSession();
        if (refreshed) {
          token = await _authService.getToken();
          userId = await _resolveUserIdForPurchase() ?? userId;
          if (token != null && token.isNotEmpty) {
            response = await sendVerificationRequest(token);
          }
        }
      }

      if (response.statusCode != 200) {
        _lastVerificationError =
            _buildVerificationErrorMessage(response.statusCode, response.body);
        debugPrint(
          'Backend verification failed: status=${response.statusCode} body=${response.body}',
        );
        return false;
      }

      try {
        await _authService.refreshProfile();
      } catch (e) {
        debugPrint('Profile refresh after purchase verification failed: $e');
      }
      return true;
    } catch (e) {
      // Without the exception. Interpolating it here is how the buyer of a
      // plan read a SocketException, hostname and errno included, in the
      // middle of a sentence about their payment.
      _lastVerificationError =
          const SubscriptionMessage('subscription.err.verifyConnection');
      debugPrint('Backend verification failed: $e');
      return false;
    }
  }

  /// What to say when Play refuses a purchase because the account already has it.
  ///
  /// Not an error, and it used to be reported as three at once: a red dialog
  /// ("aboneliğiniz zaten var"), a congratulation from the restore this same
  /// path kicks off, and a persistent banner carrying the raw
  /// `BillingResponse.itemAlreadyOwned`. One tap, three messages, two of them
  /// contradicting each other.
  ///
  /// When a restore did start, the recovered purchase comes back through this
  /// same stream as [PurchaseStatus.restored] and is reported there, once — so
  /// this stays quiet. It speaks only when there is nothing else to report.
  void _reportAlreadyOwned(bool restoreStarted) {
    if (restoreStarted) {
      return;
    }
    onPurchaseError?.call(
      const SubscriptionMessage('subscription.err.alreadyOwned'),
    );
  }

  bool _isAlreadyOwnedError(IAPError? error) {
    if (error == null) {
      return false;
    }
    final code = error.code.toLowerCase();
    final message = error.message.toLowerCase();
    return code.contains('already') ||
        code.contains('owned') ||
        code.contains('item_already_owned') ||
        message.contains('already owned');
  }

  SubscriptionMessage? _mapPlayStoreError(IAPError? error) {
    if (error == null) {
      return null;
    }
    final code = error.code.toLowerCase();
    final message = error.message.toLowerCase();
    if (message.contains('pg-gemf-02') || code.contains('pg-gemf-02')) {
      return const SubscriptionMessage('subscription.err.playPayment');
    }
    if (code == 'error' || code.contains('billingresponse.error')) {
      return const SubscriptionMessage('subscription.err.playTemporary');
    }
    return null;
  }

  /// The same three cases as [_mapPlayStoreError], read out of a raw exception
  /// string rather than a structured [IAPError].
  ///
  /// Each situation answers with one key, shared with its structured twin.
  /// Two wordings for one situation is how the buyer of an owned plan ended up
  /// reading three messages for a single tap.
  SubscriptionMessage? _mapRawPlayError(String rawError) {
    final lower = rawError.toLowerCase();
    if (lower.contains('pg-gemf-02')) {
      return const SubscriptionMessage('subscription.err.playPayment');
    }
    if (lower.contains('billingresponse.error') ||
        lower.contains('service unavailable')) {
      return const SubscriptionMessage('subscription.err.playTemporary');
    }
    if (lower.contains('itemalreadyowned') ||
        lower.contains('item_already_owned')) {
      return const SubscriptionMessage('subscription.err.alreadyOwned');
    }
    return null;
  }

  @visibleForTesting
  SubscriptionMessage? debugMapPlayStoreError(IAPError? error) {
    return _mapPlayStoreError(error);
  }

  @visibleForTesting
  SubscriptionMessage? debugMapRawPlayError(String rawError) {
    return _mapRawPlayError(rawError);
  }

  @visibleForTesting
  void debugReportAlreadyOwned(bool restoreStarted) {
    _reportAlreadyOwned(restoreStarted);
  }

  Future<int?> _resolveUserIdForPurchase() async {
    var userId = await _authService.getUserId();
    if (userId != null && userId > 0) {
      return userId;
    }

    try {
      await _authService.refreshProfile();
    } catch (_) {
      // ignore and retry local resolution
    }

    userId = await _authService.getUserId();
    return (userId != null && userId > 0) ? userId : null;
  }

  Future<void> _refreshPurchaseSessionIfPossible() async {
    try {
      await _authService.refreshSession();
    } catch (e) {
      debugPrint('Purchase session pre-refresh failed: $e');
    }
  }

  SubscriptionMessage _buildVerificationErrorMessage(
      int statusCode, String body) {
    String? code;
    String? error;
    try {
      final parsed = json.decode(body);
      if (parsed is Map<String, dynamic>) {
        code = parsed['code']?.toString();
        error = parsed['error']?.toString();
      }
    } catch (_) {
      // fall through
    }
    final normalized = '$code $error $body'.toLowerCase();

    if (statusCode == 401 || statusCode == 403) {
      if (normalized.contains('user identity mismatch')) {
        return const SubscriptionMessage('subscription.err.identityMismatch');
      }
      return const SubscriptionMessage('subscription.err.sessionVerify');
    }
    if (statusCode == 400 && normalized.contains('purchasetoken is required')) {
      return const SubscriptionMessage('subscription.err.tokenMissing');
    }
    // Two distinct backend faults — the Play product has no mapping, or the
    // plan the mapping names is gone — and one thing the buyer can do about
    // either. The distinction is kept where it is useful, in the log.
    if (statusCode == 400 &&
        (normalized.contains('unable to map google product/base plan') ||
            normalized.contains('mapped plan not found'))) {
      debugPrint('Subscription plan mapping rejected by backend: $body');
      return const SubscriptionMessage('subscription.err.planMapping');
    }
    if (statusCode == 400 && code == 'INVALID_PURCHASE') {
      return const SubscriptionMessage('subscription.err.invalidPurchase');
    }
    if (statusCode == 503 && code == 'PROVIDER_UNAVAILABLE') {
      return const SubscriptionMessage('subscription.err.providerUnavailable');
    }
    // The server's own `error` string used to be pasted in here. It is written
    // for whoever reads the logs, in English, and it reached the buyer inside
    // an otherwise translated sentence.
    if (error != null && error.isNotEmpty) {
      debugPrint('Unmapped verification error from backend: $error');
    }
    return SubscriptionMessage(
      'subscription.err.verifyFailed',
      args: {'code': '$statusCode'},
    );
  }

  @visibleForTesting
  SubscriptionMessage debugBuildVerificationErrorMessage(
      int statusCode, String body) {
    return _buildVerificationErrorMessage(statusCode, body);
  }

  /// Get plans from backend
  Future<List<SubscriptionPlan>> getPlans() async {
    final apiUrl = await AppConfig.apiBaseUrl;
    final url = '$apiUrl/subscription/plans';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SubscriptionPlan.fromJson(json)).toList();
      }
      debugPrint('Plans request failed: HTTP ${response.statusCode} at $url');
      throw const SubscriptionMessageException(
        SubscriptionMessage('subscription.err.plansLoad'),
      );
    } on SubscriptionMessageException {
      rethrow;
    } catch (e) {
      // The original failure travels on rather than being wrapped: being
      // offline is the commonest way to land here, and only the exception
      // itself still says so. AiErrorMessageFormatter names that case; a
      // wrapper would have flattened it into "the plans could not be loaded".
      debugPrint('Plans request failed for $url: $e');
      rethrow;
    }
  }

  /// Get user's subscription status
  Future<Map<String, dynamic>> getUserSubscriptionStatus() async {
    final apiUrl = await AppConfig.apiBaseUrl;
    var userId = await _authService.getUserId();
    var token = await _authService.getToken();

    if (userId == null || userId <= 0 || token == null || token.isEmpty) {
      final refreshed = await _authService.refreshSession();
      if (refreshed) {
        userId = await _authService.getUserId();
        token = await _authService.getToken();
      }
    }

    if (userId == null || userId <= 0) {
      throw const SubscriptionMessageException(
        SubscriptionMessage('common.err.sessionExpired'),
      );
    }

    Future<http.Response> sendStatusRequest(String? bearerToken) {
      return http.get(
        Uri.parse('$apiUrl/users/$userId/subscription/status'),
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': userId.toString(),
          if (bearerToken != null && bearerToken.isNotEmpty)
            'Authorization': 'Bearer $bearerToken',
        },
      );
    }

    var response = await sendStatusRequest(token);
    if (response.statusCode == 401 || response.statusCode == 403) {
      final refreshed = await _authService.refreshSession();
      if (refreshed) {
        userId = await _authService.getUserId() ?? userId;
        token = await _authService.getToken();
        response = await sendStatusRequest(token);
      }
    }

    if (response.statusCode == 200) {
      try {
        await _authService.refreshProfile();
      } catch (e) {
        debugPrint('Profile refresh after subscription status failed: $e');
      }
      return json.decode(response.body);
    }

    throw SubscriptionMessageException(
      _buildVerificationErrorMessage(response.statusCode, response.body),
    );
  }

  /// DEMO MODE: Activate subscription without payment (for testing only!)
  Future<Map<String, dynamic>> activateDemoSubscription(int planId) async {
    final apiUrl = await AppConfig.apiBaseUrl;
    final userId = await _authService.getUserId();

    final response = await http.post(
      Uri.parse('$apiUrl/subscription/demo/activate'),
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': userId.toString(),
      },
      body: json.encode({
        'planId': planId,
      }),
    );

    if (response.statusCode == 200) {
      try {
        await _authService.refreshProfile();
      } catch (e) {
        debugPrint('Profile refresh after demo subscription failed: $e');
      }
      return json.decode(response.body);
    } else {
      debugPrint(
        'Demo activation failed: status=${response.statusCode} body=${response.body}',
      );
      throw const SubscriptionMessageException(
        SubscriptionMessage('subscription.err.demoFailed'),
      );
    }
  }
}
