import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';

/// Kullanıcı oturum ve profil yönetimi servisi
class AuthService {
  static const String _tokenKey = 'session_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _rememberMeKey = 'remember_me';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Cache
  Map<String, dynamic>? _cachedUser;
  String? _cachedToken;
  String? _cachedRefreshToken;

  /// Oturum token'ını al
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;

    final prefs = await SharedPreferences.getInstance();
    _cachedRefreshToken = prefs.getString(_refreshTokenKey);
    return _cachedRefreshToken;
  }

  /// Kullanıcı verilerini al
  Future<Map<String, dynamic>?> getUser() async {
    if (_cachedUser != null) return _cachedUser;

    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userDataKey);
    if (userData != null) {
      try {
        _cachedUser = jsonDecode(userData);
        return _cachedUser;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Kullanıcı giriş yapmış mı?
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Login (E-posta & Şifre)
  Future<Map<String, dynamic>> login(String email, String password, {bool rememberMe = false}) async {
    try {
      final baseUrl = await AppConfig.apiBaseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailOrTag': email, 
          'password': password,
          'deviceInfo': 'Flutter Mobile App', 
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['accessToken'] ?? data['sessionToken'];
        final refreshToken = data['refreshToken'];
        if (token == null || refreshToken == null) {
          return {'success': false, 'message': 'Token alınamadı'};
        }
        
        final user = data['user'] ?? {
          'id': data['userId'] ?? 0,
          'email': email,
          'role': 'USER',
          'displayName': email.split('@')[0],
          'userTag': '#00000',
        };

        await saveSession(token, refreshToken, user, rememberMe: rememberMe);
        
        // Offline giriş için şifre hash'ini kaydet
        await _saveOfflineCredentials(email, password, user);
        
        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Giriş başarısız'};
      }
    } catch (e) {
      // Bağlantı hatası durumunda offline giriş dene
      print('Online login failed, trying offline: $e');
      return await _tryOfflineLogin(email, password);
    }
  }

  Future<void> _saveOfflineCredentials(String email, String password, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_email', email.toLowerCase());
    await prefs.setString('offline_password_hash', _hashPassword(password));
    // User data is already saved in saveSession via user_data key
  }

  Future<Map<String, dynamic>> _tryOfflineLogin(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    
    final cachedEmail = prefs.getString('offline_email');
    final cachedPasswordHash = prefs.getString('offline_password_hash');
    final cachedUserData = prefs.getString(_userDataKey); // saveSession'da kullanılan key
    
    if (cachedEmail == null || cachedPasswordHash == null || cachedUserData == null) {
      return {'success': false, 'message': 'İnternet bağlantısı yok ve kayıtlı offline oturum bulunamadı.'};
    }
    
    // Email kontrolü (hashlenmiş email ile de yapılabilirdi ama basitçe lowercase)
    // Email veya Tag girişi olduğu için cachedEmail ile eşleşiyor mu basitçe bakıyoruz
    // Tag ile offline giriş zor olabilir, sadece email'i cacheledik.
    // Kullanıcıya kolaylık olsun diye, eğer inputcached email ile eşleşiyorsa kabul edelim.
    
    if (email.toLowerCase() != cachedEmail.toLowerCase()) {
       // Belki kullanıcı tag girdi? Offline modda tag desteği zor.
       // Şimdilik sadece email match
       return {'success': false, 'message': 'Offline modda email eşleşmedi. Lütfen son kullandığınız email ile deneyin.'};
    }

    if (_hashPassword(password) != cachedPasswordHash) {
      return {'success': false, 'message': 'Şifre hatalı (Offline)'};
    }

    // Başarılı Offline Giriş
    try {
      final user = jsonDecode(cachedUserData);
      // Token'ı yenilemeye gerek yok, eskisi kalsın veya dummy
      // _cachedUser vs güncellenmeli
      _cachedUser = user;
      return {'success': true, 'user': user, 'isOffline': true};
    } catch (e) {
      return {'success': false, 'message': 'Offline kullanıcı verisi bozuk.'};
    }
  }

  String _hashPassword(String password) {
    // Basit hash - gerçek production için crypto kütüphanesi kullanılmalı
    var hash = 0;
    for (var i = 0; i < password.length; i++) {
      hash = ((hash << 5) - hash) + password.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF; 
    }
    return hash.toString();
  }

  /// Register (Kayıt Ol)
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final baseUrl = await AppConfig.apiBaseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email, 
          'password': password,
          'displayName': name, // Backend expects displayName
          'deviceInfo': 'Flutter Mobile App',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['accessToken'] ?? data['sessionToken'];
        final refreshToken = data['refreshToken'];
        if (token != null && refreshToken != null) {
           await saveSession(token, refreshToken, data['user']);
           return {'success': true, 'user': data['user']};
        }
        return await login(email, password, rememberMe: true);
      } else {
        return {'success': false, 'message': data['error'] ?? 'Kayıt başarısız'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası: $e'};
    }
  }

  /// Google Login
  Future<Map<String, dynamic>> googleLogin() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Giriş iptal edildi'};
      }

      // Backend /google-login endpoint'ini kullan
      final baseUrl = await AppConfig.apiBaseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': googleUser.email,
          'displayName': googleUser.displayName ?? googleUser.email.split('@')[0],
          'photoUrl': googleUser.photoUrl,
          'googleId': googleUser.id,
          'deviceInfo': 'Flutter Mobile App',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
         final token = data['accessToken'] ?? data['sessionToken'];
         final refreshToken = data['refreshToken'];
         if (token == null || refreshToken == null) {
           return {'success': false, 'message': 'Token alınamadı'};
         }

         await saveSession(token, refreshToken, data['user']);
         return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Google ile giriş başarısız'};
      }

    } catch (e) {
      return {'success': false, 'message': 'Google giriş hatası: $e'};
    }
  }

  /// Oturumu kaydet
  Future<void> saveSession(String token, String refreshToken, Map<String, dynamic> user, {bool rememberMe = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userDataKey, jsonEncode(user));
    await prefs.setBool(_rememberMeKey, rememberMe);
    _cachedToken = token;
    _cachedRefreshToken = refreshToken;
    _cachedUser = user;
  }

  /// Kullanıcı bilgilerini güncelle
  Future<void> updateUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(user));
    _cachedUser = user;
  }

  /// Çıkış yap
  Future<void> logout() async {
    final token = await getToken();
    final refreshToken = await getRefreshToken();
    
    if (token != null) {
      try {
        final baseUrl = await AppConfig.apiBaseUrl;
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            if (refreshToken != null) 'refreshToken': refreshToken,
          }),
        );
      } catch (e) {
        // Sessizce geç
      }
    }

    // Yerel verileri temizle
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    // Remember me kalsın mı? Genelde logout olunca her şey silinir.
    
    _cachedToken = null;
    _cachedRefreshToken = null;
    _cachedUser = null;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  /// Profil bilgilerini backend'den yenile
  Future<Map<String, dynamic>?> refreshProfile() async {
     // Backend'de /me endpoint'i auth_controller'da yoktu.
     // Şimdilik cached datayı dön
     return getUser();
  }

  /// Kullanıcı ID'sini al
  Future<int?> getUserId() async {
    final user = await getUser();
    return user?['id'];
  }
}
