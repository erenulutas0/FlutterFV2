import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class SocialService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final userId = await _authService.getUserId();
    return {
      'Content-Type': 'application/json',
      'X-User-Id': userId.toString(), 
    };
  }

  Future<List<dynamic>> getFeed() async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/social/feed'), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Akış yüklenemedi');
    }
  }

  Future<Map<String, dynamic>> createPost(String content) async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/posts'),
      headers: headers,
      body: json.encode({'content': content}),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Paylaşım yapılamadı: ${response.statusCode} - ${response.body}');
    }
  }

  // Toggle like - beğeni ekle veya kaldır
  Future<Map<String, dynamic>> toggleLike(int postId) async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/posts/$postId/like'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Beğeni işlemi başarısız');
    }
  }

  Future<Map<String, dynamic>> commentPost(int postId, String content) async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/posts/$postId/comment'),
      headers: headers,
      body: json.encode({'content': content}),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Yorum yapılamadı');
    }
  }

  Future<List<dynamic>> getComments(int postId) async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/social/posts/$postId/comments'), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Yorumlar yüklenemedi');
    }
  }

  Future<List<dynamic>> getNotifications() async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/notifications'), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Bildirimler yüklenemedi');
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Bildirim okundu işaretlenemedi');
    }
  }

  Future<List<dynamic>> getFriends() async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/friends/list'), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Arkadaşlar yüklenemedi');
    }
  }

  // Heartbeat - kullanıcının çevrimiçi olduğunu bildirmek için
  Future<void> sendHeartbeat() async {
    try {
      final baseUrl = await AppConfig.apiBaseUrl;
      final headers = await _getHeaders();
      await http.post(Uri.parse('$baseUrl/users/heartbeat'), headers: headers);
    } catch (e) {
      // Heartbeat hataları sessizce yok sayılır
    }
  }

  // Kullanıcı profilini getir
  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/friends/profile/$userId'), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Profil yüklenemedi');
    }
  }

  // Arkadaşlık isteği gönder
  Future<Map<String, dynamic>> sendFriendRequest(String email) async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/friends/request'),
      headers: headers,
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      final error = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(error['error'] ?? 'İstek gönderilemedi');
    }
  }

  // Arkadaşlık isteğini kabul et
  Future<Map<String, dynamic>> acceptFriendRequest(int requestId) async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/friends/accept/$requestId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('İstek kabul edilemedi');
    }
  }

  // Bekleyen arkadaşlık isteklerini getir
  Future<List<dynamic>> getPendingFriendRequests() async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/friends/requests'), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('İstekler yüklenemedi');
    }
  }

  // Arkadaşlıktan çıkar
  Future<Map<String, dynamic>> removeFriend(int friendId) async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/friends/remove/$friendId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Arkadaşlıktan çıkarılamadı');
    }
  }

  // Arkadaşlık durumunu kontrol et
  Future<Map<String, dynamic>> getFriendshipStatus(int otherUserId) async {
    final baseUrl = await AppConfig.apiBaseUrl;
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/friends/status/$otherUserId'), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Durum kontrol edilemedi');
    }
  }
}
