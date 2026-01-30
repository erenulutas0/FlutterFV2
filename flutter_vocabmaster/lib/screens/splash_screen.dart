
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../providers/app_state_provider.dart';
import '../main.dart'; 
import 'landing_page.dart';
import 'login_page.dart';
import '../widgets/animated_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Biraz bekle (Logo görünsün)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    if (isLoggedIn) {
      // Veriyi önden yükle
      final user = await authService.getUser();
      if (user != null && mounted) {
        Provider.of<AppStateProvider>(context, listen: false).setUser(user);
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } else {
      // Giriş yapmamış -> Landing Page veya Login Page
      // User talebi: Giriş yapmadıysa (landing) ekranı görsün.
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LandingPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          const Positioned.fill(
            child: AnimatedBackground(isDark: true),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome, 
                    size: 60, 
                    color: Colors.cyan
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'VocabMaster',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 48),
                const CircularProgressIndicator(color: Colors.cyan),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
