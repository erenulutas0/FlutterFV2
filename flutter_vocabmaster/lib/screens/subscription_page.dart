import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/subscription_service.dart';
import '../widgets/modern_background.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _useGooglePlayIAP = false; // Set to true when Play Store products are ready

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _initializeIAP();
  }

  void _initializeIAP() {
    _subscriptionService.initializePurchaseStream();
    _subscriptionService.onPurchaseSuccess = (message) {
      setState(() => _isPurchasing = false);
      _showSuccessDialog(message);
    };
    _subscriptionService.onPurchaseError = (error) {
      setState(() => _isPurchasing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    };
  }

  @override
  void dispose() {
    _subscriptionService.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await _subscriptionService.getPlans();
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  // === CONFIGURATION FLAGS ===
  static const bool DEMO_MODE = true; // Set to false for production!
  
  void _startPayment(SubscriptionPlan plan) async {
    if (_isPurchasing) return;
    
    setState(() => _isPurchasing = true);

    // DEMO MODE: Skip payment entirely
    if (DEMO_MODE) {
      _activateDemoSubscription(plan);
      return;
    }

    // Use Google Play IAP on Android, Apple IAP on iOS
    if (_useGooglePlayIAP && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final success = await _subscriptionService.purchaseWithIAP(plan);
        if (!success) {
          setState(() => _isPurchasing = false);
        }
        // Purchase result will come through the stream callback
      } catch (e) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ödeme hatası: $e')),
        );
      }
    } else {
      // Fallback to iyzico for web or demo mode
      _startIyzicoPayment(plan);
    }
  }

  void _activateDemoSubscription(SubscriptionPlan plan) async {
    try {
      final result = await _subscriptionService.activateDemoSubscription(plan.id);
      setState(() => _isPurchasing = false);
      _showSuccessDialog(result['message'] ?? 'Demo abonelik aktif!');
    } catch (e) {
      setState(() => _isPurchasing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demo hatası: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _startIyzicoPayment(SubscriptionPlan plan) async {
    try {
      final result = await _subscriptionService.initializeIyzicoPayment(plan.id);
      final String paymentUrl = result['paymentPageUrl'];

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IyzicoWebView(
              url: paymentUrl,
              onSuccess: () {
                Navigator.pop(context);
                _showSuccessDialog('Ödemeniz başarıyla tamamlandı!');
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ödeme hatası: $e')),
      );
    } finally {
      setState(() => _isPurchasing = false);
    }
  }

  void _showSuccessDialog([String? message]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎉 Tebrikler!', style: TextStyle(color: Colors.white)),
        content: Text(
          message ?? 'PRO üyeliğiniz başarıyla aktif edildi. Keyifle öğrenin!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('Tamam', style: TextStyle(color: Color(0xFF22D3EE))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('PRO Üyelik', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ModernBackground(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22D3EE)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
              child: Column(
                children: [
                   const Text(
                    'Dil Öğrenme Yolculuğunu\nÜst Seviyeye Taşı',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Yapay zeka destekli özelliklerle hızla ilerle.',
                    style: TextStyle(color: Colors.white60, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  ..._plans.map((plan) => _buildPlanCard(plan)).toList(),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    bool isFree = plan.name == 'FREE';
    if (isFree) return const SizedBox.shrink(); // Don't show free in pro page

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.name.contains('ANNUAL') ? 'Yıllık Plan' : 'Aylık Plan',
                      style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (plan.name.contains('ANNUAL'))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Text('%40 Tasarruf', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '${plan.price} ${plan.currency}',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      plan.durationDays == 30 ? ' / ay' : ' / yıl',
                      style: const TextStyle(color: Colors.white60, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildPerk(Icons.check_circle, 'Sınırsız AI Chat Buddy'),
                _buildPerk(Icons.check_circle, 'IELTS Speaking Simülasyonu'),
                _buildPerk(Icons.check_circle, 'Gelişmiş Gramer Kontrolü'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => _startPayment(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22D3EE),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Hemen Yükselt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerk(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF22D3EE), size: 18),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 15)),
        ],
      ),
    );
  }
}

class IyzicoWebView extends StatefulWidget {
  final String url;
  final VoidCallback onSuccess;

  const IyzicoWebView({Key? key, required this.url, required this.onSuccess}) : super(key: key);

  @override
  _IyzicoWebViewState createState() => _IyzicoWebViewState();
}

class _IyzicoWebViewState extends State<IyzicoWebView> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            // Check if the URL contains the callback path (even if it's the backend URL)
            if (url.contains('/api/subscription/callback/iyzico')) {
              widget.onSuccess();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Güvenli Ödeme')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
