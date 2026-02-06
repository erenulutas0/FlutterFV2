import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

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

  /// Maps plan name to Google Play product ID
  String get googlePlayProductId {
    switch (name) {
      case 'PRO_MONTHLY':
        return 'pro_monthly_subscription';
      case 'PRO_ANNUAL':
        return 'pro_annual_subscription';
      default:
        return '';
    }
  }

  /// Maps plan name to Apple App Store product ID
  String get appleProductId {
    switch (name) {
      case 'PRO_MONTHLY':
        return 'com.vocabmaster.pro.monthly';
      case 'PRO_ANNUAL':
        return 'com.vocabmaster.pro.annual';
      default:
        return '';
    }
  }
}

class SubscriptionService {
  final AuthService _authService = AuthService();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Function(String message)? onPurchaseSuccess;
  Function(String error)? onPurchaseError;

  /// Initialize IAP listener
  void initializePurchaseStream() {
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('IAP Error: $error'),
    );
  }

  /// Dispose the stream
  void dispose() {
    _subscription?.cancel();
  }

  /// Check if IAP is available
  Future<bool> isIAPAvailable() async {
    return await _inAppPurchase.isAvailable();
  }

  /// Get available products from store
  Future<List<ProductDetails>> getStoreProducts() async {
    final Set<String> productIds = {
      'pro_monthly_subscription',
      'pro_annual_subscription',
    };

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }

    return response.productDetails;
  }

  /// Start Google Play / Apple IAP purchase
  Future<bool> purchaseWithIAP(SubscriptionPlan plan) async {
    try {
      final available = await isIAPAvailable();
      if (!available) {
        onPurchaseError?.call('Uygulama içi satın alma kullanılamıyor');
        return false;
      }

      final String productId = Platform.isIOS 
          ? plan.appleProductId 
          : plan.googlePlayProductId;

      if (productId.isEmpty) {
        onPurchaseError?.call('Bu plan için ürün bulunamadı');
        return false;
      }

      final products = await getStoreProducts();
      final product = products.where((p) => p.id == productId).firstOrNull;

      if (product == null) {
        onPurchaseError?.call('Ürün mağazada bulunamadı');
        return false;
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // For subscriptions
      return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      onPurchaseError?.call('Satın alma başlatılamadı: $e');
      return false;
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('Purchase pending...');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        onPurchaseError?.call(purchaseDetails.error?.message ?? 'Satın alma hatası');
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        // Verify purchase with backend
        final verified = await _verifyPurchaseWithBackend(purchaseDetails);
        
        if (verified) {
          onPurchaseSuccess?.call('Aboneliğiniz başarıyla aktifleştirildi!');
        } else {
          onPurchaseError?.call('Satın alma doğrulanamadı');
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  /// Verify purchase with backend
  Future<bool> _verifyPurchaseWithBackend(PurchaseDetails purchaseDetails) async {
    try {
      final apiUrl = await AppConfig.apiBaseUrl;
      final userId = await _authService.getUserId();

      final endpoint = Platform.isIOS 
          ? '$apiUrl/subscription/verify/apple'
          : '$apiUrl/subscription/verify/google';

      // Determine plan name from product ID
      String planName = 'PRO_MONTHLY';
      if (purchaseDetails.productID.contains('annual')) {
        planName = 'PRO_ANNUAL';
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': userId.toString(),
        },
        body: json.encode({
          'planName': planName,
          'purchaseToken': purchaseDetails.verificationData.serverVerificationData,
          'productId': purchaseDetails.productID,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Backend verification failed: $e');
      return false;
    }
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
      } else {
         throw Exception('Paketler yüklenemedi: HTTP ${response.statusCode} at $url');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e (URL: $url)');
    }
  }

  /// Initialize iyzico payment (for web/alternative payment)
  Future<Map<String, dynamic>> initializeIyzicoPayment(int planId) async {
    final apiUrl = await AppConfig.apiBaseUrl;
    final userId = await _authService.getUserId();
    
    final callbackUrl = '$apiUrl/subscription/callback/iyzico';

    final response = await http.post(
      Uri.parse('$apiUrl/subscription/pay/iyzico'),
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': userId.toString(),
      },
      body: json.encode({
        'planId': planId,
        'callbackUrl': callbackUrl,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorBody = json.decode(response.body);
      final error = errorBody['error'] ?? 'Ödeme başlatılamadı';
      throw Exception(error);
    }
  }

  /// Get user's subscription status
  Future<Map<String, dynamic>> getUserSubscriptionStatus() async {
    final apiUrl = await AppConfig.apiBaseUrl;
    final userId = await _authService.getUserId();

    if (userId == null) throw Exception('Kullanıcı ID bulunamadı');

    final response = await http.get(
      Uri.parse('$apiUrl/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Abonelik durumu alınamadı');
    }
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
      return json.decode(response.body);
    } else {
      final errorBody = json.decode(response.body);
      final error = errorBody['error'] ?? 'Demo aktivasyon başarısız';
      throw Exception(error);
    }
  }
}

